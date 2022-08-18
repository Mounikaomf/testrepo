import sys
import os
from awsglue.transforms import *
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, lit, broadcast
from pyspark.sql.types import *
from pyspark.sql import SQLContext
import datetime
import boto3
import logging
import requests
import re

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger("FIS")
logger.setLevel(logging.INFO)

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


def remove_prefix(column_name):
    if column_name.split("_")[0] != "FILLER" and column_name != "FILE_DT":
        return column_name[column_name.find("_") + 1:], column_name[:column_name.find("_")]
    return column_name, ""


def flatten(schema, fields=None, prefix=None):
    if not fields:
        fields = []
    for field in schema.fields:
        full_name = prefix + "." + field.name if prefix else field.name
        node_names = full_name.split(".")
        dtype = field.dataType
        if isinstance(dtype, ArrayType):
            dtype = dtype.elementType
        if isinstance(dtype, StructType):
            fields = flatten(dtype, fields, prefix=full_name)
        else:
            name = ""
            names = [name for name, full_name in fields]
            for node_id in range(len(node_names) - 1, -1, -1):
                current_node_name, current_node_prefix = remove_prefix(node_names[node_id])
                name = current_node_name + "_" + name if name is not "" else current_node_name
                if re.match(r"^FILLER_P[1-9][0-9]*$", name):
                    continue
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
            logger.debug("Final name for column {0} is {1}".format(full_name, name))
    return fields


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

def get_latest_copybook(copybooks):
    return max(copybooks, key = lambda copybook : int(copybook[copybook.rfind("_")+1:copybook.rfind(".")]))

def read_dataframe(spark, copybook):
    return spark.read.format("cobol") \
        .option("is_record_sequence", "true") \
        .option("is_text", "true") \
        .option("encoding", "ascii") \
        .option("copybook", copybook) \
        .option("enable_indexes", "false") \
        .option("input_split_size_mb", "256") \
        .option("drop_value_fillers", "false") \
        .option("generate_record_id", "true") \
        .option("schema_retention_policy", "collapse_root") \
        .option("paths", ",".join(files_to_process)) \
        .load()

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
        "bucket_config",
        "source_prefix",
        "target_prefix",
        "JOB_NAME",
        "copybook_prefix",
        "header_copybook_prefix",
        "logging_table",
    ],
)
spark = glue_context.spark_session
bucket = args["bucket"]
bucket_config = args["bucket_config"]
source_prefix = args["source_prefix"]
target_prefix = args["target_prefix"]
copybook_prefix = args["copybook_prefix"]
header_copybook_prefix = args["header_copybook_prefix"]
logging_table = args["logging_table"]

logger.info("Bucket : {}".format(bucket))
logger.info("Config bucket : {}".format(bucket_config))
logger.info("Source prefix : {}".format(source_prefix))
logger.info("Target prefix : {}".format(target_prefix))
logger.info("Copybook prefix : {}".format(copybook_prefix))
logger.info("Copybook header prefix : {}".format(header_copybook_prefix))
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

copybooks = get_objects_from_s3(bucket_config, copybook_prefix)

header_copybooks = get_objects_from_s3(bucket_config, header_copybook_prefix)

if len(files_to_process) > 0:
    if len(copybooks) > 0 and len(header_copybooks) > 0:
        copybook = get_latest_copybook(copybooks)
        header_copybook = get_latest_copybook(header_copybooks)
        logger.info("Copybook : {}".format(copybook))
        logger.info("Header copybook : {}".format(header_copybook))
        logger.info("Files to process :\n" + "\n".join(files_to_process))
        header_DF = read_dataframe(spark, header_copybook) \
            .filter("Record_Id == 0") \
            .select(col("File_Id").alias("Header_File_Id"),"FILE_DT")
        input_DF = read_dataframe(spark, copybook) \
            .filter("Record_Id > 0") \
            .join(broadcast(header_DF), col("File_Id") == header_DF["Header_File_Id"]) \
            .drop("File_Id", "Record_Id", "Header_File_Id")
        input_DF.persist()
        logger.info("Processing {} records".format(input_DF.count()))
        now = datetime.datetime.now()
        flattened_DF = input_DF \
            .select([col(full_name).alias(name) for name, full_name in flatten(input_DF.schema)]) \
            .withColumn("year", lit(now.year)) \
            .withColumn("month", lit(now.month)) \
            .withColumn("day", lit(now.day))
        flattened_DF \
            .coalesce(1) \
            .write \
            .format("parquet") \
            .partitionBy("year", "month", "day") \
            .mode("append") \
            .save(build_uri_from_bucket_and_key(bucket, target_prefix).replace("s3://","s3a://")+"/")
        add_files_to_logging_table(logging_table, files_to_process)
    else:
        logger.info("No copybooks for data or header were found to process")
else:
    logger.info("No files were found to process")
job.commit()
