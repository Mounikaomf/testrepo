import datetime
import json
import sys
import os
import requests
import logging
from awsglue.transforms import *
from pyspark.sql.functions import col, lit, when, collect_list, struct, row_number
from pyspark.sql.window import Window
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import Relationalize
import boto3


def build_uri_from_bucket_and_key(bucket, key):
    return "s3://" + os.path.join(bucket, key)


## @params: [JOB_NAME]
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "bucket",
        "target_prefix",
        "target_bucket",
        "source_prefix",
        "config_bucket",
        "config_key",
    ],
)

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger("Luminate")
logger.setLevel(logging.INFO)

#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
response_json = r.json()
aws_region = response_json.get('region')

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
bucket = args["bucket"]
target_bucket = args["target_bucket"]
target_prefix = args["target_prefix"]
source_prefix = args["source_prefix"]
config_bucket = args["config_bucket"]
config_key = args["config_key"]

logger.info(f"bucket: {bucket}.")
logger.info(f"target_prefix: {target_prefix}.")
logger.info(f"target_bucket: {target_bucket}")
logger.info(f"source_prefix: {source_prefix}.")
logger.info(f"aws_region: {aws_region}.")

job.init(args["JOB_NAME"], args)

input_path = build_uri_from_bucket_and_key(bucket, source_prefix)

input_df = glue_context \
    .create_dynamic_frame_from_options(connection_type="s3",
                connection_options={"paths": [input_path],
                'recurse': True}, format="parquet",
                transformation_ctx="input_df") \
    .toDF()

input_df.persist()
new_rows = input_df.count()
if new_rows > 0:
    logger.info(f"Found new {new_rows} rows")
    s3 = boto3.resource("s3")
    config_obj = s3.Object(config_bucket, config_key)
    config_file = config_obj.get()["Body"].read().decode("utf-8")
    config_dict = json.loads(config_file)

    mapping_list = config_dict["mapping"]
    condition = None
    for mapping in mapping_list:
        key = mapping["key"]
        value = mapping["value"]
        if condition is None:
            condition = when(col("ATTR_TYP")==key, value)
        else:
            condition = condition.when(col("ATTR_TYP")==key, value)
    condition = condition.otherwise("ignore")
    now = datetime.datetime.now()
    input_df \
        .withColumn("entityName", condition) \
        .filter(col("entityName") != "ignore") \
        .withColumn("eid", col("ATTR_VAL")) \
        .withColumn("appPrefix", lit("OMF")) \
        .withColumn("feedbackStatus", lit("Blacklisted")) \
        .withColumn("expiryDate", lit((now+datetime.timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3]+"Z")) \
        .withColumn("partition", (row_number().over(Window.orderBy(lit(0))) / 100).cast('integer')) \
        .groupBy("partition") \
        .agg(collect_list(struct("entityName", "eid", "appPrefix", "feedbackStatus", "expiryDate")).alias("blocklistItems")) \
        .withColumn("year", lit(now.year)) \
        .withColumn("month", lit(now.month)) \
        .withColumn("day", lit(now.day)) \
        .write \
        .format("json") \
        .partitionBy("year", "month", "day", "partition") \
        .mode("append") \
        .save(build_uri_from_bucket_and_key(target_bucket, target_prefix).replace("s3://","s3a://")+"/")
else:
    logger.info("No new rows were found")
logger.info("Finished job")
job.commit()
