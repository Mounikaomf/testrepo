module "module314a-sqs2sftp" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "Report314a"
  name = "314a"
  region_code = var.region_code
  sftp_target_directory = "/CARDS_OFAC"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-314a-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "report314a/out"
  tags_var = local.report314a_common_tags
}
