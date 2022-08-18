locals {
  powercurve_common_tags = {
    Application = "PowerCurve"
    ApplicationSubject = "PowerCurve"
  }
}

data "aws_ssm_parameter" "declineletter-powercurve-sns-name" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/declineletter/powercurve/name"
}

#Lambda to copy to sftp
module "declineletter-sqs2sftp" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "powercurve-declineletter"
  region_code = var.region_code
  sftp_target_directory = "/cardsventure"
  sftp_target_hostname = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/password"
  sftp_target_port = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/port"
  sftp_target_user_ssm = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.declineletter-powercurve-sns-name.value}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "prepared"
  tags_var = local.powercurve_common_tags
}