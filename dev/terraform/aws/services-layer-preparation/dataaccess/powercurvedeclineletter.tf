resource "aws_ssm_parameter" "declineletter-sftp-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/user"
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
resource "aws_ssm_parameter" "declineletter-sftp-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/password"
  type = "String"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "declineletter-sftp-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "declineletter-sftp-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/declineletter/port"
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
