import datetime
import time
import json
import sys
import os
import requests
import logging
import uuid
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3

def build_uri_from_bucket_and_key(bucket, key):
    return "s3://" + os.path.join(bucket, key)

def write_records_to_sns(partition):
    client = boto3.client('sns', region_name=aws_region)
    s3 = boto3.resource("s3")
    config_obj = s3.Object(config_bucket, config_key)
    config_file = config_obj.get()["Body"].read().decode("utf-8")
    config_dict = json.loads(config_file)
    for row in partition:
        try:
            sns_message = {}
            for column in config_dict["columns"]:
                if "name" not in column:
                    if "default_value" not in column:
                        if column["generate"] == "uuid":
                            value = str(uuid.uuid4())
                        elif column["generate"] == "timestamp":
                            value = str(int(time.time()))
                    else:
                        value = column["default_value"]
                else:
                    value = row[column["name"]]
                if "data_type" in column:
                    if column["data_type"] == "float":
                        value = float(value)
                    elif column["data_type"] == "date":
                        value = datetime.datetime.strptime(value, column["format"]).strftime(column["final_format"])
                key = column["final_name"]
                names = key.split(".")
                nested_dict = sns_message
                for index in range(len(names)):
                    if index == len(names)-1:
                        nested_dict.update({names[index]:value})
                    else:
                        if names[index] not in nested_dict:
                            nested_dict.update({names[index]:{}})
                        nested_dict = nested_dict[names[index]]
            response = client.publish(
                TargetArn=sns_arn,
                Message=json.dumps({'default' : json.dumps(sns_message)}),
                MessageStructure='json'
            )
            if "MessageId" not in response:
                yield row
        except:
            yield row

## @params: [JOB_NAME]
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "bucket",
        "config_bucket",
        "config_key",
        "source_prefix",
        "sns_arn",
    ],
)

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger("S3_TO_SNS")
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
source_prefix = args["source_prefix"]
sns_arn = args["sns_arn"]
config_bucket = args["config_bucket"]
config_key = args["config_key"]

logger.info(f"bucket: {bucket}.")
logger.info(f"source_prefix: {source_prefix}.")
logger.info(f"aws_region: {aws_region}.")
logger.info(f"sns_arn: {sns_arn}.")

job.init(args["JOB_NAME"], args)

input_path = build_uri_from_bucket_and_key(bucket, source_prefix)

input_df = glue_context \
    .create_dynamic_frame_from_options(connection_type="s3",
                connection_options={"paths": [input_path],
                'recurse': True}, format="parquet",
                transformation_ctx="input_df") \
    .toDF().repartition(48)

helper_df = input_df.rdd \
        .mapPartitions(write_records_to_sns)

logger.info("Amount of failed records : {}".format(helper_df.count()))

logger.info("Job finished successfully")

job.commit()
