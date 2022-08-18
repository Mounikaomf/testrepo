locals {
  pnm_common_tags = {
    Application = "PNM"
    ApplicationSubject = "PNM"
  }
}

module "s3-pnm-ingestion" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "sftppnm-ingestion"
  security_classification = "con"
  region = var.region_code
  tags_var = local.pnm_common_tags
}

resource "aws_iam_user" "pnm-user" {
  name = "${var.account_code}-${var.env}-pnm-sftp-user"
  path = "/"

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-sftp-user"
    )
  )

}

resource "aws_iam_access_key" "pnm-user-key" {
  user = aws_iam_user.pnm-user.name
}

resource "aws_iam_user_policy" "pnm-user-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-pnm-sftp-user"
  user = aws_iam_user.pnm-user.name

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
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-sftppnm-ingestion-con-${var.region_code}",
        "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-sftppnm-ingestion-con-${var.region_code}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_ssm_parameter" "pnm-user-access-id" {
  name = "/${var.account_code}/${var.env}/ingestion/pnm/user/access-id"
  type = "String"
  value = aws_iam_access_key.pnm-user-key.id
}

resource "aws_ssm_parameter" "pnm-user-secret" {
  name = "/${var.account_code}/${var.env}/ingestion/pnm/user/secret"
  type = "SecureString"
  value = aws_iam_access_key.pnm-user-key.secret
}

resource "aws_sns_topic" "pnm-ingestion" {
  name = "${var.account_code}-${var.env}-pnm-ingestion-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-ingestion-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-sftppnm-ingestion-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-ingestion-${var.region_code}"
    )
  )
  
}

resource "aws_ssm_parameter" "pnm-ingestion-sns-topic" {
  name = "/${var.account_code}/${var.env}/ingestion/sns/pnm/topicarn"
  type = "String"
  value = aws_sns_topic.pnm-ingestion.arn
}

resource "aws_s3_bucket_notification" "pnm-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-sftppnm-ingestion-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.pnm-ingestion.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "incoming/"
  }
}