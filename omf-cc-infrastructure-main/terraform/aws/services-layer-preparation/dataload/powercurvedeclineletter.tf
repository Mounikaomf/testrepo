module "s3-declineletter" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "declineletter"
  security_classification = "con"
  region = var.region_code
  tags_var = local.productoffer_common_tags
}

resource "aws_sns_topic" "declineletter-powercurve" {
  name = "${var.account_code}-${var.env}-declineletter-powercurve-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-declineletter-powercurve-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-declineletter-powercurve-${var.region_code}"
    )
  )

}

resource "aws_ssm_parameter" "declineletter-powercurve-sns-name" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/declineletter/powercurve/name"
  type = "String"
  value = aws_sns_topic.declineletter-powercurve.name
}

resource "aws_s3_bucket_notification" "declineletter-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.declineletter-powercurve.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "prepared/"
  }

  depends_on = [
    aws_sns_topic.declineletter-powercurve
  ]
}