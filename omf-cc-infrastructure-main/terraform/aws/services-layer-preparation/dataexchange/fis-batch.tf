resource "aws_ssm_parameter" "jfrog-sqs2sftp-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/jfrog/username"
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

#pass
resource "aws_ssm_parameter" "jfrog-sqs2sftp-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/jfrog/password"
  type = "String"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}