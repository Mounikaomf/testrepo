resource "aws_ssm_parameter" "sftp-fisoffload-hostname" {
  name = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-fisoffload-port" {
  name = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  type = "String"
  value = "77"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-fisoffload-user" {
  name = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  type = "String"
  value = "defaultuser"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-fisoffload-password" {
  name = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  type = "String"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
