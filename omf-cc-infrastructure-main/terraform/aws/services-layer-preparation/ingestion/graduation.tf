resource "aws_ssm_parameter" "graduation-sns-topic-arn" {
  name = "/${var.account_code}/${var.env}/ingestion/sns/graduation/arn"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}