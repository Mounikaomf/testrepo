resource "aws_ssm_parameter" "cards-s3-ingestion-cards-appsvc" {
  name = "/${var.account_code}/${var.env}/ingestion/s3/customerview/source_bucket"
  type = "String"
  value = "${var.account_code}-storage-${var.env}-omfeds-s3-raw-ue1-all-cards-appsvc-all"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
