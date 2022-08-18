resource "aws_ssm_parameter" "fisoffload-sftp-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/fisoffload/user"
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
resource "aws_ssm_parameter" "fisoffload-sftp-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/fisoffload/password"
  type = "String"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "fisoffload-sftp-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/fisoffload/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "fisoffload-sftp-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/fisoffload/port"
  type = "String"
  value = "22"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
  tags = {
    creator = "omf eds dev"
  }
}
