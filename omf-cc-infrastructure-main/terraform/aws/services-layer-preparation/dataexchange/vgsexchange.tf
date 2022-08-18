locals {
  vgsexchange_common_tags = {
    Application = "VGSExchange"
    ApplicationSubject = "VGSExchange"
  }
}

module "s3-vgs-exchange" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "vgsexchange"
  security_classification = "con"
  region = var.region_code
  tags_var = local.vgsexchange_common_tags
}

resource "aws_iam_user" "vgs-exchange-user" {
  name = "${var.account_code}-${var.env}-vgsexchange-sftp-user"
  path = "/"

  tags = merge(
    local.vgsexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-vgsexchange-sftp-user"
    )
  )

}

resource "aws_iam_access_key" "vgs-exchange-user-key" {
  user = aws_iam_user.vgs-exchange-user.name
}

resource "aws_iam_user_policy" "vgs-exchange-user-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-vgsexchange-sftp-user"
  user = aws_iam_user.vgs-exchange-user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-vgsexchange-con-${var.region_code}",
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-vgsexchange-con-${var.region_code}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_ssm_parameter" "vgs-exchange-user-access-id" {
  name = "/${var.account_code}/${var.env}/exchange/vgs/user/access-id"
  type = "String"
  value = aws_iam_access_key.vgs-exchange-user-key.id
}

resource "aws_ssm_parameter" "vgs-exchange-user-secret" {
  name = "/${var.account_code}/${var.env}/exchange/vgs/user/secret"
  type = "SecureString"
  value = aws_iam_access_key.vgs-exchange-user-key.secret
}

resource "aws_sns_topic" "graduation-maintenance" {
  name = "${var.account_code}-${var.env}-graduation-maintenance-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-graduation-maintenance-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-vgsexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.vgsexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-graduation-maintenance-${var.region_code}"
    )
  )
  
}

resource "aws_s3_bucket_notification" "s3sns2batch-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-vgsexchange-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.graduation-maintenance.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "graduationmaintenance/inout/"
  }
}
