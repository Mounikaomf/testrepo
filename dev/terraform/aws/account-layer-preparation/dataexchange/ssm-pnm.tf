resource "aws_ssm_parameter" "pnm-sqs-accountid" {
  name = "/${var.account_code}/${var.env}/dataexchange/pnm/omfcards/accountid"
  type = "String"
  value = "123456789123"
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