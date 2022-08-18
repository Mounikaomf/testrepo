locals {
  telephony_common_tags = {
    Application = "Telephony"
    "ApplicationSubject" = "Telephony"
  }
}

module "s3-telephony" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "telephony"
  security_classification = "con"
  region = var.region_code
  tags_var = local.telephony_common_tags
}

resource "aws_sns_topic" "telephony-s32sns" {
  name = "${var.account_code}-${var.env}-telephony-s32sns-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-telephony-s32sns-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-telephony-s32sns-${var.region_code}"
    )
  )

}

resource "aws_s3_bucket_notification" "s3sns2s3-telephony-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.telephony-s32sns.arn
    events        = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_sns_topic.telephony-s32sns
  ]
}