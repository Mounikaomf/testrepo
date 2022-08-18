resource "aws_ssm_parameter" "eftwebbank-sqs-accountid" {
  name = "/${var.account_code}/${var.env}/ingestion/sqs/omfcards/accountid"
  type = "String"
  value = "defaultuser"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
  tags = {
    Creator  = "omf eds devops team"
  }
}
