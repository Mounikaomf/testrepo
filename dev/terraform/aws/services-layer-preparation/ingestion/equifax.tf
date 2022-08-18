locals {
  equifax_common_tags = {
    Application = "Equifax"
    ApplicationSubject = "Equifax"
  }
}

module "s3-equifax" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "equifax-ingestion"
  security_classification = "con"
  region = var.region_code
  tags_var = local.equifax_common_tags
}

resource "aws_iam_user" "equifax-user" {
  name = "${var.account_code}-${var.env}-equifax-sftp-user"
  path = "/"

  tags = merge(
    local.equifax_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-equifax-sftp-user"
    )
  )

}

resource "aws_iam_access_key" "equifax-user-key" {
  user = aws_iam_user.equifax-user.name
}

resource "aws_iam_user_policy" "equifax-user-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-equifax-sftp-user"
  user = aws_iam_user.equifax-user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}",
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_ssm_parameter" "equifax-user-access-id" {
  name = "/${var.account_code}/${var.env}/ingestion/equifax/user/access-id"
  type = "String"
  value = aws_iam_access_key.equifax-user-key.id
}

resource "aws_ssm_parameter" "equifax-user-secret" {
  name = "/${var.account_code}/${var.env}/ingestion/equifax/user/secret"
  type = "SecureString"
  value = aws_iam_access_key.equifax-user-key.secret
}

# resource "aws_s3_access_point" "s3-equifax-access-point" {
#   bucket = "${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}"
#   name   = "${var.account_code}-${var.env}-accesspoint-equifax-${var.region_code}"
# }
