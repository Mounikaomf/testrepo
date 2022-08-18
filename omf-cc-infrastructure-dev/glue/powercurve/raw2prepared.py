import boto3
import os
import sys
import logging
import json
import requests
from datetime import date, datetime
import pyspark.sql.functions as F
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StringType
from awsglue.transforms import *
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext


DATE_DELIMITER = "-"


def add_time_partitioning_columns(df, str_datetime):
    year, month, day, hour = str_datetime.split(DATE_DELIMITER)

    return df \
        .withColumn("year", F.lit(year)) \
        .withColumn("month", F.lit(month)) \
        .withColumn("day", F.lit(day)) \
        .withColumn("hour", F.lit(hour))


def get_s3components_and_config_from_s3_json_object_path(s3_object_path):
    """
    Returns bucket-name, objcet_key and contents of json file as a dict from an s3 path

        Parameters:
            s3_object_path (str): eg bucket-name-of-s3/prefix/key/to/obj.json

        Returns:
            config_bucket   (str): bucket-name-of-s3
            config_path_key (str): prefix/key/to/obj.json
            json_dict       (dict): {}
    """
    config_bucket = s3_object_path.split("/")[0]
    config_path_key = "/".join(s3_object_path.split("/")[1:])
    s3 = boto3.resource("s3")
    config_obj = s3.Object(config_bucket, config_path_key)
    config_file = config_obj.get()["Body"].read().decode("utf-8")

    json_dict = json.loads(config_file)

    return config_bucket, config_path_key, json_dict

def replace_columns_content_in_dataframe(df, to_change_columns: set(), replacement_string=None):
    """For each column in dataframe check if it is in the 'to_change_columns' set and replace contents of it with
    replacement_string
    """
    for column in df.columns:
        if column in to_change_columns:
            df = df.withColumn(column, F.lit(replacement_string).cast(StringType()))

    return df

args = getResolvedOptions(
    sys.argv,
    [
        "bucket",
        "target_prefix",
        "raw_layer_prefix",
        "pii_fields_config_path",
        "rds_database",
        "table",
        "JOB_NAME",
    ],
)


bucket = args["bucket"]
target_prefix = args["target_prefix"]
rds_database = args["rds_database"]
table = args["table"] #crawled glue table name like "pco_db_eda_tenant1_applicant"
job_name = args["JOB_NAME"]
pii_fields_config_path = args["pii_fields_config_path"]
raw_layer_prefix = args["raw_layer_prefix"]

def main():
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(job_name, args)

    #https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
    r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
    response_json = r.json()
    aws_region = response_json.get('region')
    s3 = boto3.client("s3", region_name=aws_region)

    MSG_FORMAT = '%(asctime)s %(levelname)s %(name)s: %(message)s'
    DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
    logger = logging.getLogger("PowerCurve")
    logger.setLevel(logging.INFO)

    PARQUET_DATETIME_FORMAT = DATE_DELIMITER.join(["%Y", "%m", "%d", "%H"])

    datetime_now = datetime.now()
    parquet_datetime = datetime_now.strftime(PARQUET_DATETIME_FORMAT)

    table_name = table.upper()

    pii_config_bucket, pii_fields_key_path, pii_json_dict = get_s3components_and_config_from_s3_json_object_path(pii_fields_config_path)

    logger.info(f"Glue Job {job_name} for table {table_name.upper()} STARTED.")
    logger.info(f"parquet_datetime: {parquet_datetime}.")
    logger.info(f"bucket: {bucket}.")
    logger.info(f"target_prefix: {target_prefix}.")
    logger.info(f"rds_database: {rds_database}.")
    logger.info(f"aws_region: {aws_region}.")
    logger.info(f"table: {table}.")
    logger.info(f"pii_config_bucket: {pii_config_bucket}.")
    logger.info(f"pii_fields_key_path: {pii_fields_key_path}.")
    logger.info(f"raw_layer_prefix: {raw_layer_prefix}.")

    dynamicframe1 = glueContext.create_dynamic_frame.from_catalog(database=rds_database, table_name=table, transformation_ctx = "dynamicframe1")
    #--additional_options = {"jobBookmarkKeys":["<ID from config.json>"],"jobBookmarkKeysSortOrder":"asc"}
    dataframe1 = dynamicframe1.toDF().repartition(1)
    #logger.info(dynamicframe1.toDF().show())

    dataframe1.cache()

    row_count = dataframe1.count()
    logger.info(f"New row count: {row_count}.")

    if row_count == 0:
        logger.info("No rows to process.")
    else:
        # write parquet to raw layer
        dynamicframe_raw = DynamicFrame.fromDF(dataframe1, glueContext, "dynamicframe_raw")
        raw_layer_fullpath_parquet = "s3a://" + os.path.join(bucket, raw_layer_prefix)
        logger.info(f"Raw parquet path: {raw_layer_fullpath_parquet}.")
        dfoutput_raw = glueContext.write_dynamic_frame.from_options(
                            frame = dynamicframe_raw, connection_type = "s3",
                            connection_options = {
                                "path": raw_layer_fullpath_parquet
                            },
                            format = "parquet", transformation_ctx = "dfoutput_raw"
                        )
        logger.info(f"Parquet file created: {raw_layer_fullpath_parquet}.")

        # continue processing to prepared layer
        logger.info(f"Continuing process to prepared layer...")

        for col in dataframe1.columns:
            dataframe1 = dataframe1.withColumnRenamed(col, col.upper())

        # replace PII fields with null values
        logger.info("Removing info from PII columns")

        pii_columns_set = set([field.upper() for field in pii_json_dict["PII"]["FIELDS"]])

        dataframe_pii_removed = replace_columns_content_in_dataframe(dataframe1, pii_columns_set)

        dataframe2 = add_time_partitioning_columns(dataframe_pii_removed, parquet_datetime)
        dynamicframe2 = DynamicFrame.fromDF(dataframe2, glueContext, "dynamicframe2")

        # parquet writes intermediary paruqets to a '_temporary' folder at the destination and then moves it to the final parquet
        # write parquet to a temporary folder then move it to the prepared layer
        fullpath_parquet = "s3a://" + os.path.join(bucket, target_prefix)
        logger.info(f"Output parquet path: {fullpath_parquet}.")
        dfoutput1 = glueContext.write_dynamic_frame.from_options(frame = dynamicframe2, connection_type = "s3",
                            connection_options = {
                                "path": fullpath_parquet,
                                "partitionKeys": ["year", "month", "day", "hour"]},
                            format = "parquet", transformation_ctx = "dfoutput1")
        logger.info(f"Parquet file created: {fullpath_parquet}.")

        dataframe1.unpersist()

    logger.info(f"Glue Job {job_name} for table {table} COMPLETED.")

    job.commit() #important to save bookmark
    spark.stop()

if __name__ == "__main__":
    main()
