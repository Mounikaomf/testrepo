import os
import sys
import json
import logging
import requests
from datetime import date, datetime
import boto3
import pyspark.sql.functions as F
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from functools import reduce
from pyspark.sql import DataFrame
from awsglue.transforms import *
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import Relationalize
from awsglue.dynamicframe import DynamicFrame
from pyspark import SparkContext


DATE_DELIMITER = "-"

def add_time_partitioning_columns(df, str_datetime):
    year, month, day, hour = str_datetime.split(DATE_DELIMITER)

    return df \
        .withColumn("year", F.lit(year)) \
        .withColumn("month", F.lit(month)) \
        .withColumn("day", F.lit(day)) \
        .withColumn("hour", F.lit(hour))

def config_get_param(json_dict, param_name):
    return json_dict[param_name]

def config_get_field_mapping(json_dict, table_name):
    output_list = []
    for i in json_dict["tables"][table_name]:
        if "fieldmap" in i:
            mapping_line = (json_dict["tables"][table_name][i]).replace(' ', '')
            tp = tuple(mapping_line.split(","))
            output_list.append(tp)

    if len(output_list):
        return output_list
    else:
        return None

def get_ssm_param(ssm_client, name):
    return ssm_client.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]

def s3_folder_nonempty(bucket, key, aws_region, logger):
    s3 = boto3.resource("s3", region_name=aws_region)
    bucket = s3.Bucket(bucket)
    objs = list(bucket.objects.filter(Prefix=key))
    logger.info("Number of objects in the folder : " + str(len(objs)-1) + ".")
    return len(objs) > 1

def check_s3_folder(bucket, key, aws_region, logger):
    logger.info(f"Checking if input folder {bucket}/{key} has data...")
    if s3_folder_nonempty(bucket, key, aws_region, logger):
        return 1
    else:
        return 0

def df_columns_char_replace(df, char_from, char_to):
    for oldName in df.schema.names:
        df = df.withColumnRenamed(oldName, oldName.replace(char_from,char_to))
    return df


def process_csv_files(glueContext, spark, table, bucket, source_prefix, target_prefix, mapping_list, aws_region, with_header, separator, logger, parquet_datetime):
    logger.info(f"Reading {table} CSV files...")
    glueContext = GlueContext(SparkContext.getOrCreate())
    s3 = boto3.client("s3")

    input_path = "s3://" + os.path.join(bucket, source_prefix)

    if check_s3_folder(bucket, source_prefix, aws_region, logger) == 0:
        logger.info(f"Data not found for {table}.")
        return False, False

    logger.info(f"Processing...")
    input_df = glueContext.create_dynamic_frame_from_options(connection_type = "s3", connection_options = {"paths": [input_path], "recurse":True}, format = "csv", format_options={"withHeader": with_header, "separator": separator}, transformation_ctx = "input_df")
    dataframe1 = input_df.toDF()

    rows_count = dataframe1.count()
    logger.info(f"New rows count: {rows_count}.")
    if rows_count == 0:
        return False, False

    logger.info("Adding Filename column...")
    dataframe1 = dataframe1.withColumn("filename", F.input_file_name())
    dataframe2 = dataframe1.repartition(1)

    for oldName in dataframe2.schema.names:
        dataframe2 = dataframe2.withColumnRenamed(oldName, oldName.upper())

    logger.info("Replacing chars in columns...")
    dataframe2 = df_columns_char_replace(dataframe2, ".","_")
    dataframe2 = df_columns_char_replace(dataframe2, "-","_")
    dataframe2 = df_columns_char_replace(dataframe2, " ","")

    dynamicframe1 = DynamicFrame.fromDF(dataframe2, glueContext, "dynamicframe1")

    if mapping_list == None:
        logger.info("No column mapping.")
        dynamicframe2 = dynamicframe1
    else:
        logger.info("Applying column mapping...")
        #!if a field is missing in the mapping list then it will be deleted from output
        dynamicframe2 = ApplyMapping.apply(frame = dynamicframe1, mappings = mapping_list)

    logger.info("Adding columns for partition keys...")
    dataframe3 = dynamicframe2.toDF()
    dataframe3 = add_time_partitioning_columns(dataframe3, parquet_datetime)
    dynamicframe3 = DynamicFrame.fromDF(dataframe3, glueContext, "dynamicframe3")

    fullpath_parquet = "s3a://" + os.path.join(bucket,target_prefix)
    logger.info(f"Creating archive parquet file {fullpath_parquet}...")
    flattenedoutput1 = glueContext.write_dynamic_frame.from_options(frame = dynamicframe3, connection_type = "s3",
                       connection_options = {"path": fullpath_parquet, "partitionKeys": ["year", "month", "day", "hour"]}, format = "parquet", transformation_ctx = "flatteneddataoutput1")

    logger.info(f"Parquet file created.")

    return fullpath_parquet, True


args = getResolvedOptions(
    sys.argv,
    [
        "bucket",
        "source_prefix",
        "target_prefix",
        "table",
        "config_path",
        "JOB_NAME",
    ],
)

bucket = args["bucket"]
source_prefix = args["source_prefix"]
target_prefix = args["target_prefix"]
table = args["table"]
config_path = args["config_path"]
job_name = args["JOB_NAME"]


def main():
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(job_name, args)

    r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
    response_json = r.json()
    aws_region = response_json.get('region')

    MSG_FORMAT = '%(asctime)s %(levelname)s %(name)s: %(message)s'
    DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
    logger = logging.getLogger(job_name)
    logger.setLevel(logging.INFO)

    PARQUET_DATETIME_FORMAT = DATE_DELIMITER.join(["%Y", "%m", "%d", "%H"])
    datetime_now = datetime.now()
    parquet_datetime = datetime_now.strftime(PARQUET_DATETIME_FORMAT)

    config_bucket = bucket
    table_name = table.upper()

    logger.info(f"Glue Job {job_name} for table {table_name} STARTED.")
    logger.info(f"bucket: {bucket}.")
    logger.info(f"source_prefix: {source_prefix}.")
    logger.info(f"target_prefix: {target_prefix}.")
    logger.info(f"aws_region: {aws_region}.")
    logger.info(f"config_bucket: {config_bucket}.")
    logger.info(f"config_path: {config_path}.")

    s3 = boto3.resource("s3")

    if len(config_path) > 0:
        config_obj = s3.Object(config_bucket,config_path)
        config_file = config_obj.get()["Body"].read().decode("utf-8")
        json_dict = json.loads(config_file)
        mapping_list = config_get_field_mapping(json_dict, table_name)
    else:
        logger.info("ERROR: no config file.")
        sys.exit(1)

    logger.info("Retrieving parameters from config...")
    with_header = config_get_param(json_dict, "withHeader")
    separator = config_get_param(json_dict, "separator")
    logger.info(f"Parameter with_header: {str(with_header)}.")
    logger.info(f"Parameter separator: [{separator}].")

    fullpath_parquet, have_files = process_csv_files(glueContext, spark, table_name, bucket, source_prefix, target_prefix, mapping_list, aws_region, with_header, separator, logger, parquet_datetime)

    if not have_files:
        logger.info("No files to process.")

    logger.info(f"Glue Job {job_name} for table {table_name} COMPLETED.")

    job.commit()
    spark.stop()


if __name__ == "__main__":
    main()

