resource "aws_ssm_parameter" "graduation-maintenance-destination-path" {
  name = "/${var.account_code}/acc/exchange/gradmaint/destination"
  type = "String"
  value = "/example"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}