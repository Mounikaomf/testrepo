resource "aws_lambda_function" "sqs2s3-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2s3-${var.name}-${var.region_code}"
  role          = aws_iam_role.sqs2s3-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${var.version_lambda}.zip"
  handler       = "snssqs2s3operations.snssqs2_s3_handler"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      aws_region            = var.region_code
      APPEND_DATETIME       = var.append_datetime
      APPEND_DATE           = var.append_date
      VERSION_LAMBDA        = var.version_lambda
      TARGET_BUCKET         = var.target_bucket
      TARGET_PREFIX         = var.target_prefix
      FILE_NAME             = var.file_name
      QUEUE_NAME            = aws_sqs_queue.sqs2s3-sqs.name
      MAX_QUEUE_MESSAGES    = var.max_queue_messages
    }
  }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2s3-${var.name}-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue" "sqs2s3-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2s3-${var.name}-${var.region_code}"
  delay_seconds             = 0
  max_message_size          = 10240
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 960

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2s3-${var.name}-${var.region_code}"
    )
  )
}

resource "aws_sqs_queue_policy" "sqs2s3-sqs-policy" {
  queue_url = aws_sqs_queue.sqs2s3-sqs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "sqs2s3",
      "Effect": "Allow",
      "Principal": {
      "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sqs2s3-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": [
            "${var.snstopic_arn}"
          ]
        }
      }
    }
  ]
}
POLICY
}

#scheduled trigger for lambda
resource "aws_cloudwatch_event_rule" "sqs2s3-lambda-cron" {
  name                = "${var.account_code}-${var.env}-lambdatrigger-${var.name}-${var.region_code}"
  description         = "Fires every hour"
  schedule_expression = "cron(0 0/1 * * ? *)"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambdatrigger-${var.name}-${var.region_code}"
    )
  )
}

resource "aws_cloudwatch_event_target" "sqs2s3-lambda-cron-target" {
  rule      = "${aws_cloudwatch_event_rule.sqs2s3-lambda-cron.name}"
  target_id = "${aws_lambda_function.sqs2s3-copy.function_name}"
  arn       = "${aws_lambda_function.sqs2s3-copy.arn}"
}

resource "aws_lambda_permission" "sqs2s3-allowcloudwatchevent" {
  statement_id  = "AllowCloudwatchEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2s3-copy.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sqs2s3-lambda-cron.arn
}

resource "aws_sns_topic_subscription" "sqs2s3-subscription" {
  topic_arn = var.snstopic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs2s3-sqs.arn
  depends_on = [aws_lambda_function.sqs2s3-copy]
}

resource "aws_iam_role" "sqs2s3-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-sqs2s3-${var.name}"

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
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sqs2s3-${var.name}"
    )
  )

}

resource "aws_iam_policy" "sqs2s3-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}-lambda"
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
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.target_bucket}"]
    },
    {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.target_bucket}/*"]
    },
    {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
    },
    {
            "Action": [
                "sqs:ChangeMessageVisibility",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:ReceiveMessage"
            ],
            "Effect": "Allow",
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
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}-lambda"
    )
  )

}

resource "aws_iam_policy_attachment" "sqs2s3-attachment-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}-attachmentlambda"
  policy_arn = aws_iam_policy.sqs2s3-lambda.arn
  roles = [aws_iam_role.sqs2s3-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "sqs2s3-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sqs2s3-${var.name}-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.sqs2s3-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.sqs2s3-copy.function_name} lambda function"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-sqs2s3-${var.name}-${var.region_code}"
    )
  )
}
