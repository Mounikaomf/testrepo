import sys
import os
import requests
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import Relationalize
import boto3


## @params: [JOB_NAME]
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "bucket",
        "target_prefix",
        "source_database",
        "source_table",
    ],
)

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger("CustomerView")
logger.setLevel(logging.INFO)

#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
r = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
response_json = r.json()
aws_region = response_json.get('region')
s3 = boto3.client("s3", region_name=aws_region)

logger.info("Create glue context")
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
logger.info("Set job parameters")
bucket = args["bucket"]
target_prefix = args["target_prefix"]
source_database = args["source_database"]
source_table = args["source_table"]

logger.info(f"bucket: {bucket}.")
logger.info(f"target_prefix: {target_prefix}.")
logger.info(f"source_database: {source_database}.")
logger.info(f"source_table: {source_table}.")
logger.info(f"aws_region: {aws_region}.")

job.init(args["JOB_NAME"], args)

logger.info("Load dynamic dataframe from table")
datasource0 = glueContext.create_dynamic_frame.from_catalog(
    database=source_database, table_name=source_table, transformation_ctx="datasource0"
)

datasource1 = datasource0.coalesce(1)

logger.info("Apply mapping")
# TODO: check why partition_0 is 'export' as of now
applymapping1 = ApplyMapping.apply(
    frame=datasource1,
    mappings=[
        ("customerid", "string", "CUSTOMERID", "string"),
        ("pan_tokenized", "string", "PAN_TOKENIZED", "string"),
        ("partition_0", "string", "year", "string"),
        ("partition_1", "string", "month", "string"),
        ("partition_2", "string", "day", "string"),
        ("partition_3", "string", "hour", "string"),
    ],
    transformation_ctx="applymapping1",
)

logger.info("Resolve choice")
resolvechoice2 = ResolveChoice.apply(
    frame=applymapping1, choice="make_struct", transformation_ctx="resolvechoice2"
)


logger.info("Drop null fields")
dropnullfields3 = DropNullFields.apply(
    frame=resolvechoice2, transformation_ctx="dropnullfields3"
)

logger.info("Write data to temporary parquet folder")
fullpath_parquet = "s3a://" + os.path.join(bucket, target_prefix)

datasink4 = glueContext.write_dynamic_frame.from_options(
    frame=dropnullfields3,
    connection_type="s3",
    connection_options={
        "path": fullpath_parquet,
        "partitionKeys": ["year", "month", "day", "hour"],
    },
    format="parquet",
    transformation_ctx="datasink4",
)

logger.info(f"Parquet file created: {fullpath_parquet}.")

logger.info("Commit job")
job.commit()
