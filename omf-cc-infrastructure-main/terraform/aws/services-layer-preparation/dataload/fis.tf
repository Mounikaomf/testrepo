locals {
  fis_common_tags = {
    Application = "FIS"
  }
}

module "s3-fis" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "fis"
  security_classification = "con"
  region = var.region_code
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS"
    )
  )
}

resource "aws_sns_topic" "fis-accmaint" {
  name = "${var.account_code}-${var.env}-fis-accmaint-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-accmaint-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-accmaint-${var.region_code}",
      "ApplicationSubject", "FIS-AccMaint"
    )
  )

}

resource "aws_sns_topic" "fis-ereports" {
  name = "${var.account_code}-${var.env}-fis-ereports-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-ereports-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-ereports-${var.region_code}",
      "ApplicationSubject", "FIS-eReports"
    )
  )

}

resource "aws_sns_topic" "fis-boshreports" {
  name = "${var.account_code}-${var.env}-fis-boshreports-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-boshreports-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-boshreports-${var.region_code}",
      "ApplicationSubject", "FIS-BOSHReports"
    )
  )

}

resource "aws_sns_topic" "fis-gu010d" {
  name = "${var.account_code}-${var.env}-fis-gu010d-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-gu010d-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-gu010d-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_sns_topic" "fis-gu011d" {
  name = "${var.account_code}-${var.env}-fis-gu011d-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-gu011d-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-gu011d-${var.region_code}",
      "ApplicationSubject", "FIS-NameAddress"
    )
  )

}

resource "aws_sns_topic" "fis-analytixreports" {
  name = "${var.account_code}-${var.env}-fis-analytixreports-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-analytixreports-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-analytixreports-${var.region_code}",
      "ApplicationSubject", "FIS-AnalytixReports"
    )
  )

}

resource "aws_sns_topic" "fis-GU045" {
  name = "${var.account_code}-${var.env}-fis-GU045-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-GU045-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-GU045-${var.region_code}",
      "ApplicationSubject", "FIS-GeneralLedger"
    )
  )

}

resource "aws_sns_topic" "fis-WebBank" {
  name = "${var.account_code}-${var.env}-fis-WebBank-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-WebBank-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-WebBank-${var.region_code}",
      "ApplicationSubject", "FIS-WebBank"
    )
  )

}

resource "aws_sns_topic" "fis-sfexchange" {
  name = "${var.account_code}-${var.env}-fis-sfexchange-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-sfexchange-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-sfexchange-${var.region_code}",
      "ApplicationSubject", "FIS"
    )
  )
}

resource "aws_sns_topic" "fis-marketinganalytics" {
  name = "${var.account_code}-${var.env}-fis-marketinganalytics-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-marketinganalytics-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-marketinganalytics-${var.region_code}",
      "ApplicationSubject", "FIS"
    )
  )
}

resource "aws_ssm_parameter" "fis-marketinganalytics-sns-name" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/fis-marketinganalytics/name"
  type = "String"
  value = aws_sns_topic.fis-marketinganalytics.name
}

//resource "aws_sns_topic" "fis-stepfunction" {
//  name = "${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//
//  policy = <<POLICY
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Effect": "Allow",
//      "Principal": {
//        "Service": "s3.amazonaws.com"
//      },
//      "Action": "SNS:Publish",
//      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}",
//      "Condition": {
//        "ArnLike": {
//          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
//        }
//      }
//    }
//  ]
//}
//POLICY
//}

resource "aws_s3_bucket_notification" "s3sns2s3-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"

  topic {
    topic_arn     = aws_sns_topic.fis-accmaint.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/Account+Maintenance+batch+file/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-ereports.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/eReports/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-boshreports.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/BOSH+reports/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-gu010d.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/cardholder_master/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-gu011d.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/nameaddress/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-analytixreports.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/Analytix+Reports/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-GU045.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/generalledger/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-WebBank.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/WebBank+settlement+file/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-marketinganalytics.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/FOS+statement+index+file/"
  }
  topic {
    topic_arn     = aws_sns_topic.fis-sfexchange.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "prepared/"
  }
//  topic {
//    topic_arn     = aws_sns_topic.fis-stepfunction.arn
//    events        = ["s3:ObjectCreated:*"]
//    filter_prefix = "raw_glue/"
//  }
}

resource "aws_dynamodb_table" "fis-paymentallocation-table" {
  name           = "${var.account_code}-${var.env}-fis-paymentallocation-${var.region_code}"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-paymentallocation-${var.region_code}",
      "ApplicationSubject", "FIS-PaymentAllocation"
    )
  )

}

resource "aws_dynamodb_table" "fis-cardholder_master-table" {
  name           = "${var.account_code}-${var.env}-fis-cardholder_master-${var.region_code}"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-cardholder_master-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_dynamodb_table" "fis-cardholder_plan-table" {
  name           = "${var.account_code}-${var.env}-fis-cardholder_plan-${var.region_code}"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-cardholder_plan-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderPlan"
    )
  )

}

resource "aws_dynamodb_table" "fis-nameaddress-table" {
  name           = "${var.account_code}-${var.env}-fis-nameaddress-${var.region_code}"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-nameaddress-${var.region_code}",
      "ApplicationSubject", "FIS-NameAddress"
    )
  )

}

resource "aws_dynamodb_table" "fis-posteditems-table" {
  name           = "${var.account_code}-${var.env}-fis-posteditems-${var.region_code}"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-posteditems-${var.region_code}",
      "ApplicationSubject", "FIS-PostedItems"
    )
  )

}
