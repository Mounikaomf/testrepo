locals {
  customerview_common_tags = {
    Application = "CustomerView"
    ApplicationSubject = "CustomerView"
  }
}

module "customerview-s3sns2s3" {
  source               = "../../modules/s3sns2s3"
  name                 = "customerview-ingestion"
  config_file          = ""
  destination_bucket   = "${var.account_code}-${var.env}-s3-cc-customerview-con-${var.region_code}"
  source_bucket        = "${var.account_code}-storage-${var.env}-omfeds-s3-raw-${var.region_code}-all-cards-appsvc-all"
  account_code         = var.account_code
  env                  = var.env
  region_code          = var.region_code
  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date          = ""
  append_datetime      = false
  destination_prefix   = "raw"
  source_prefix_filter = "/export"
  notification_filter_prefix = "export/"
  notification_filter_suffix = ""
  tags_var = local.customerview_common_tags
}
