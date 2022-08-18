import os
import sys
import json
import logging
import requests
from datetime import date, datetime
from urllib.parse import urlparse
import boto3
import pyspark.sql.functions as F
import re
from awsglue.utils import getResolvedOptions
from awsglue.transforms import *
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import Relationalize
from awsglue.dynamicframe import DynamicFrame
from pyspark import SparkContext
from pyspark.sql import SQLContext
from pyspark.sql.types import *

DATE_DELIMITER = "-"


def build_uri_from_bucket_and_key(bucket, key):
    return "s3://" + os.path.join(bucket, key)


def get_bucket_and_key_from_uri(uri):
    uri_splitted = uri.split("//")
    bucket_key = uri_splitted[0]
    if len(uri_splitted) != 1:
        bucket_key = uri_splitted[1]
    index_of_first_slash = bucket_key.find("/")
    if index_of_first_slash == -1:
        return bucket_key, ""
    elif index_of_first_slash == len(bucket_key) - 1:
        return bucket_key[:-1], ""
    return bucket_key[:index_of_first_slash], bucket_key[index_of_first_slash + 1:]


def copy_object_to_s3(source_bucket, source_key, destination_bucket, destination_key, s3_client, logger):
    copy_source = {"Bucket": source_bucket, "Key": source_key}
    logger.info(
        "Copying {0} to {1}".format(
            build_uri_from_bucket_and_key(source_bucket, source_key),
            build_uri_from_bucket_and_key(destination_bucket, destination_key),
        )
    )
    copy_response = s3_client.copy_object(
        CopySource=copy_source, Bucket=destination_bucket, Key=destination_key
    )
    logger.debug(copy_response)


def delete_object_from_s3(bucket, key, s3_client, logger):
    logger.info("Deleting {}".format(build_uri_from_bucket_and_key(bucket, key)))
    delete_response = s3_client.delete_object(Bucket=bucket, Key=key)
    logger.debug(delete_response)


def move_files(files, source_prefix, target_prefix, s3_client, logger):
    for file in files:
        key = get_bucket_and_key_from_uri(file)[1]
        destination_key = key.replace(source_prefix, target_prefix)
        copy_object_to_s3(
            bucket, key, bucket, destination_key, s3_client, logger
        )
        delete_object_from_s3(bucket, key, s3_client, logger)


def get_objects_from_s3(bucket, key, s3_client, logger):
    response = s3_client.list_objects_v2(Bucket=bucket, Prefix=key)
    logger.debug(response)
    files = []
    if "Contents" in response:
        for object in response["Contents"]:
            if object['Key'][-1:] != '/':
                files.append(object)
    files = [build_uri_from_bucket_and_key(bucket, file["Key"]) for file in files]
    return files


def config_get_all_source_fields(json_dict, table_name):
    output_list = []
    for i in json_dict["tables"][table_name]:
        if "fieldmap" in i:
            mapping_line = (json_dict["tables"][table_name][i]).replace(' ', '')
            fd = mapping_line.partition(",")[0]
            output_list.append(fd)
    return output_list


def config_get_field_mapping(json_dict, table_name):
    output_list = []
    for i in json_dict["tables"][table_name]:
        if "fieldmap" in i:
            mapping_line = (json_dict["tables"][table_name][i]).replace(' ', '')
            tp = tuple(mapping_line.split(","))
            output_list.append(tp)
    return output_list


def s3_folder_nonempty(bucket, key, aws_region, logger):
    s3 = boto3.resource("s3", region_name=aws_region)
    bucket = s3.Bucket(bucket)
    objs = list(bucket.objects.filter(Prefix=key))
    logger.info("Number of objects in the folder : " + str(len(objs) - 1) + ".")
    return len(objs) > 1


def check_s3_folder(bucket, key, aws_region, logger):
    logger.info(f"Checking if input folder {bucket}/{key} has data...")
    if s3_folder_nonempty(bucket, key, aws_region, logger):
        return 1
    else:
        return 0


def get_bucket_from_url(url):
    return urlparse(url, allow_fragments=False).netloc


def add_missing_columns(df, table, column_list):
    """Add missing columns to dataframe if they are missing in the JSON file"""
    for col in df.columns:
        df = df.withColumnRenamed(col, col.upper())

    for column in column_list:
        if column.upper() not in df.columns:
            # logger.info("Missing column:" + column.upper())
            df = df.withColumn(column.upper(), F.lit(None).cast(StringType()))  # F.lit("NA-missed")
    return df


def add_time_partitioning_columns(df, str_datetime):
    year, month, day, hour = str_datetime.split(DATE_DELIMITER)

    return df \
        .withColumn("year", F.lit(year)) \
        .withColumn("month", F.lit(month)) \
        .withColumn("day", F.lit(day)) \
        .withColumn("hour", F.lit(hour))


def remove_prefix(column_name):
    if column_name.split("_")[0] != "FILLER" and column_name != "FILE_DT":
        return column_name[column_name.find("") + 1:], column_name[:column_name.find("")]
    return column_name, ""


snowflake_reserved_words = ["ACCOUNT", "ALL", "ALTER", "AND", "ANY", "AS", "BETWEEN", "BY", "CASE", "CAST",
                            "CHECK", "COLUMN", "CONNECT", "CONNECTION", "CONSTRAINT", "CREATE", "CROSS", "CURRENT",
                            "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP", "CURRENT_USER", "DATABASE",
                            "DELETE", "DISTINCT", "DROP", "ELSE", "EXISTS", "FALSE", "FOLLOWING", "FOR", "FROM", "FULL",
                            "GRANT", "GROUP", "GSCLUSTER", "HAVING", "ILIKE", "IN", "INCREMENT", "INNER", "INSERT",
                            "INTERSECT", "INTO", "IS", "ISSUE", "JOIN", "LATERAL", "LEFT", "LIKE", "LOCALTIME",
                            "LOCALTIMESTAMP", "MINUS", "NATURAL", "NOT", "NULL", "OF", "ON", "OR", "ORDER",
                            "ORGANIZATION", "QUALIFY",
                            "REGEXP", "REVOKE", "RIGHT", "RLIKE", "ROW", "ROWS", "SAMPLE", "SCHEMA", "SELECT", "SET",
                            "SOME", "START", "TABLE", "TABLESAMPLE", "THEN", "TO", "TRIGGER", "TRUE", "TRY_CAST",
                            "UNION", "UNIQUE", "UPDATE", "USING", "VALUES", "VIEW", "WHEN", "WHENEVER", "WHERE", "WITH"]


def flatten(schema, fields=None, prefix=None, logger=None):
    if not fields:
        fields = []
    for field in schema.fields:
        full_name = prefix + "." + field.name if prefix else field.name
        node_names = full_name.split(".")
        dtype = field.dataType
        if isinstance(dtype, StructType):
            fields = flatten(dtype, fields, prefix=full_name, logger=logger)
        else:
            name = ""
            names = [name for name, full_name in fields]
            for node_id in range(len(node_names) - 1, -1, -1):
                current_node_name, current_node_prefix = remove_prefix(node_names[node_id])
                name = current_node_name + "_" + name if name != "" else current_node_name
                if name in snowflake_reserved_words:
                    if node_id == 0:
                        name = current_node_prefix + "_" + name
                        break
                    continue
                if name not in names:
                    new_name = name
                    if re.match(r"^[0-9]+", name):
                        parts = current_node_name.split("_")
                        amount_of_permutations = len(parts)
                        while re.match(r"^[0-9]+", parts[0]) and amount_of_permutations > 0:
                            parts.append(parts[0])
                            parts.pop(0)
                            amount_of_permutations -= 1
                        if amount_of_permutations == 0 and node_id == 0:  # all parts of last node start with digits
                            new_name = current_node_prefix + "_" + name  # assuming that prefix never starts with digits
                        elif amount_of_permutations != 0:
                            if node_id == len(node_names) - 1:
                                new_name = "_".join(parts)
                            else:
                                new_name = "_".join(parts) + name[name.find(current_node_name) + 1:]
                        else:
                            continue
                    if new_name not in names:
                        name = new_name
                        break
            if name in names:
                name = full_name.replace(".", "_")  # ultimate fallback in case all names are already in use
            fields.append((name, full_name))
            # logger.info("Final name for column {0} is {1}".format(full_name, name))
    return fields


def write_parquet_file_with_time_partitioning(df, glueContext, table, bucket, target_prefix, temporary_prefix, logger,
    table_upper, s3_client, parquet_datetime):

    logger.info(f"Moving files {table_upper} to destination")

    df1 = add_time_partitioning_columns(df, parquet_datetime)

    dynamicframe1 = DynamicFrame.fromDF(df1, glueContext, "dynamicframe1")

    # parquet writes intermediary paruqets to a '_temporary' folder at the destination and then moves it to the final parquet
    # write parquet to a temporary folder then move it to the prepared layer
    temporary_table_prefix = f"{temporary_prefix}/{table}"
    target_table_prefix = f"{target_prefix}/{table}"
    temporary_parquet = "s3a://" + os.path.join(bucket, temporary_table_prefix)
    flattenedoutput1 = glueContext.write_dynamic_frame.from_options(
        frame=dynamicframe1, connection_type="s3",
        connection_options={"path": temporary_parquet, "partitionKeys": ["year", "month", "day", "hour"]},
        format="parquet", transformation_ctx="flatteneddataoutput1"
    )

    logger.info(f"For {table_upper}, parquet file created at: {temporary_parquet}")

    parquet_files = get_objects_from_s3(bucket, temporary_table_prefix, s3_client, logger)
    move_files(parquet_files, temporary_table_prefix, target_table_prefix, s3_client, logger)

    logger.info(
        f"Moved {table_upper} parquet files to {build_uri_from_bucket_and_key(bucket, target_table_prefix)}")



def process_json_files(glueContext, spark, bucket, source_prefix, target_prefix, parquet_datetime, aws_region, logger,
                       json_dict, temporary_prefix, s3_client):
    logger.info(f"Starting to process json files...")
    glueContext = GlueContext(SparkContext.getOrCreate())

    input_path = "s3://" + os.path.join(bucket, source_prefix) + "/"

    logger.info(f"Processing data from {input_path}...")
    input_df = glueContext.create_dynamic_frame_from_options(connection_type="s3",
                                                             connection_options={"paths": [input_path],
                                                                                 'recurse': True}, format="json",
                                                             transformation_ctx="input_df") \
                            .toDF() \
                            .withColumn("filename", F.input_file_name())\
                            .repartition(1) \
                            .cache()

    files_count = input_df.count()
    logger.info(f"New files count: {files_count}.")
    if files_count == 0:
        return False

    # REMOVE logic
    dataframe_without_remove_event = input_df.filter("eventName != 'REMOVE'").cache()
    files_count_without_remove_event = dataframe_without_remove_event.count()

    entities = []
    if files_count_without_remove_event > 0:
        # check what entities we have to process
        entities = [r["S"].lower() for r in dataframe_without_remove_event.select(
            "dynamodb.NewImage.entityType.S").distinct().collect()]

        logger.info(f"Found following entities in files: {','.join(entities)}")

        for table in entities:
            # we skipping prospect for now
            if table == "prospect":
                continue

            table_upper = table.upper()
            mapping_list = config_get_field_mapping(json_dict, table_upper)
            column_list = config_get_all_source_fields(json_dict, table_upper)

            df1 = dataframe_without_remove_event.filter(f"dynamodb.NewImage.entityType.S = '{table}'").cache()

            df_renamed_cols = df1.select([F.col(full_name).alias(full_name.replace(".", "_")) for _, full_name in flatten(df1.schema, logger=logger)])

            # we can only have eventName "MODIFY" with manualReviewUploads and not "CREATE"
            if table == "application":
                df_manual_review_uploads = df_renamed_cols.filter(F.size(F.col("dynamodb_NewImage_manualReviewUploads_L")) > 0).cache()

                if df_manual_review_uploads.count() > 0:
                    # manualReviewUploads needs to be exploded into rows
                    df_manual_review_uploads_flatten = df_manual_review_uploads \
                        .withColumn("dynamodb_NewImage_manualReviewUploads_L", F.explode_outer(F.col("dynamodb_NewImage_manualReviewUploads_L")))

                    manual_review_uploads_table = "manualReviewUploads"
                    manual_review_uploads_table_upper = manual_review_uploads_table.upper()

                    mapping_list_manual_review_uploads = config_get_field_mapping(json_dict, manual_review_uploads_table_upper)
                    column_list_manual_review_uploads = config_get_all_source_fields(json_dict, manual_review_uploads_table_upper)


                    df_renamed = df_manual_review_uploads_flatten.select([F.col(full_name).alias(full_name.replace(".", "_").upper()) for _, full_name in flatten(df_manual_review_uploads_flatten.schema, logger=logger)])

                    df3 = add_missing_columns(df_renamed, manual_review_uploads_table_upper, column_list_manual_review_uploads)
                    # logger.info(dataframe2.printSchema( ))

                    dynamicframe1 = DynamicFrame.fromDF(df3, glueContext, "dynamicframe1")
                    dynamicframe2 = ApplyMapping.apply(frame=dynamicframe1, mappings=mapping_list_manual_review_uploads)

                    df4 = dynamicframe2.toDF()

                    write_parquet_file_with_time_partitioning(df4, glueContext, manual_review_uploads_table, bucket, target_prefix, temporary_prefix,
                        logger, manual_review_uploads_table_upper, s3_client, parquet_datetime)

                df_manual_review_uploads.unpersist()

            df3 = add_missing_columns(df_renamed_cols, table_upper, column_list)

            # logger.info(dataframe2.printSchema( ))

            dynamicframe1 = DynamicFrame.fromDF(df3, glueContext, "dynamicframe1")
            dynamicframe2 = ApplyMapping.apply(frame=dynamicframe1, mappings=mapping_list)

            df4 = dynamicframe2.toDF()

            write_parquet_file_with_time_partitioning(df4, glueContext, table, bucket, target_prefix, temporary_prefix,
                logger, table_upper, s3_client, parquet_datetime)

            df1.unpersist()

    table = "remove"
    df_remove_event_0 = input_df.filter("eventName = 'REMOVE'").cache()
    files_with_remove_event = df_remove_event_0.count()

    input_df.unpersist()
    dataframe_without_remove_event.unpersist()

    if files_with_remove_event > 0:
        logger.info(f"Processing {files_with_remove_event } files with remove event...")

        entities.append(table)

        df_renamed_cols = df_remove_event_0.select([F.col(full_name).alias(full_name.replace(".", "_")) for _, full_name in flatten(df_remove_event_0.schema, logger=logger)])

        write_parquet_file_with_time_partitioning(df_renamed_cols, glueContext, table, bucket, target_prefix, temporary_prefix,
            logger, table_upper, s3_client, parquet_datetime)

        df_remove_event_0.unpersist()

    else:
        logger.info("No 'REMOVE' eventName.")

    return entities


args = getResolvedOptions(
    sys.argv,
    [
        "bucket",
        "source_prefix",
        "target_prefix",
        "temporary_prefix",
        "config_path",
        "JOB_NAME",
    ],
)

bucket = args["bucket"]
source_prefix = args["source_prefix"]
target_prefix = args["target_prefix"]
config_path = args["config_path"]
job_name = args["JOB_NAME"]
temporary_prefix = args["temporary_prefix"]


def main():
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(job_name, args)

    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
    r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
    response_json = r.json()
    aws_region = response_json.get('region')

    MSG_FORMAT = '%(asctime)s %(levelname)s %(name)s: %(message)s'
    DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    PARQUET_DATETIME_FORMAT = DATE_DELIMITER.join(["%Y", "%m", "%d", "%H"])
    SOURCE_PATH_DATETIME_FORMAT = DATE_DELIMITER.join(["%Y", "%m", "%d"])

    logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
    logger = logging.getLogger(f"JOB_NAME")
    logger.setLevel(logging.INFO)

    datetime_now = datetime.now()
    parquet_datetime = datetime_now.strftime(PARQUET_DATETIME_FORMAT)
    # the full source prefix will have a format dependant on current date. source_prefix/Year/Month/Day
    source_path_datetime = datetime_now.strftime(SOURCE_PATH_DATETIME_FORMAT)
    # source_path_full_prefix = os.path.join(source_prefix, *source_path_datetime.split("-"))
    source_path_full_prefix = source_prefix
    config_bucket = config_path.split("/")[0]
    config_path_key = "/".join(config_path.split("/")[1:])

    logger.info(f"Glue Job {job_name} STARTED.")
    logger.info(f"Load date - {parquet_datetime}.")
    logger.info(f"bucket: {bucket}.")
    logger.info(f"source_prefix: {source_prefix}.")
    logger.info(f"target_prefix: {target_prefix}.")
    logger.info(f"temporary_prefix: {temporary_prefix}.")
    logger.info(f"aws_region: {aws_region}.")
    logger.info(f"config_path: {config_path}.")
    logger.info(f"config_bucket: {config_bucket}.")
    logger.info(f"config_path_key: {config_path_key}.")
    logger.info(f"source_path_full_prefix: {source_path_full_prefix}")

    s3 = boto3.resource("s3")
    config_obj = s3.Object(config_bucket, config_path_key)
    config_file = config_obj.get()["Body"].read().decode("utf-8")
    s3_client = boto3.client("s3", region_name=aws_region)

    json_dict = json.loads(config_file)

    entities = process_json_files(glueContext, spark, bucket, source_path_full_prefix, target_prefix, parquet_datetime,
                                  aws_region, logger, json_dict, temporary_prefix, s3_client)

    if not entities:
        logger.info("No files to process.")
    else:
        logger.info(f"ProductOffers Glue Job for tables {entities} COMPLETED.")

    job.commit()
    spark.stop()


if __name__ == "__main__":
    main()
