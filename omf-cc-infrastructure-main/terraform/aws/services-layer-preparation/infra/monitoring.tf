resource "aws_sns_topic" "failure-all-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEventsPublishMessages",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
    },
    {
      "Sid": "AllowLambdaPublishMessages",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
    },
    {
      "Sid": "AllowCloudwatchPublishMessages",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
    }
  ]
}
POLICY

  tags = merge(
    local.infra_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"
    )
  )
  
}