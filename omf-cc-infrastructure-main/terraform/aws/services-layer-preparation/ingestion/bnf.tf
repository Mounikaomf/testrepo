locals {
  bnf_common_tags = {
    Application = "BNF"
    ApplicationSubject = "BNF"
  }
}

resource "aws_ssm_parameter" "bnf-decryption-public_key" {
  name = "/${var.account_code}/${var.env}/ingestion/decryption/bnf/public_key"
  type = "String"
  value = "default"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "bnf-decryption-private_key" {
  name = "/${var.account_code}/${var.env}/ingestion/decryption/bnf/private_key"
  type = "String"
  value = "default"
  tier = "Advanced"
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_dynamodb_table" "bnf-log-incoming-table" {
  name           = "${var.account_code}-${var.env}-bnf-log-incoming-${var.region_code}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key       = "file_name"
  range_key = "processed_datetime"

  attribute {
    name = "file_name"
    type = "S"
  }
  attribute {
    name = "processed_datetime"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-bnf-log-incoming-${var.region_code}"
    )
  )

}
