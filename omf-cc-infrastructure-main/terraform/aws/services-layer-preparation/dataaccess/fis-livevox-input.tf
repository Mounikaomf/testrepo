resource "aws_ssm_parameter" "livevoxinput-sftp-user" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/user"
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
resource "aws_ssm_parameter" "livevoxinput-sftp-pass" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/password"
  type = "SecureString"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "livevoxinput-sftp-hostname" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "livevoxinput-sftp-port" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/port"
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

resource "aws_ssm_parameter" "graduation-maintenance-destination-path" {
  name = "/${var.account_code}/${var.env}/dataaccess/sftp/livevoxinput/destination"
  type = "String"
  value = "example/example"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
