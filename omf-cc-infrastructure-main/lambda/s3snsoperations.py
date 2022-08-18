
from requests.models import stream_decode_response_unicode
import boto3
import paramiko
import uuid
import logging
import json
import os
import re
import requests
import csv
import openpyxl
from datetime import date, datetime
from boto3.dynamodb.conditions import Key, Attr
from boto3.dynamodb.types import TypeDeserializer
import omfeds_lambda_python.reportutils as reportutils
from omfeds_lambda_python.sftpuploader import SftpUploader, SftpDownloader
from omfeds_lambda_python.fileencryptor import FileEncryptor, FileDecryptor
from omfeds_lambda_python.sftpremotefilenamedatafactory import RemoteFileNameDataFactory
from omfeds_lambda_python.pgpfilenamedatafactory import PGPFileNameDataFactory

logger = logging.getLogger()
loglevel = os.getenv("LOGLEVEL", "INFO")
logger.setLevel(loglevel)


def lambda_copy_s3_file(event, context):
    s3_client = boto3.client("s3")
    target_bucket = os.environ["TARGET_BUCKET"]
    source_bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    file_key_name = event["Records"][0]["s3"]["object"]["key"]
    copy_source_object = {"Bucket": source_bucket_name, "Key": file_key_name}
    s3_client.copy_object(
        CopySource=copy_source_object, Bucket=target_bucket, Key=file_key_name
    )

    return {"statusCode": 200, "body": f"Copied {file_key_name} to {target_bucket}"}


def sns2sftp_deliver_file(event, context):
    logger.info("Processing started - getting environment variables")
    source_filter_prefix = os.getenv("SOURCE_FILTER_PREFIX")
    aws_region = os.environ["AWS_REGION"]
    sftp_host = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_HOSTNAME"], aws_region
    )
    sftp_user = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_USER_SSM"], aws_region
    )
    sftp_pass = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_PASS_SSM"], aws_region
    )
    sftp_port =reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_PORT"], aws_region
    )
    sftp_directory = os.getenv("SFTP_TARGET_DIRECTORY", None)
    feedname = os.getenv("FEEDNAME", "objectname")

    hasfailedfiles = False
    filestatusdict = {"files": []}

    remotefilenamefactory = RemoteFileNameDataFactory(feedname)
    remotefilename = remotefilenamefactory.getremotefilename()

    if sftp_directory == "":
        sftp_directory = None

    logger.debug(f"File name: {remotefilename}")
    sftpuploader = SftpUploader(
        sftpuser=sftp_user["Parameter"]["Value"],
        sftppassword=sftp_pass["Parameter"]["Value"],
        sftphost=sftp_host["Parameter"]["Value"],
        sftpport=sftp_port["Parameter"]["Value"],
        sftpdirectory=sftp_directory,
    )

    for record in event["Records"]:
        try:
            messages = json.loads(record["Sns"]["Message"])
        except KeyError:
            messages = json.loads(json.loads(record["body"])["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]
            s3key = s3key.replace("+", " ")
            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Key name: {s3key}")

            if "/_temporary/" in s3key:
                logger.info("Skipping temporary folder")
                continue

            if source_filter_prefix and not re.match("^"+source_filter_prefix, s3key):
                logger.info("Event doesn't start with source prefix filter")
                continue

            if remotefilename == "objectname":
                remotefilename = s3filename
            try:
                reportutils.downloads3file(s3bucketname, s3key, f"/tmp/{remotefilename}")
            except Exception:
                message = f"Could not download {remotefilename} file from S3"
                logger.error(message)
                hasfailedfiles = True
                filestatusdict["files"].append({"name": s3filename, "status": "failed"})
                continue

            if "OMF_cards_ECOA_Adverse_action_Report_" in remotefilename:
                if(os.path.getsize(f"/tmp/{remotefilename}") > 52428800):
                    logger.info("File size for convertation is bigger than 50 MB!")
               
                wb = openpyxl.Workbook()
                ws = wb.active

                with open(f"/tmp/{remotefilename}") as f:
                    reader = csv.reader(f, delimiter=',')
                    for row in reader:
                        ws.append(row)

                remotefilename = remotefilename.replace(".csv", ".xlsx")
                wb.save(f"/tmp/{remotefilename}")

            sftpuploader.localfilename = f"/tmp/{remotefilename}"
            logger.info(f"Putting /tmp/{remotefilename} to SFTP")
            try:
                sftpuploader.sftpputlocalfile()
            except Exception:
                message = f"Could not upload {remotefilename} file to SFTP"
                logger.error(message)
                hasfailedfiles = True
                filestatusdict["files"].append({"name": s3filename, "status": "failed"})
                continue
            else:
                message = f"Uploaded {remotefilename} to SFTP successfully"
                logger.info(message)
                filestatusdict["files"].append(
                    {"name": s3filename, "status": "success"}
                )

    filestatusdict["hasfailedfiles"] = hasfailedfiles
    filestatusstring = json.dumps(filestatusdict)
    if hasfailedfiles:
        try:
            raise Exception("Couldn't upload all files")
        finally:
            return {
                "statusCode": 500,
                "body": filestatusstring,
            }
    else:
        return {
            "statusCode": 200,
            "body": filestatusstring,
        }


#Load files from sftp to s3 distanation (S3_TARGET_BUCKET + S3_TARGET_PREFIX)
#Write max file date from a batch to the DynamoDB log.
def sftp_download_files(event, context):
    logger.info("Processing started - getting environment variables")
    aws_region = os.environ["AWS_REGION"]
    sftp_host = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_HOSTNAME"], aws_region
    )
    sftp_user = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_USER_SSM"], aws_region
    )
    sftp_pass = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_PASS_SSM"], aws_region
    )
    sftp_port =reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_PORT"], aws_region
    )
    sftp_directory = os.getenv("SFTP_TARGET_DIRECTORY", None)
    s3_target_bucket = os.getenv("S3_TARGET_BUCKET", None)
    s3_target_prefix = os.getenv("S3_TARGET_PREFIX", None)
    dynamodb_sftp_log_table = os.getenv("SFTP_LOG_TABLE", None)
    filename_pattern = os.getenv("SFTP_FILENAME_PATTERN", None)
    feedname = os.getenv("FEEDNAME", "objectname")

    filenamelist = []
    max_time = datetime.strptime('1900-01-01 01:00:00', '%Y-%m-%d %H:%M:%S')
    hasfailedfiles = False
    filestatusdict = {"files": []}

    remotefilenamefactory = RemoteFileNameDataFactory(feedname)
    remotefilename = remotefilenamefactory.getremotefilename()

    if sftp_directory == "":
        sftp_directory = None

    logger.debug(f"File name: {remotefilename}")
    sftpdownloader = SftpDownloader(
        sftpuser=sftp_user["Parameter"]["Value"],
        sftppassword=sftp_pass["Parameter"]["Value"],
        sftphost=sftp_host["Parameter"]["Value"],
        sftpport=sftp_port["Parameter"]["Value"],
        sftpdirectory=sftp_directory,
    )

    logger.info(f"SFTP Filename pattern: {filename_pattern}")
    logger.info(f"SFTP directory: {sftp_directory}")
    logger.info(f"S3 Bucket name: {s3_target_bucket}")
    logger.info(f"S3 Key name: {s3_target_prefix}")

    latesttime = None

    logger.info("Reading log...")
    dynamodb = boto3.resource("dynamodb")
    dynamodb_table = dynamodb.Table(dynamodb_sftp_log_table)
    response = None

    kce = Key("file_name").eq("latestfile") & Key("processed_datetime").begins_with("2")
    response = dynamodb_table.query(KeyConditionExpression = kce, ScanIndexForward = False, Limit = 1)
    logger.debug(json.dumps(response))
    response = response["Items"]

    if response:
        latesttime = response[0]["processed_datetime"]

    logger.info("Reading log was successfull")

    #latesttime = None #for debug
    if latesttime is None:
        latesttime = datetime.strptime('1900-01-01 01:00:00', '%Y-%m-%d %H:%M:%S')
    else:
        latesttime = datetime.strptime(latesttime, '%Y-%m-%d %H:%M:%S')

    logger.info(f"LatestTime from log: {latesttime}.")
    logger.info(f"Get file list from SFTP...")
    filepropertieslist = sftpdownloader.listfiles(None, filename_pattern, 10000)
            
    if filepropertieslist:
        for fl in filepropertieslist:
            if fl[1] > latesttime:
                filenamelist.append(fl[0])
                if fl[1] > max_time:
                    max_time = fl[1]
                dynamodb_table.put_item(
                    Item = {
                        "file_name": fl[0],
                        "processed_datetime": fl[1].strftime("%Y-%m-%d %H:%M:%S")
                    }
                )

    logger.info(f"Download file list from SFTP to /tmp/...")
    try:
        if filenamelist:
            sftpdownloader.sftpgetfiles(filenamelist)
        else:
            logger.info("No files on SFTP.")

        logger.info("Downloading files was completed.")

        if filenamelist:
            logger.info(f"Putting /tmp/ files to S3...")
            for filename in filenamelist:
                reportutils.s3uploadfile("/tmp/" + filename, s3_target_bucket, s3_target_prefix, filename)

            logger.info(f"Logging max datetime: {max_time}.")
            dynamodb_table.put_item(
                Item = {
                    "file_name": "latestfile",
                    "processed_datetime": max_time.strftime("%Y-%m-%d %H:%M:%S")
                }
            )
        else:
            logger.info(f"Putting /tmp/ files to S3 was skipped.")
    except Exception:
        message = f"Could not download files from SFTP"
        logger.error(message)
        hasfailedfiles = True
        if not filenamelist:
            filenamelist = ["empty file list"]
        for filename in filenamelist:
            filestatusdict["files"].append({"name": filename, "status": "failed"})
    else:
        if filenamelist:
            for filename in filenamelist:
                filestatusdict["files"].append({"name": filename, "status": "success"})

    filestatusdict["hasfailedfiles"] = hasfailedfiles
    filestatusstring = json.dumps(filestatusdict)
    if hasfailedfiles:
        try:
            raise Exception("Couldn't download all files")
        finally:
            return {
                "statusCode": 500,
                "body": filestatusstring,
            }
    else:
        return {
            "statusCode": 200,
            "body": filestatusstring,
        }


def gpg_encrypt_file(event, context):
    logger.info("Processing started - getting environment variables")
    aws_region = os.environ["AWS_REGION"]
    source_filter_prefix = os.getenv("SOURCE_FILTER_PREFIX")
    public_key = reportutils.resolve_ssm_parameter(
        os.environ["PUBLIC_KEY_SSM"], aws_region
    )
    feedname = os.getenv("FEEDNAME", "objectname")
    pgptargets3bucket = os.environ["TARGET_S3_BUCKET"]
    pgpfiles3prefix = os.environ["TARGET_S3_PREFIX"]

    with open("/tmp/publickey.asc", "a") as f:
        f.write(public_key["Parameter"]["Value"])

    hasfailedfiles = False
    filestatusdict = {"files": []}

    pgpfilenamefactory = PGPFileNameDataFactory(feedname)
    pgpfilename = pgpfilenamefactory.getpgpfilename()

    logger.debug(f"File name: {pgpfilename}")

    for record in event["Records"]:
        try:
            messages = json.loads(record["Sns"]["Message"])
        except KeyError:
            messages = json.loads(json.loads(record["body"])["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]
            s3key = s3key.replace("+", " ")
            if "/_temporary/" in s3key:
                logger.info("Skipping temporary folder")
                continue

            if source_filter_prefix and not re.match("^" + source_filter_prefix, s3key):
                logger.info(f"Event doesn't start with source_prefix_filter {source_filter_prefix}. s3key: {s3key}")
                continue

            if pgpfilename == "objectname":
                pgpfilename = f"{s3filename}.gpg"

            reportutils.downloads3file(s3bucketname, s3key, f"/tmp/{s3filename}")
            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Downloaded: {s3filename}")
            fileencryptor = FileEncryptor(
                pgpfilename=f"/tmp/{pgpfilename}",
                pgpkey="/tmp/publickey.asc",
                datafilename=f"/tmp/{s3filename}",
            )
            try:
                encryptionstatus = fileencryptor.encryptfilepgp()
            except Exception as e:
                exceptioninfo = str(e)
                message = f"Could not encrypt {s3key} file: {exceptioninfo}"
                logger.error(message)
                logger.error(encryptionstatus)
                hasfailedfiles = True
                filestatusdict["files"].append(
                    {"name": s3filename, "status": f"failed: {encryptionstatus}"}
                )
                continue
            else:
                message = f"Encrypted {s3filename} successfully"
                logger.info(message)
                logger.info(encryptionstatus)
                filestatusdict["files"].append(
                    {"name": s3filename, "status": "success"}
                )
                logger.info(f"Put /tmp/{pgpfilename} to s3")
                reportutils.s3uploadfile(
                    f"/tmp/{pgpfilename}",
                    pgptargets3bucket,
                    pgpfiles3prefix,
                    pgpfilename,
                )

    filestatusdict["hasfailedfiles"] = hasfailedfiles
    filestatusstring = json.dumps(filestatusdict)
    if hasfailedfiles:
        try:
            raise Exception("Couldn't encrypt all files")
        finally:
            return {
                "statusCode": 500,
                "body": filestatusstring,
            }
    else:
        return {
            "statusCode": 200,
            "body": filestatusstring,
        }

# DESTINATION_BUCKET - mandatory
# CONFIG_FILE - optional. If existed - then it overwrites all oother params.
# SOURCE_PREFIX_FILTER- optional (with slash at the beginning - name "/fisvgs", without - number of folders to delete "1") - prefix that should be removed in the beginning of object path. <bucket>/<prefix>/<object_name>
# DESTINATION_PREFIX - optional. raw/creditcards. without slach at the end. <DESTINATION_BUCKET>/<DESTINATION_PREFIX>/<object_with_prefix_after_cut_by_filter>
# APPEND_DATETIME(boolean) optional - add folder structure at destination bucket. <DESTINATION_BUCKET>/<DESTINATION_PREFIX>/<year>/<month>/<day>/<hour>/<min>.
# APPEND_DATE(boolean) optional - not going to be implemented now. add only date without time. <DESTINATION_BUCKET>/<DESTINATION_PREFIX>/<year>/<month>/<day>. Could be overrided by APPEND_DATETIME
def sns_s3_copy_file(event, context):

    logger.info("Processing started - getting environment variables")

    def check_source_prefix_filter_type(source_prefix_filter):
        """Check if source_prefix_filter has the flag for number of folders to filter of is string filter"""
        if source_prefix_filter:
            if source_prefix_filter[0] != "/":
                source_prefix_filter = int(source_prefix_filter)
                return source_prefix_filter, True
            else:
                source_prefix_filter = source_prefix_filter[1:]
                return source_prefix_filter, False
        else:
            return source_prefix_filter, False

    aws_region = os.getenv("AWS_REGION")
    logger.info("AWS region : {}".format(aws_region))

    # retrieve env independent of config_file
    targets3bucket = os.getenv("DESTINATION_BUCKET")
    config_file = os.getenv("CONFIG_FILE")
    source_prefix_filter = ""
    s3_client = boto3.client("s3", aws_region)

    if not targets3bucket:
        return {
                "statusCode": 500,
                "body": "No destianation bucket specified",
        }

    if config_file:
        splitted_config_file = config_file.split("/")
        config_bucket        = splitted_config_file[0]
        config_path_key      = "/".join(splitted_config_file[1:])  # filter bucket name

        logger.info(f"Reading config file from bucket: {config_bucket} at path: {config_path_key}")

        s3 = boto3.resource("s3")
        config_obj = s3.Object(config_bucket, config_path_key)
        config_file = config_obj.get()["Body"].read().decode("utf-8")
        config_dict = json.loads(config_file)
    else:
        source_prefix_filter = os.getenv("SOURCE_PREFIX_FILTER")
        destination_prefix   = os.getenv("DESTINATION_PREFIX")
        append_datetime      = os.getenv("APPEND_DATETIME")
        if append_datetime == "true":
            append_datetime = True
        else:
            append_datetime = False

    hasfailedfiles = False
    filestatusdict = {"files": []}
    targets3prefix = ""
    # check if we need to filter based on a number of folders
    folder_nr_source_prefix_filter = False
    source_prefix_filter, folder_nr_source_prefix_filter = check_source_prefix_filter_type(source_prefix_filter)

    for record in event["Records"]:
        try:
            messages = json.loads(record["Sns"]["Message"])
        except KeyError:
            messages = json.loads(json.loads(record["body"])["Message"])
        for message in messages["Records"]:
            copy_option_saved = False
            s3bucketname   = message["s3"]["bucket"]["name"]
            s3filename     = message["s3"]["object"]["key"].split("/")[-1]
            s3key          = message["s3"]["object"]["key"]    # foo/bar/file.ext
            targets3prefix = "/".join(s3key.split("/")[:-1])   #  -- without filename -- foo/bar or ''

            logger.info(f"Notification record from bucket {s3bucketname} and key {s3key}")
            s3key = s3key.replace("+", " ")
            if "/_temporary/" in s3key:
                logger.info("Skipping temporary folder")
                continue

            # if config_file we should load info from there
            if config_file:
                copy_option_list = config_dict["copy_options"]
                if copy_option_list:
                    # check if copy_option source_prefixkey is found in variable that contains the prefix.
                    for option in copy_option_list:
                        option_source_prefix_filter = option["source_prefix_filter"]
                        if re.match("^"+option_source_prefix_filter, s3key):
                            destination_prefix   = option["destination_prefix"]
                            source_prefix_filter = option_source_prefix_filter
                            copy_option_saved = True
                    if not copy_option_saved:
                        continue
                    append_datetime = config_dict["append_datetime"]
            else:
                if not re.match("^"+source_prefix_filter, s3key):
                    logger.info(f"Event doesn't start with source_prefix_filter {source_prefix_filter}. s3key: {s3key}")
                    continue
            # Below if statement order is important for proper targets3prefix
            if folder_nr_source_prefix_filter:
                targets3prefix = "/".join(s3key.split("/")[int(source_prefix_filter):])
            elif source_prefix_filter:
                # add a trailing slash to source_prefix_filter to have foo/bar structure and not /foo/bar after filter
                source_prefix_filter = source_prefix_filter + "/"
                index_to_slice = re.match("^"+source_prefix_filter, s3key).span()[1]
                targets3prefix = targets3prefix[index_to_slice:]
            if append_datetime:
                datetime_str = datetime.utcnow().strftime("%Y/%m/%d/%H/%M")
                if targets3prefix:
                    targets3prefix = f"{datetime_str}/{targets3prefix}"
                else:
                    targets3prefix = datetime_str

            if destination_prefix:
                if targets3prefix:
                    targets3prefix = f"{destination_prefix}/{targets3prefix}"
                else:
                    targets3prefix = destination_prefix

            # TODO: find a more elegant solution to this replace
            targets3prefix = targets3prefix.replace("%3D","=")

            copy_source_object = {"Bucket": s3bucketname, "Key": s3key.replace("%3D","=")}

            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Downloaded: {s3filename}")
            logger.info(f"targets3prefix: {targets3prefix}")
            if targets3prefix == "":
                file_key_name = s3key
            else:
                file_key_name = f"{targets3prefix}/{s3filename}"

            try:
                s3_client.copy_object(
                    CopySource=copy_source_object,
                    Bucket=targets3bucket,
                    Key=file_key_name,
                    ACL="bucket-owner-full-control",
                )
            except Exception as e:
                exceptioninfo = str(e)
                message = f"Could not copy {s3key} file: {exceptioninfo}"
                logger.error(message)
                hasfailedfiles = True
                filestatusdict["files"].append(
                    {"name": s3filename, "status": f"failed: {exceptioninfo}"}
                )
                continue
            else:
                message = f"Copied {s3filename} successfully"
                logger.info(message)
                filestatusdict["files"].append(
                    {"name": s3filename, "status": "success"}
                )

    filestatusdict["hasfailedfiles"] = hasfailedfiles
    filestatusstring = json.dumps(filestatusdict)
    if hasfailedfiles:
        try:
            raise Exception("Couldn't copy all files")
        finally:
            return {
                "statusCode": 500,
                "body": filestatusstring,
            }
    else:
        return {
            "statusCode": 200,
            "body": filestatusstring,
        }

def s32luminate(event, context):
    aws_region = os.environ["AWS_REGION"]
    client_id = reportutils.resolve_ssm_parameter(
        os.environ["CLIENT_ID_SSM"], aws_region
    )["Parameter"]["Value"]
    client_secret = reportutils.resolve_ssm_parameter(
        os.environ["CLIENT_SECRET_SSM"], aws_region
    )["Parameter"]["Value"]
    auth_endpoint = reportutils.resolve_ssm_parameter(
        os.environ["AUTHORIZATION_ENDPOINT_SSM"], aws_region
    )["Parameter"]["Value"]
    api_endpoint = reportutils.resolve_ssm_parameter(
        os.environ["API_ENDPOINT_SSM"], aws_region
    )["Parameter"]["Value"]
    scope = os.environ["SCOPE"]
    source_prefix_filter = os.getenv("SOURCE_FILTER_PREFIX")
    for record in event["Records"]:
        try:
            messages = json.loads(record["Sns"]["Message"])
        except KeyError:
            messages = json.loads(json.loads(record["body"])["Message"])
        for message in messages["Records"]:
            s3bucketname   = message["s3"]["bucket"]["name"]
            s3key          = message["s3"]["object"]["key"]
            s3key = s3key.replace("+", " ").replace("%3D","=")

            logger.info(f"Notification record from bucket {s3bucketname} and key {s3key}")

            if "/_temporary/" in s3key:
                logger.info("Skipping temporary folder")
                continue

            if not re.match("^" + source_prefix_filter, s3key):
                logger.info("Event doesn't start with source prefix filter")
                continue

            s3 = boto3.resource("s3")
            try:
                file_obj = s3.Object(s3bucketname, s3key)
                file = file_obj.get()["Body"].read().decode("utf-8")
                file_dict = json.dumps(json.loads(file))
            except Exception as e:
                logger.info(f"Couldn't process file, exception is {e}")
                continue

            auth_headers = {'Content-Type': 'text/plain'}
            auth_data = f"client_id={client_id}&client_secret={client_secret}&grant_type=client_credentials&scope={scope}"
            auth_response = requests.post(auth_endpoint, data=auth_data, headers=auth_headers).json()
            try:
                access_token = auth_response['access_token']
                logger.info("Successfully got access token")
            except KeyError as e:
                logger.info("Couldn't get access token, response is {}".format(auth_response))
                raise e

            request_id = str(uuid.uuid4())
            logger.info(f"Request id is {request_id}")
            headers = {'Content-Type' : 'application/json', 'Authorization' : "Bearer " + access_token, 'efx-client-correlation-id' : request_id}
            data = file_dict
            response = requests.post(api_endpoint, data = data, headers = headers).json()

            try:
                blocklistResponseItems = response['blocklistResponseItems']
                for item in blocklistResponseItems:
                    if item['updateStatus'] != 'succeeded':
                        logger.info("Update status of failed item :" +item['updateStatus'])
                        raise Exception("Some of items were not updated successfully")
                logger.info("Successfully sent request with {} items".format(str(len(blocklistResponseItems))))
            except KeyError as e:
                logger.info("Failed to process request, response is {}".format(response))
                raise e


def gpg_decrypt_file(event, context):
    '''
    Decrypts files using private key store in SSM paramter sotre and puts it to s3 bucket

    Mandatory environment variables:
    PRIVATE_KEY_SSM  - SSM parameter store entry containing private key
    TARGET_S3_BUCKET - s3 bucket to store decrypted file
    TARGET_S3_PREFIX - s3 prefix for decrypted file

    Optional environment variable:
    FEEDNAME             -  used to determine name of decrypted file and s3 object which
                            stores it. If any specific filename is required it has to be
                            set to value matching feedname variable in pgpfilenamedata.py
                            data classes.

                            E.g if we want to use file name defined by specific dataclass
                            then we seet feedname variable value and then same value should
                            be set in feedname parameter
    SOURCE_FILTER_PREFIX  - s3 object prefix that triggered the event has to match in order for lambda to decrypt
    ENCRYPTED_FILE_SUFFIX - encrypted s3 file suffix to be removed after decryption, removed nothing if missing.
                            If this is missing in order to not have same name for files that are encrypted and decrypted
                            we add "decrypted_" prefix for decrypted files

    '''

    logger.info("Processing started - getting environment variables")
    aws_region = os.environ["AWS_REGION"]
    source_filter_prefix = os.getenv("SOURCE_FILTER_PREFIX")
    encrypted_file_suffix = os.getenv("ENCRYPTED_FILE_SUFFIX", "")
    public_key = reportutils.resolve_ssm_parameter(
        os.environ["PRIVATE_KEY_SSM"], aws_region
    )
    feedname = os.getenv("FEEDNAME", "objectname")
    decrypted_target_bucket = os.environ["TARGET_S3_BUCKET"]
    decrypted_file_s3_prefix = os.environ["TARGET_S3_PREFIX"]

    logger.info(f"encrypted_file_suffix: {encrypted_file_suffix}")

    with open("/tmp/privatekey.asc", "w") as f:
        f.write(public_key["Parameter"]["Value"])

    hasfailedfiles = False
    filestatusdict = {"files": []}

    pgpfilenamefactory = PGPFileNameDataFactory(feedname)
    pgpfilename = pgpfilenamefactory.getpgpfilename()

    logger.debug(f"File name: {pgpfilename}")

    for record in event["Records"]:
        try:
            messages = json.loads(record["Sns"]["Message"])
        except KeyError:
            messages = json.loads(json.loads(record["body"])["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]
            s3key = s3key.replace("+", " ")
            if "/_temporary/" in s3key:
                logger.info("Skipping temporary folder")
                continue

            if source_filter_prefix and not re.match("^" + source_filter_prefix, s3key):
                logger.info(f"Event doesn't start with source_prefix_filter {source_filter_prefix}. s3key: {s3key}")
                continue

            if encrypted_file_suffix and encrypted_file_suffix[-len(encrypted_file_suffix):] == encrypted_file_suffix:
                logger.info(f"Removing suffix {encrypted_file_suffix} from {pgpfilename}")
                pgpfilename = pgpfilename[:-len(encrypted_file_suffix)]
            elif pgpfilename == "objectname":
                pgpfilename = f"decrypted_{s3filename}"

            reportutils.downloads3file(s3bucketname, s3key, f"/tmp/{s3filename}")
            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Downloaded: {s3filename} to /tmp/{s3filename}")
            filedecryptor = FileDecryptor(
                pgpfilename=f"/tmp/{pgpfilename}",
                pgpkey="/tmp/privatekey.asc",
                datafilename=f"/tmp/{s3filename}",
            )
            try:
                decryptionstatus = filedecryptor.decryptfilepgp()
            except Exception as e:
                exceptioninfo = str(e)
                message = f"Could not decrypt {s3key} file: {exceptioninfo}"
                logger.error(message)
                logger.error(decryptionstatus)
                hasfailedfiles = True
                filestatusdict["files"].append(
                    {"name": s3filename, "status": f"failed: {decryptionstatus}"}
                )
                continue
            else:
                message = f"Decrypted {s3filename} successfully"
                logger.info(message)
                logger.info(decryptionstatus)
                filestatusdict["files"].append(
                    {"name": s3filename, "status": "success"}
                )
                logger.info(f"Put /tmp/{pgpfilename} to s3")
                reportutils.s3uploadfile(
                    f"/tmp/{pgpfilename}",
                    decrypted_target_bucket,
                    decrypted_file_s3_prefix,
                    pgpfilename,
                )

    filestatusdict["hasfailedfiles"] = hasfailedfiles
    filestatusstring = json.dumps(filestatusdict)
    if hasfailedfiles:
        try:
            raise Exception("Couldn't decrypt all files")
        finally:
            return {
                "statusCode": 500,
                "body": filestatusstring,
            }
    else:
        return {
            "statusCode": 200,
            "body": filestatusstring,
        }

