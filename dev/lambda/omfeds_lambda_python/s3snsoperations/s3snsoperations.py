import boto3
import paramiko
import logging
import json
import os
import pendulum
import omfeds_lambda_python.reportutils as reportutils
from omfeds_lambda_python.sftpuploader import SftpUploader
from omfeds_lambda_python.fileencryptor import FileEncryptor
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
    '''
    Function to sftp file from s3 bucket. Takes filename from sns event or 
    remotefilenamedata.py

    Mandatory environment variables:
    aws_region - AWS Region, to be deprecated once getting region from session
                 data is implemented
    SFTP_TARGET_HOSTNAME - SFTP hostname
    SFTP_TARGET_USER_SSM - SSM Parameter store key containing SFTP user
    SFTP_TARGET_PASS_SSM - SSM Parameter store key containing SFTP password

    Optional environment variables:
    SFTP_TARGET_PORT - SFTP port, defaults to 22
    SFTP_TARGET_DIRECTORY - SFTP target directory, defaults to /
    FEEDNAME - Used by sftpremotefilenamedatafactory.py to determine filename
               defaults to file name from SNS event. If any specific filename 
               is required it has to be set to value matching feedname variable
               in remotefilenamedata.py data classes.

               E.g if we want to use file name defined by specific dataclass
               then we seet feedname variable value and then same value should
               be set in feedname parameter

    '''
    logger.info("Processing started - getting environment variables")
    aws_region = os.environ["aws_region"]
    sftp_host = os.environ["SFTP_TARGET_HOSTNAME"]
    sftp_user = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_USER_SSM"], aws_region
    )
    sftp_pass = reportutils.resolve_ssm_parameter(
        os.environ["SFTP_TARGET_PASS_SSM"], aws_region
    )
    sftp_port = os.getenv("SFTP_TARGET_PORT", 22)
    sftp_directory = os.getenv("SFTP_TARGET_DIRECTORY", None)
    feedname = os.getenv("FEEDNAME", "objectname")

    hasfailedfiles = False
    filestatusdict = {"files": []}

    remotefilenamefactory = RemoteFileNameDataFactory(feedname)
    remotefilename = remotefilenamefactory.getremotefilename()

    logger.debug(f"File name: {remotefilename}")
    sftpuploader = SftpUploader(
        sftpuser=sftp_user["Parameter"]["Value"],
        sftppassword=sftp_pass["Parameter"]["Value"],
        sftphost=sftp_host,
        sftpport=sftp_port,
        sftpdirectory=sftp_directory,
    )

    for record in event["Records"]:
        messages = json.loads(record["Sns"]["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]

            if remotefilename == "objectname":
                remotefilename = s3filename

            reportutils.downloads3file(s3bucketname, s3key, f"/tmp/{remotefilename}")
            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Download: {s3filename}")
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


def gpg_encrypt_file(event, context):
    '''
    Encrypts files using public key stored in SSM parameter store and puts it to s3 bucket

    Mandatory environment variables:
    aws_region - AWS Region, to be deprecated once getting region from session
                 data is implemented
    PUBLIC_KEY_SSM - SSM parameter store entry containing public key
    TARGET_S3_BUCKET - s3 bucket to store encrypted file
    TARGET_S3_PREFIX - s3 prefix for encrypted file

    Optional environment variable:
    FEEDNAME - used to determine name of encrypted file and s3 object which
               stores it. If any specific filename is required it has to be
               set to value matching feedname variable in pgpfilenamedata.py
               data classes.

               E.g if we want to use file name defined by specific dataclass
               then we seet feedname variable value and then same value should
               be set in feedname parameter

    '''
    logger.info("Processing started - getting environment variables")
    aws_region = os.environ["aws_region"]
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
        messages = json.loads(record["Sns"]["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]

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


def sns_s3_copy_file(event, context):
    '''
    Used to copy file between s3 buckets. Source bucket is extracted from SNS 
    event, target bucket and prefix is set as environment variable. 

    Mandatory environment variables:
    TARGET_BUCKET - target s3 bucket

    Optional environment variables:
    TARGET_PREFIX - prefix to be used for object in target bucket, defaults to
                    prefix in source SNS event
    aws_region - AWS Region, to be deprecated once getting region from session
                 data is implemented. Defaults to us-east-1

    '''
    logger.info("Processing started - getting environment variables")
    aws_region = os.getenv("aws_region", "us-east-1")
    targets3bucket = os.environ["TARGET_BUCKET"]
    targets3prefix = os.getenv("TARGET_PREFIX", None)
    s3_client = boto3.client("s3")

    hasfailedfiles = False
    filestatusdict = {"files": []}

    for record in event["Records"]:
        messages = json.loads(record["Sns"]["Message"])
        for message in messages["Records"]:
            s3bucketname = message["s3"]["bucket"]["name"]
            s3filename = message["s3"]["object"]["key"].split("/")[-1]
            s3key = message["s3"]["object"]["key"]

            copy_source_object = {"Bucket": s3bucketname, "Key": s3key}

            reportutils.downloads3file(s3bucketname, s3key, f"/tmp/{s3filename}")
            logger.info(f"Bucket name {s3bucketname}")
            logger.info(f"Downloaded: {s3filename}")

            if targets3prefix is None:
                file_key_name = s3key
            else:
                file_key_name = f"{targets3prefix}/{s3filename}"

            try:
                s3_client.copy_object(
                    CopySource=copy_source_object,
                    Bucket=targets3bucket,
                    Key=file_key_name,
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
