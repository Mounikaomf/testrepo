locals {
  pnm_common_tags = {
    Application = "PNM"
    ApplicationSubject = "PNM"
  }
}

data "aws_ssm_parameter" "pnm-sqs-accountid" {
  name = "/${var.account_code}/acc/dataexchange/pnm/omfcards/accountid"
}

module "s3-pnm" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "pnm"
  security_classification = "con"
  region = var.region_code
  tags_var = local.pnm_common_tags
}

resource "aws_sns_topic" "pnm-dataload" {
  name = "${var.account_code}-${var.env}-pnm-dataload-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-dataload-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-dataload-${var.region_code}"
    )
  )
  
}

resource "aws_sns_topic" "pnm-exchange" {
  name = "${var.account_code}-${var.env}-pnm-exchange-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-exchange-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-exchange-${var.region_code}"
    )
  )
  
}

resource "aws_sns_topic" "pnm-sns2cardssqs" {
  name = "${var.account_code}-${var.env}-pnm-sns2cardssqs-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSNSfromS3",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-sns2cardssqs-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
        }
      }
    },
    {
      "Sid": "AllowexternalSQSsubscribeToSNS",
      "Effect":"Allow",
      "Principal":{
        "AWS":"${data.aws_ssm_parameter.pnm-sqs-accountid.value}"
      },
      "Action":"sns:Subscribe",
      "Resource":"arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-sns2cardssqs-${var.region_code}"
    }
  ]
}
POLICY

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-sns2cardssqs-${var.region_code}"
    )
  )
  
}

resource "aws_sns_topic" "pnm-failure" {
  name = "${var.account_code}-${var.env}-pnm-failure-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-pnm-failure-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-pnm-failure-${var.region_code}"
    )
  )
  
}

resource "aws_ssm_parameter" "pnm-dataload-sns-topic" {
  name = "/${var.account_code}/${var.env}/dataload/sns/pnm/topicarn"
  type = "String"
  value = aws_sns_topic.pnm-dataload.arn
}

resource "aws_ssm_parameter" "pnm-exhcange-sns-topic" {
  name = "/${var.account_code}/${var.env}/exchange/sns/pnm/topicarn"
  type = "String"
  value = aws_sns_topic.pnm-exchange.arn
}

resource "aws_ssm_parameter" "pnm-sns2cardssqs-sns-topic" {
  name = "/${var.account_code}/${var.env}/dataload/sns2cardssqs/pnm/topicarn"
  type = "String"
  value = aws_sns_topic.pnm-sns2cardssqs.arn
}

resource "aws_s3_bucket_notification" "pnm-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.pnm-dataload.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/"
  }

  topic {
    topic_arn     = aws_sns_topic.pnm-exchange.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "processed/success/paymentsreport/"
  }
  topic {
    topic_arn     = aws_sns_topic.pnm-exchange.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "processed/success/returnsreport/"
  }
  topic {
    topic_arn     = aws_sns_topic.pnm-failure.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "processed/failed/returnsreport/"
  }
  topic {
    topic_arn     = aws_sns_topic.pnm-failure.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "processed/failed/paymentsreport/"
  }
}
