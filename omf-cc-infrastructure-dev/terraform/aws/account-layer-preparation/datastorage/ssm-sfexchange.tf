resource "aws_ssm_parameter" "sfexchange-user_arn" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/user_arn"
  type = "String"
  value = "arn:aws:iam::99999999999:user/default-user-example"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-externalid" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/external_id"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-user" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/user"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-password" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/password"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-account_id" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/accound_id"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-warehouse" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/warehouse"
  type = "String"
  value = "defaultwarehouse"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "sfexchange-role" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/role"
  type = "String"
  value = "defaultrole"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
