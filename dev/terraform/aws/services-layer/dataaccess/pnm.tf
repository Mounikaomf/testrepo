locals {
  pnm_common_tags = {
    Application = "PNM"
    ApplicationSubject = "PNM"
  }
}

data "aws_ssm_parameter" "pnm-exchange-sns-topic" {
  name = "/${var.account_code}/${var.env}/exchange/sns/pnm/topicarn"
}

module "pnm-dataload-sqs2s3" {
  source               = "../../modules/sqs2s3"
  account_code = var.account_code
  append_date = ""
  append_datetime = ""
  config_file = ""
  destination_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  destination_prefix = "PNM/TO-BE-PROCESSED"
  env = var.env
  name = "pnm-dataload"
  region_code = var.region_code
  snstopic_arn = "${data.aws_ssm_parameter.pnm-exchange-sns-topic.value}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
  source_prefix_filter = "/processed/success"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = local.pnm_common_tags
}