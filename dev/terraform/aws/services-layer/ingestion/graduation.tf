locals {
  graduation_apr_common_tags = {
    Application = "Graduation"
    ApplicationSubject = "GraduationAprCli"
  }
}

data "aws_ssm_parameter" "graduation-sns-topic-arn" {
  name = "/${var.account_code}/${var.env}/ingestion/sns/graduation/arn"
}

#external sns to s3
module "graduation-ingestion-sqs2s3" {
  source                = "../../modules/sqs2s3external"
  account_code          = var.account_code
  append_date           = ""
  append_datetime       = ""
  env                   = var.env
  name                  = "graduation-ingestion"
  region_code           = var.region_code
  #snstopic_arn          = "arn:aws:sns:us-east-1:560030824191:test-graduation-ag"
  snstopic_arn          = data.aws_ssm_parameter.graduation-sns-topic-arn.value
  target_bucket         = "${var.account_code}-${var.env}-s3-cc-graduation-ingestion-con-${var.region_code}"
  target_prefix         = "raw"
  file_name             = "part-graduation"
  max_queue_messages    = "10"
  version_lambda        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var              = local.graduation_apr_common_tags
}