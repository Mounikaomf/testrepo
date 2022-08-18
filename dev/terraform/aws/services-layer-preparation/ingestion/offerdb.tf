resource "aws_ssm_parameter" "cards-s3-ingestion-offerdb" {
  name = "/${var.account_code}/${var.env}/ingestion/s3/productoffers/source_bucket"
  type = "String"
  value = "${var.account_code}-storage-${var.env}-omfeds-s3-raw-ue1-all-offerdb-all"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
