data "aws_kms_key" "dataaccess-vgsfis-kmskey" {
  key_id = "alias/${var.env}"
}

resource "aws_ssm_parameter" "sftp-vgsfis-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/vgsfis/hostname"
  type = "String"
  value = "www.example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "sftp-vgsfis-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/vgsfis/user"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "sftp-vgsfis-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/vgsfis/pass"
  type = "SecureString"
  value = "default"
  key_id = "${data.aws_kms_key.dataaccess-vgsfis-kmskey.id}"
  overwrite = true
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-vgsfis-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/vgsfis/port"
  type = "String"
  value = "77"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
