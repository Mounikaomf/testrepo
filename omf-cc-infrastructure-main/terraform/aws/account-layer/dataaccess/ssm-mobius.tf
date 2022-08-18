data "aws_kms_key" "dataaccess-mobius-kmskey" {
  key_id = "alias/${var.env}"
}

resource "aws_ssm_parameter" "sftp-mobius-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/mobius/hostname"
  type = "String"
  value = "www.example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "sftp-mobius-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/mobius/user"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
resource "aws_ssm_parameter" "sftp-mobius-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/mobius/pass"
  type = "SecureString"
  value = "default"
  key_id = "${data.aws_kms_key.dataaccess-mobius-kmskey.id}"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sftp-mobius-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/mobius/port"
  type = "String"
  value = "77"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
