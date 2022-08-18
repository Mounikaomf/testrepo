import boto3
import json

from typing import Tuple
from pathlib import Path

from botocore.exceptions import ClientError


def downloads3file(s3bucketname, s3objectname, localfilename):

    localfile = Path(localfilename)
    try:
        localpath = localfile.resolve(strict=True)
    except FileNotFoundError:
        s3 = boto3.client("s3")
        s3.download_file(s3bucketname, s3objectname, localfilename)
    else:
        pass


def s3uploadfile(filename, bucket, bucketprefix=None, s3objectname=None):

    # If S3 object_name was not specified, use file_name
    if s3objectname is None:
        s3objectname = filename

    if bucketprefix is None:
        objectname = s3objectname
    else:
        objectname = "/".join([bucketprefix, s3objectname])

    # Upload the file
    s3_client = boto3.client("s3")
    try:
        response = s3_client.upload_file(filename, bucket, objectname)
    except ClientError as e:
        raise ConnectionError
        return False
    return True


def resolve_ssm_parameter(parametername, aws_region, withdecryptionflag = True):
    session = boto3.Session(region_name=aws_region)
    ssm = session.client('ssm')
    return ssm.get_parameter(Name=parametername, WithDecryption=withdecryptionflag)


def read_json_file_from_bucket_and_objectname(bucket: str, s3objectname: str) -> dict:
    """Read json file from s3 and return contents"""

    s3 = boto3.resource("s3")
    config_obj = s3.Object(bucket, s3objectname)
    config_file = config_obj.get()["Body"].read().decode("utf-8")

    return json.loads(config_file)


def split_s3_path_into_bucket_and_objectname(s3_path: str) -> Tuple[str, str]:
    """Split s3 path into bucket and file object name
    [s3://]bucket-name/file/object/name.ext -> ('bucket-name', 'file/object/name.ext')
    """

    s3_path = s3_path.replace("s3://", "").replace("s3a://", "")

    split_s3_path = s3_path.split("/")
    s3_bucket = split_s3_path[0]
    s3_objectname = "/".join(split_s3_path[1:])  # filter bucket name

    return s3_bucket, s3_objectname