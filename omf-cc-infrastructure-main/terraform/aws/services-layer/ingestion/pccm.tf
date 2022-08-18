//module "pccm-sftp2s3" {
//  source               = "../../modules/s3sns2s3"
//  name                 = "pccm-ingestion"
//  config_file          = ""
//  destination_bucket   = "${var.account_code}-${var.env}-s3-cc-pccm-con-${var.region_code}"
//  source_bucket        = "${var.account_code}-${var.env}-s3-cc-pccm-con-${var.region_code}"
//  account_code         = var.account_code
//  env                  = var.env
//  region_code          = var.region_code
//  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
//  append_date          = ""
//  append_datetime      = false
//  destination_prefix   = ""
//  source_prefix_filter = ""
//  notification_filter_prefix = ""
//  notification_filter_suffix = ""
//}
