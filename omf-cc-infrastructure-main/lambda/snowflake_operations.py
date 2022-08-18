import logging
import os
import json
import boto3

from datetime import datetime

from omfeds_lambda_python.reportutils import resolve_ssm_parameter, read_json_file_from_bucket_and_objectname, \
    split_s3_path_into_bucket_and_objectname
from omfeds_lambda_python.snowflakeconnector import SnowflakeConnector

logger = logging.getLogger()
loglevel = os.getenv("LOGLEVEL", "INFO")
logger.setLevel(loglevel)


# SQL_QUERIES_JSON_FILE - file with SQL queries
# SQL_QUERY_KEY - specific query to execute from queries dict
# DESTINATION_BUCKET - bucket to offload data
# DESTINATION_PREFIX - prefix for the destination key
# SSM_SSM_SNOWFLAKE_USER
# SSM_SSM_SNOWFLAKE_PASSWORD
# SSM_SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER
# SSM_SNOWFLAKE_WAREHOUSE
# SSM_SNOWFLAKE_ROLE
# SNOWFLAKE_SOURCE_DATABASE
# SNOWFLAKE_SOURCE_SCHEMA
# STORAGE_S3_INTEGRATION - integration object saved in SnowFlake with options for export, ie: IAM Role to be used, whitelisted buckets
def snowflake_offload_procedure(event, context):
    """Offload data from snowflake to s3 asynchronous"""

    # retrieve environment variables
    aws_region = os.getenv("AWS_REGION", "us-east-1")
    destination_bucket = os.getenv("DESTINATION_BUCKET")
    destination_prefix = os.getenv("DESTINATION_PREFIX")
    sql_queries_json_file = os.getenv("SQL_QUERIES_JSON_FILE")  # s3-bucket-name/path/to/file.json
    sql_query_usecase = os.getenv("SQL_QUERY_USECASE")
    # Snowflake connector parameters
    ssm_snowflake_user = os.getenv("SSM_SNOWFLAKE_USER")
    ssm_snowflake_password = os.getenv("SSM_SNOWFLAKE_PASSWORD")
    ssm_snowflake_account_identifier = os.getenv("SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER")
    ssm_snowflake_warehouse = os.getenv("SSM_SNOWFLAKE_WAREHOUSE", "ANALYSIS_01")
    ssm_snowflake_role = os.getenv("SSM_SNOWFLAKE_ROLE", "SF_RG_DB_ALL_SCH_RW")
    snowflake_source_database = os.getenv("SNOWFLAKE_SOURCE_DATABASE")
    snowflake_source_schema = os.getenv("SNOWFLAKE_SOURCE_SCHEMA")
    storage_s3_integration = os.getenv("STORAGE_S3_INTEGRATION")

    # get ssm values
    snowflake_user               = resolve_ssm_parameter(ssm_snowflake_user, aws_region)["Parameter"]["Value"]
    snowflake_password           = resolve_ssm_parameter(ssm_snowflake_password, aws_region)["Parameter"]["Value"]
    snowflake_account_identifier = resolve_ssm_parameter(ssm_snowflake_account_identifier, aws_region)["Parameter"]["Value"]
    snowflake_warehouse          = resolve_ssm_parameter(ssm_snowflake_warehouse, aws_region)["Parameter"]["Value"]
    snowflake_role               = resolve_ssm_parameter(ssm_snowflake_role , aws_region)["Parameter"]["Value"]


    queries_file_bucket, queries_file_path_key = split_s3_path_into_bucket_and_objectname(sql_queries_json_file)

    logger.info(f"Reading config file from bucket: {queries_file_bucket} at path key: {queries_file_path_key}")

    queries_dict = read_json_file_from_bucket_and_objectname(queries_file_bucket, queries_file_path_key)
    raw_sql_query = queries_dict.get(sql_query_usecase).get("sql_query")

    if raw_sql_query:
        logger.info(f"AWS region : {aws_region}.")
        logger.info(f"destination_bucket: {destination_bucket}.")
        logger.info(f"destination_prefix: {destination_prefix}.")
        logger.info(f"queries_file_bucket: {queries_file_bucket}.")
        logger.info(f"queries_file_path_key: {queries_file_path_key}.")
        logger.info(f"sql_query_key: {sql_query_usecase}.")
        logger.info(f"account_identifier: {snowflake_account_identifier}.")
        logger.info(f"snowflake_source_database: {snowflake_source_database}.")
        logger.info(f"snowflake_source_schema: {snowflake_source_schema}.")
        logger.info(f"snowflake_warehouse: {snowflake_warehouse}.")
        logger.info(f"snowflake_role: {snowflake_role}.")

        try:
            sf_helper = SnowflakeConnector(
                snowflake_user=snowflake_user,
                snowflake_password=snowflake_password,
                snowflake_account_identifier=snowflake_account_identifier,
                snowflake_source_database=snowflake_source_database,
                snowflake_source_schema=snowflake_source_schema,
                snowflake_warehouse=snowflake_warehouse,
                snowflake_role=snowflake_role
            )

            logger.info("Initialized connector object")

            logger.info(f"Executing SQL statement \n{raw_sql_query}")
            try:
                procedure_status = sf_helper.execute_stored_procedure(raw_sql_query)
            except Exception as e:
                message = f"Could not execute stored procedure in query {raw_sql_query}."
                message = f"{message}\n{e}"
                logger.error(message)
            else:
                logger.info(f"Procedure status: {procedure_status}")
                logger.info("Finished.")
        except Exception as e:
            message = f"Could not initialized SnowflakeConnector object.\n{e}"
            logger.error(message)
    else:
        logger.info(f"Query {sql_query_usecase} not found int queries_dict keys {queries_dict.keys()}")