import json
import sys
import os
from awsglue.transforms import *
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import *
from pyspark.sql.functions import col, lit
from pyspark.sql import SQLContext, Row
import datetime
import boto3
import logging
import requests

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger("BNF")
logger.setLevel(logging.INFO)

def convert_string_to_row(partition):
    config_dict = get_config()
    for row in partition:
        columns = {}
        for column in config_dict["schema"]:
            name = column["name"]
            start = column["start"]-1
            end = column["end"]
            data_type = column["format"]
            value_of_column = row[start:end].strip()
            try:
                if data_type == "NUMBER":
                    value_of_column=int(value_of_column)
            except:
                value_of_column = None
            columns.update({name : value_of_column})
        yield Row(**columns)

def get_config():
    s3 = boto3.resource("s3")
    config_obj = s3.Object(config_bucket, config_key)
    config_file = config_obj.get()["Body"].read().decode("utf-8")
    return json.loads(config_file)

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

def build_uri_from_bucket_and_key(bucket, key):
    return "s3://" + os.path.join(bucket, key)

def get_objects_from_s3(bucket, key, add_last_modified_datetime = False):
    response = s3.list_objects_v2(Bucket=bucket, Prefix=key)
    logger.debug(response)
    files = []
    if "Contents" in response:
        for object in response["Contents"]:
            if object['Key'][-1:] != '/':
                files.append(object)
    if add_last_modified_datetime:
        files = [(build_uri_from_bucket_and_key(bucket, file["Key"]), file["LastModified"]) for file in files]
    else:
        files = [build_uri_from_bucket_and_key(bucket, file["Key"]) for file in files]
    return files

def convert_string_to_datetime(value):
    return datetime.datetime.strptime(value,'%Y-%m-%d %H:%M:%S.%f').timestamp()

def get_processed_files_from_logging_table(table):
    row_list = glue_context.create_dynamic_frame.from_options(
        connection_type="dynamodb",
        connection_options={
            "dynamodb.input.tableName": table,
            "dynamodb.throughput.read.percent": "1.0",
            "dynamodb.splits": "1"
        }
    ).select_fields(["file_name", "processed_datetime"]).toDF().collect()
    processed_files = [(str(row["file_name"]),str(row["processed_datetime"])) for row in row_list]
    dict = {}
    for file_name, processed_datetime in processed_files:
        if file_name in dict:
            if convert_string_to_datetime(dict[file_name]) < convert_string_to_datetime(processed_datetime):
                dict[file_name] = processed_datetime
        else:
            dict[file_name] = processed_datetime
    return [(file_name, processed_datetime) for file_name, processed_datetime in dict.items()]

def add_files_to_logging_table(table, files):
    schema = StructType([StructField("file_name", StringType()),StructField("processed_datetime", StringType())])
    date_time = datetime.datetime.now()
    files = [[get_bucket_and_key_from_uri(file)[1], str(date_time)] for file in files]
    df = DynamicFrame.fromDF(sql_context.createDataFrame(files, schema=schema), glue_context, "df")
    glue_context.write_dynamic_frame_from_options(
        frame=df,
        connection_type="dynamodb",
        connection_options={
            "dynamodb.output.tableName": table,
            "dynamodb.throughput.write.percent": "1.0"
        }
    )
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
spark_context = SparkContext.getOrCreate()
sql_context = SQLContext(spark_context)
glue_context = GlueContext(spark_context)
job = Job(glue_context)
job.init(args["JOB_NAME"], args)
args = getResolvedOptions(
    sys.argv,
    [
        "bucket",
        "source_prefix",
        "target_prefix",
        "JOB_NAME",
        "logging_table",
        "config_bucket",
        "config_key",
    ],
)
spark = glue_context.spark_session
bucket = args["bucket"]
source_prefix = args["source_prefix"]
target_prefix = args["target_prefix"]
logging_table = args["logging_table"]
config_bucket = args["config_bucket"]
config_key = args["config_key"]

logger.info("Bucket : {}".format(bucket))
logger.info("Source prefix : {}".format(source_prefix))
logger.info("Target prefix : {}".format(target_prefix))
logger.info("Logging table : {}".format(logging_table))

#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
response_json = r.json()
aws_region = response_json.get('region')
logger.info("AWS region : {}".format(aws_region))
s3 = boto3.client("s3", region_name=aws_region)

processed_files = get_processed_files_from_logging_table(logging_table)
files = get_objects_from_s3(bucket, source_prefix, True)
files_to_process = []
for file in files:
    if get_bucket_and_key_from_uri(file[0])[1] in [processed_file[0] for processed_file in processed_files]:
        last_modified_datetime = file[1].timestamp()
        last_processed_datetime = convert_string_to_datetime(next(filter(lambda x: x[0] == get_bucket_and_key_from_uri(file[0])[1], processed_files))[1])
        if last_modified_datetime > last_processed_datetime:
            files_to_process.append(file[0])
    else:
        files_to_process.append(file[0])

if len(files_to_process) > 0:
    config = get_config()
    fields = []
    logger.info("Files to process :\n" + "\n".join(files_to_process))
    for column in config["schema"]:
        name = column["name"]
        data_type = column["format"]
        if data_type == "NUMBER":
            fields.append(StructField(name, LongType(), True))
        else:
            fields.append(StructField(name, StringType(), True))
    schema = StructType(fields)
    input_rdd = spark.sparkContext.textFile(",".join(files_to_process))
    final_df = spark.createDataFrame(input_rdd.mapPartitions(convert_string_to_row), schema)
    now = datetime.datetime.now()
    final_df \
        .withColumn("year", lit(now.year)) \
        .withColumn("month", lit(now.month)) \
        .withColumn("day", lit(now.day)) \
        .coalesce(1) \
        .write \
        .format("parquet") \
        .partitionBy("year", "month", "day") \
        .mode("append") \
        .save(build_uri_from_bucket_and_key(bucket, target_prefix).replace("s3://", "s3a://") + "/")
    add_files_to_logging_table(logging_table, files_to_process)
    logger.info("Successfully finished job")
else:
    logger.info("Found no new files to process")
job.commit()
