data "aws_ssm_parameter" "fis-livevoxinput-destination-path" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/destination"
}

module "fis-sqs2sftp-livevoxinput" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-livevoxinput"
  region_code = var.region_code
  sftp_target_directory = data.aws_ssm_parameter.fis-livevoxinput-destination-path.value
  sftp_target_hostname = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/password"
  sftp_target_port = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/port"
  sftp_target_user_ssm = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-fis-livevoxinput-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "livevox_input/out"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}