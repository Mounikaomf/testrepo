resource "aws_ssm_parameter" "luminate-client-id" {
  name = "/${var.account_code}/${var.env}/dataaccess/api/luminate/clientid"
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

resource "aws_ssm_parameter" "luminate-client-secret" {
  name = "/${var.account_code}/${var.env}/dataaccess/api/luminate/clientsecret"
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

resource "aws_ssm_parameter" "luminate-auth-endpoint" {
  name = "/${var.account_code}/${var.env}/dataaccess/auth/luminate/endpoint"
  type = "String"
  value = "default"
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

resource "aws_ssm_parameter" "luminate-api-endpoint" {
  name = "/${var.account_code}/${var.env}/dataaccess/api/luminate/endpoint"
  type = "String"
  value = "default"
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
