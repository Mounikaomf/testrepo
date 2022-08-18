resource "aws_ssm_parameter" "sftp-fisvgs-public_key" {
  name = "/${var.account_code}/${var.env}/ingestion/sftp/fisvgs/public_key"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
