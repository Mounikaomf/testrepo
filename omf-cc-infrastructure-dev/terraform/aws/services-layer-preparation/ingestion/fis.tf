resource "aws_ssm_parameter" "marketinganalytics-destination-bucket" {
  name = "/${var.account_code}/${var.env}/dataaccess/s3/marketinganalytics/destinationbucket"
  type = "String"
  value = "oma-s3-${var.env}-eds-data-exchange-bucket-${var.region_code}-all"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
