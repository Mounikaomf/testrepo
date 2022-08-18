locals {
  sfexchange_common_tags = {
    Application = "SnowFlakeExchange"
    ApplicationSubject = "SnowFlakeExchange"
  }
}

data "aws_ssm_parameter" "sfexchange-snowflake-user_arn" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/user_arn"

}

data "aws_ssm_parameter" "sfexchange-snowflake-external_id" {
  name = "/${var.account_code}/${var.env}/datastorage/snowflake/external_id"
}

module "sfexchange-s3-sfexchange" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "sfexchange"
  security_classification = "con"
  region = var.region_code
  tags_var = local.sfexchange_common_tags
}

resource "aws_sns_topic" "sfexchange-webbankreport4" {
  name = "${var.account_code}-${var.env}-sfexchange-webbankreport4-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-webbankreport4-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-webbankreport4-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-314a" {
  name = "${var.account_code}-${var.env}-sfexchange-314a-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-314a-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-314a-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-livevoxinput" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-livevoxinput-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-livevoxinput-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-livevoxinput-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-webbankreport2" {
  name = "${var.account_code}-${var.env}-sfexchange-webbankreport2-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-webbankreport2-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-webbankreport2-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-webbankreport1" {
  name = "${var.account_code}-${var.env}-sfexchange-webbankreport1-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-webbankreport1-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-webbankreport1-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-sanctions" {
  name = "${var.account_code}-${var.env}-sfexchange-sanctions-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-sanctions-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-sanctions-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-acxiom-dataaccess" {
  name = "${var.account_code}-${var.env}-sfexchange-acxiom-dataaccess-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-acxiom-dataaccess-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-acxiom-dataaccess-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-encrypt-acxiom" {
  name = "${var.account_code}-${var.env}-sfexchange-encrypt-acxiom-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-encrypt-acxiom-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-encrypt-acxiom-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-314a-fis" {
  name = "${var.account_code}-${var.env}-sfexchange-314a-fis-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-314a-fis-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-314a-fis-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-equifax" {
  name = "${var.account_code}-${var.env}-sfexchange-equifax-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-equifax-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-equifax-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-graduationapr" {
  name = "${var.account_code}-${var.env}-sfexchange-graduationapr-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-graduationapr-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-graduationapr-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-colldialeroutput" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-colldialeroutput-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-colldialeroutput-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-colldialeroutput-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-nameaddress" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-nameaddress-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-nameaddress-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-nameaddress-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-posteditems" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-posteditems-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-posteditems-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-posteditems-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-cardholdermaster" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-cardholdermaster-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-cardholdermaster-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-cardholdermaster-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-cardholderplan" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-cardholderplan-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-cardholderplan-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-cardholderplan-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-fis-paymentallocation" {
  name = "${var.account_code}-${var.env}-sfexchange-fis-paymentallocation-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-fis-paymentallocation-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-fis-paymentallocation-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-declineletter" {
  name = "${var.account_code}-${var.env}-sfexchange-declineletter-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-declineletter-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-declineletter-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-telephony-callbycall" {
  name = "${var.account_code}-${var.env}-sfexchange-telephony-callbycall-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-telephony-callbycall-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-telephony-callbycall-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-telephony-calldisposition" {
  name = "${var.account_code}-${var.env}-sfexchange-telephony-calldisposition-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-telephony-calldisposition-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-telephony-calldisposition-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-telephony-ivrdetails" {
  name = "${var.account_code}-${var.env}-sfexchange-telephony-ivrdetails-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-telephony-ivrdetails-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-telephony-ivrdetails-${var.region_code}"
    )
  )

}

resource "aws_sns_topic" "sfexchange-telephony-skilllevel" {
  name = "${var.account_code}-${var.env}-sfexchange-telephony-skilllevel-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-sfexchange-telephony-skilllevel-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sfexchange-telephony-skilllevel-${var.region_code}"
    )
  )

}

resource "aws_s3_bucket_notification" "sfexchange-notification" {
  bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  eventbridge = true

  topic {
    topic_arn     = aws_sns_topic.sfexchange-webbankreport4.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "webbank_report_4/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-314a.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "report314a/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-livevoxinput.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "livevox_input/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-webbankreport2.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "webbank_report_2/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-webbankreport1.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "webbank_report_1/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-sanctions.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "report_sanctions/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-acxiom-dataaccess.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "acxiom_directmail_encrypted/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-encrypt-acxiom.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "acxiom_directmail/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-314a-fis.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "314a-fis/out/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-equifax.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "equifax/in/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-graduationapr.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "graduation/in/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-colldialeroutput.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/COLLDIALEROUTPUT/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-nameaddress.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/NAME_ADDRESS/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-posteditems.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/POSTED_ITEMS/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-cardholdermaster.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/CARDHOLDER_MASTER/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-cardholderplan.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/CARDHOLDER_PLAN/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-fis-paymentallocation.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/PAYMENT_ALLOCATION/TO-BE-PROCESSED/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-declineletter.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "declineletter/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-telephony-callbycall.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/Telephony/IVR_FILETYPE%3DCallByCall/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-telephony-calldisposition.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/Telephony/IVR_FILETYPE%3DCallDisposition/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-telephony-ivrdetails.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/Telephony/IVR_FILETYPE%3DIVRDetails/"
  }
  topic {
    topic_arn     = aws_sns_topic.sfexchange-telephony-skilllevel.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "FIS/Telephony/IVR_FILETYPE%3DSkillLevel/"
  }
}

resource "aws_iam_role" "sfexchange-snowflake-role" {
  name = "${var.account_code}-${var.env}-iamrole-sfexchange-snowflake"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "${data.aws_ssm_parameter.sfexchange-snowflake-user_arn.value}"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "${data.aws_ssm_parameter.sfexchange-snowflake-external_id.value}"
          }
        }
      }
    ]
  }
EOF

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sfexchange-snowflake"
    )
  )

}

resource "aws_iam_policy" "sfexchange-snowflake-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-sfexchange-snowflake"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:DeleteObject",
              "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-sfexchange-con-${var.region_code}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListStorageLensConfigurations",
                "s3:ListJobs",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListBucket",
                "s3:ListMultipartUploadParts"
                ],
            "Resource": "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-sfexchange-con-${var.region_code}"
        }
    ]
}
EOF

  tags = merge(
    local.sfexchange_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-sfexchange-snowflake"
    )
  )

}

resource "aws_iam_policy_attachment" "sfexchange-snowflake-policy-attach" {
  name = "${var.account_code}-${var.env}-policyattach-sfexchange-snowflake"
  roles      = [aws_iam_role.sfexchange-snowflake-role.name]
  policy_arn = "${aws_iam_policy.sfexchange-snowflake-policy.arn}"
}
