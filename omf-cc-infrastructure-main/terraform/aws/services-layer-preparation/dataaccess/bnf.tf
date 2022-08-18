resource "aws_ssm_parameter" "bnf-sns-foreigner-account-id" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/foreigner/accountid"
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
