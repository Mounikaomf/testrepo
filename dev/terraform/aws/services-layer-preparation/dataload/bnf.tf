locals {
  bnf_common_tags = {
    Application = "BNF"
    ApplicationSubject = "BNF"
  }
}

module "s3-bnf" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "bnf"
  security_classification = "con"
  region = var.region_code
  tags_var = local.bnf_common_tags
}

resource "aws_sns_topic" "bnf-sns-decryption" {
  name = "${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "bnf-sns-dataload" {
  name = "${var.account_code}-${var.env}-bnf-sns-dataload-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-bnf-sns-dataload-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-bnf-sns-dataload-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "bnf-s3sns2glue" {
  name = "${var.account_code}-${var.env}-bnf-s3sns2glue-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-bnf-s3sns2glue-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-bnf-s3sns2glue-${var.region_code}"
    )
  )

}

resource "aws_s3_bucket_notification" "s3sns2s3-bnf-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.bnf-sns-decryption.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/encryptedbnf/"
  }
  topic {
    topic_arn     = aws_sns_topic.bnf-sns-dataload.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "prepared/"
  }
  topic {
    topic_arn     = aws_sns_topic.bnf-s3sns2glue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/bnf/"
  }
  depends_on = [
    aws_sns_topic.bnf-sns-decryption,
    aws_sns_topic.bnf-sns-dataload,
    aws_sns_topic.bnf-s3sns2glue
  ]
}

resource "aws_dynamodb_table" "bnf-table" {
  name           = "${var.account_code}-${var.env}-bnf-${var.region_code}"
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
      "ApplicationComponent", "${var.account_code}-${var.env}-bnf-${var.region_code}"
    )
  )

}
