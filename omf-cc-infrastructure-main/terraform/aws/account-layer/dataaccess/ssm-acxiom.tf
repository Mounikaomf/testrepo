data "aws_kms_key" "dataaccess-acxiom-kmskey" {
  key_id = "alias/${var.env}"
}

resource "aws_ssm_parameter" "sftp-acxiom_directmail-public_key" {
  name = "/${var.account_code}/${var.env}/sftp-datatarget/acxiom_directmail/public_key"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-acxiom-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/acxiom/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-acxiom-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/acxiom/user"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-acxiom-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/acxiom/pass"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-acxiom-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/acxiom/port"
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
