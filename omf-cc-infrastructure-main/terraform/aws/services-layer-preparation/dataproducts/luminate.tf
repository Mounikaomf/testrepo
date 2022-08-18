locals {
  luminate_common_tags = {
    Application = "Luminate"
    ApplicationSubject = "Luminate"
  }
}

module "s3-luminate" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "luminate"
  security_classification = "con"
  region = var.region_code
  tags_var = local.luminate_common_tags
}

resource "aws_sns_topic" "luminate-s32sns" {
  name = "${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"
    )
  )

}

resource "aws_s3_bucket_notification" "s3sns-luminate-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.luminate-s32sns.arn
    events        = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_sns_topic.luminate-s32sns
  ]
}
