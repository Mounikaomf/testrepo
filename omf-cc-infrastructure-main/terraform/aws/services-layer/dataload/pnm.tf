locals {
  pnm_common_tags = {
    Application = "PNM"
    ApplicationSubject = "PNM"
  }
}

data "aws_ssm_parameter" "pnm-sns-topic" {
  name = "/${var.account_code}/${var.env}/dataload/sns/pnm/topicarn"
}

data "aws_ssm_parameter" "pnm-sns2cardssqs-topic" {
  name = "/${var.account_code}/${var.env}/dataload/sns2cardssqs/pnm/topicarn"
}

#TODO Change parameters and handler
resource "aws_lambda_function" "s3sns2s3-pnm" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2s3-pnm-dataload-${var.region_code}"
  role          = aws_iam_role.s3sns2s3-pnm-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.sns_s3_pnm"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      DESTINATION_BUCKET    = "${var.account_code}-${var.env}-s3-cc-pnm-con-${var.region_code}"
      aws_region            = "${var.region_code}"
      SOURCE_PREFIX_FILTER  = "raw"
      DESTINATION_PREFIX    = "prepared"
      DESTINATION_TOPIC     = "${data.aws_ssm_parameter.pnm-sns2cardssqs-topic.value}"
      CONFIG_FILE_BUCKET    = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
      CONFIG_FILE_KEY       = "appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/pnm_config.json"

    }
  }

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-s3sns2s3-pnm-dataload-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "s3sns2s3-pnm-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-pnm.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-pnm-con-${var.region_code}"
}

resource "aws_lambda_permission" "s3sns2s3-pnm-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-pnm.arn
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_ssm_parameter.pnm-sns-topic.value
}

resource "aws_sqs_queue" "sqs2lambda-pnm-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2lambda-pnm-${var.region_code}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 900
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Id": "sqsmarketinganalytics",
  "Statement":[
    {
      "Sid":"sqs2lambda-pnm-sqs",
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2lambda-pnm-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"${data.aws_ssm_parameter.pnm-sns-topic.value}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2lambda-pnm-${var.region_code}"
    )
  )

}

resource "aws_sns_topic_subscription" "pnm-subscription" {
  topic_arn = "${data.aws_ssm_parameter.pnm-sns-topic.value}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs2lambda-pnm-sqs.arn
  depends_on = [aws_sqs_queue.sqs2lambda-pnm-sqs, aws_lambda_function.s3sns2s3-pnm]
}

resource "aws_lambda_event_source_mapping" "pnm-lambda-trigger" {
  event_source_arn = aws_sqs_queue.sqs2lambda-pnm-sqs.arn
  function_name    = aws_lambda_function.s3sns2s3-pnm.arn
  batch_size = 1
}

resource "aws_iam_role" "s3sns2s3-pnm-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2s3-pnm-dataload"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-s3sns2s3-pnm-dataload"
    )
  )

}

resource "aws_iam_policy" "s3sns2s3-pnm-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-pnm-dataload"
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
        "Action": [
            "sns:*"
        ],
        "Effect": "Allow",
        "Resource": "${data.aws_ssm_parameter.pnm-sns2cardssqs-topic.value}"
    },
    {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-pnm-con-${var.region_code}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-pnm-con-${var.region_code}/*"]
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
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2s3-pnm-dataload"
    )
  )

}

resource "aws_iam_policy_attachment" "s3sns2s3-pnm-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-pnm-dataload-attachment"
  policy_arn = aws_iam_policy.s3sns2s3-pnm-policy.arn
  roles = [aws_iam_role.s3sns2s3-pnm-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "s3sns2s3-pnm-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2s3-pnm-dataload-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2s3-pnm.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2s3-pnm.function_name} lambda function"

  tags = merge(
    local.pnm_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-s3sns2s3-pnm-dataload-${var.region_code}"
    )
  )
}
