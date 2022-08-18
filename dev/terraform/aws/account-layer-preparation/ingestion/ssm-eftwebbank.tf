resource "aws_ssm_parameter" "eftwebbank-sftp-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/eftwebbank/user"
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

resource "aws_ssm_parameter" "eftwebbank-sftp-password" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/eftwebbank/password"
  type = "String"
  value = "defaulpass"
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

resource "aws_ssm_parameter" "eftwebbank-sftp-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/eftwebbank/hostname"
  type = "String"
  value = "defaulhostname"
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

resource "aws_ssm_parameter" "eftwebbank-sftp-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/eftwebbank/port"
  type = "String"
  value = "65"
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
