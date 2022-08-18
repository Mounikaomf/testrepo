locals {
  pccm_common_tags = {
    Application = "PCCM"
    ApplicationSubject = "PCCM"
  }
}

module "s3-dataexchange" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "pccm-integration"
  security_classification = "con"
  region = var.region_code
  tags_var = local.pccm_common_tags
}

resource "aws_sns_topic" "pccm-s32sns" {
  name = "${var.account_code}-${var.env}-pccm-s32sns-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pccm-s32sns-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-pccm-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.pccm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pccm-s32sns-${var.region_code}"
    )
  )

}

resource "aws_s3_bucket_notification" "pccm-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-pccm-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.pccm-s32sns.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
