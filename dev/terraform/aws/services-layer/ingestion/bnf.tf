locals {
  bnf_common_tags = {
    Application = "BNF"
    ApplicationSubject = "BNF"
  }
}

data "aws_ssm_parameter" "bnf-ingestion-private-key" {
  name = "/${var.account_code}/${var.env}/ingestion/decryption/bnf/private_key"
}

resource "aws_lambda_function" "bnf-sftp2s3" {
  function_name = "${var.account_code}-${var.env}-lambda-sftp2s3-bnf-${var.region_code}"
  role          = aws_iam_role.bnf-sftp2s3-lambda.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.sftp_download_files"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      SFTP_TARGET_HOSTNAME          = "/${var.account_code}/acc/dataaccess/sftp/acxiom/hostname"
      SFTP_TARGET_USER_SSM          = "/${var.account_code}/acc/dataaccess/sftp/acxiom/user"
      SFTP_TARGET_PASS_SSM          = "/${var.account_code}/acc/dataaccess/sftp/acxiom/pass"
      SFTP_TARGET_PORT              = "/${var.account_code}/acc/dataaccess/sftp/acxiom/port"
      SFTP_TARGET_DIRECTORY         = "outbound"
      S3_TARGET_BUCKET              = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
      S3_TARGET_PREFIX              = "raw/encryptedbnf"
      SFTP_LOG_TABLE                = "${var.account_code}-${var.env}-bnf-log-incoming-${var.region_code}"
      SFTP_FILENAME_PATTERN         = "."
    }
  }
  
  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sftp2s3-bnf-${var.region_code}"
    )
  )

}

resource "aws_cloudwatch_event_rule" "bnf-lambda-cron" {
  name                = "${var.account_code}-${var.env}-lambda-sftp2s3-bnf-cron-${var.region_code}"
  description         = "trigger for lambda sftp2s3 bnf"
  schedule_expression = "cron(0 6 30 2 ? *)"

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sftp2s3-bnf-cron-${var.region_code}"
    )
  )

}

resource "aws_cloudwatch_event_target" "bnf-lambda-cron-target" {
  arn  = aws_lambda_function.bnf-sftp2s3.arn
  rule = aws_cloudwatch_event_rule.bnf-lambda-cron.id
}

resource "aws_lambda_permission" "bnf-allowcloudwatchevent-fromsnowflake2s3" {
  statement_id  = "AllowCloudwatchEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bnf-sftp2s3.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bnf-lambda-cron.arn
}

resource "aws_cloudwatch_metric_alarm" "bnf-sftp2s3-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sftp2s3-bnf-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.bnf-sftp2s3.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.bnf-sftp2s3.function_name} lambda function"

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-sftp2s3-bnf-${var.region_code}"
    )
  )
}

resource "aws_lambda_function" "bnf-decryption" {
  function_name = "${var.account_code}-${var.env}-lambda-decryption-bnf-${var.region_code}"
  role          = aws_iam_role.bnf-decryption-lambda.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.gpg_decrypt_file_in_memory"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      TARGET_PREFIX         = "*"
      PRIVATE_KEY_SSM       = "/${var.account_code}/${var.env}/ingestion/decryption/bnf/private_key"
      SOURCE_FILTER_PREFIX  = "raw/encryptedbnf"
      TARGET_S3_BUCKET      = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
      TARGET_S3_PREFIX      = "raw/bnf"
    }
  }
  
  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-decryption-bnf-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue" "bnf-decryption-sqs" {
  name                      = "${var.account_code}-${var.env}-decryption-bnf-${var.region_code}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 180
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-decryption-bnf-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-decryption-bnf-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue_policy" "bnf-decryption-sqs-policy" {
  queue_url = aws_sqs_queue.bnf-decryption-sqs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.bnf-decryption-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "bnf-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-sns-decription-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.bnf-decryption-sqs.arn
}

resource "aws_lambda_event_source_mapping" "bnf-decryption-lambda-trigger" {
  event_source_arn = aws_sqs_queue.bnf-decryption-sqs.arn
  function_name    = aws_lambda_function.bnf-decryption.arn
  batch_size = 1
}

resource "aws_cloudwatch_metric_alarm" "bnf-decryption-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-decryption-bnf-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.bnf-decryption.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.bnf-decryption.function_name} lambda function"

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-decryption-bnf-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "bnf-sftp2s3-lambda" {
  name = "${var.account_code}-${var.env}-iamrole-bnf-sftp2s3-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-bnf-sftp2s3-lambda"
    )
  )
}

resource "aws_iam_role" "bnf-decryption-lambda" {
  name = "${var.account_code}-${var.env}-iamrole-bnf-decryption-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-bnf-decryption-lambda"
    )
  )

}

resource "aws_iam_policy" "bnf-sftp2s3-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-bnf-sftp2s3-lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",  "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"]
    },
    {
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": [
                "*"
            ]
        },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
            ],
      "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-bnf-sftp2s3-lambda"
    )
  )

}

resource "aws_iam_policy" "bnf-decryption-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-bnf-decryption-lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
        "Action": [
            "sqs:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",  "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
            ],
      "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-bnf-decryption-lambda"
    )
  )
}

resource "aws_iam_policy_attachment" "bnf-attachment-sftp2s3-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-sftp2s3-bnfattachmentlambda"
  policy_arn = aws_iam_policy.bnf-sftp2s3-lambda.arn
  roles = [aws_iam_role.bnf-sftp2s3-lambda.name]
}

resource "aws_iam_policy_attachment" "bnf-attachment-decryption-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-decryption-bnfattachmentlambda"
  policy_arn = aws_iam_policy.bnf-decryption-lambda.arn
  roles = [aws_iam_role.bnf-decryption-lambda.name]
}
