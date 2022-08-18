resource "aws_ssm_parameter" "vgs-exchange-hostname" {
  name = "/${var.account_code}/acc/exchange/vgs/hostname"
  type = "String"
  value = "example.com"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "vgs-exchange-port" {
  name = "/${var.account_code}/acc/exchange/vgs/port"
  type = "String"
  value = "77"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "vgs-exchange-user" {
  name = "/${var.account_code}/acc/exchange/vgs/user"
  type = "String"
  value = "defaultuser"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "vgs-exchange-password" {
  name = "/${var.account_code}/acc/exchange/vgs/password"
  type = "String"
  value = "defaultpassword"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}