locals {
  webbank_common_tags = {
    Application = "WebBankReport"
    ApplicationSubject = "WebBankReport"
  }
}

module "webbankreport-sqs2sftp-webbankreport1" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "WebBankReport1"
  name = "webbankreport1"
  region_code = var.region_code
  sftp_target_directory = "/to_WB"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-webbankreport1-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "webbank_report_1/out"
  tags_var = local.webbank_common_tags
}

module "webbankreport-sqs2sftp-webbankreport2" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "WebBankReport2"
  name = "webbankreport2"
  region_code = var.region_code
  sftp_target_directory = "/to_WB"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-webbankreport2-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "webbank_report_2/out"
  tags_var = local.webbank_common_tags
}

module "webbankreport-sqs2sftp-webbankreport4" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "WebBankReport4"
  name = "webbankreport4"
  region_code = var.region_code
  sftp_target_directory = "/to_WB"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-webbankreport4-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "webbank_report_4/out"
  tags_var = local.webbank_common_tags
}
