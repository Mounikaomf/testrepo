resource "aws_lambda_function" "sqs2s3-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2s3-${var.name}-${var.region_code}"
  role          = aws_iam_role.sqs2s3-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${var.version_lambda}.zip"
  handler       = "s3snsoperations.sns_s3_copy_file"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      TARGET_PREFIX         = "*"
      DESTINATION_BUCKET    = var.destination_bucket
      CONFIG_FILE           = var.config_file
      aws_region            = var.region_code
      SOURCE_PREFIX_FILTER  = var.source_prefix_filter
      DESTINATION_PREFIX    = var.destination_prefix
      APPEND_DATETIME       = var.append_datetime
      APPEND_DATE           = var.append_date
      VERSION_LAMBDA        = var.version_lambda

    }
  }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2s3-${var.name}-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "sqs2s3-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2s3-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket}"
}

resource "aws_sqs_queue" "sqs2s3-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2s3-${var.name}-${var.region_code}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 900
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Id": "sqspolicy",
  "Statement":[
    {
      "Sid":"sqs2s3",
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2s3-${var.name}-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"${var.snstopic_arn}"
        }
      }
    }
  ]
}
EOF

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
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sqs2s3-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${var.snstopic_arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "sqs2s3-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2s3-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.snstopic_arn
}

resource "aws_sns_topic_subscription" "sqs2s3-subscription" {
  topic_arn = var.snstopic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs2s3-sqs.arn
  depends_on = [aws_lambda_function.sqs2s3-copy, aws_lambda_permission.sqs2s3-allowsns]
}

resource "aws_lambda_event_source_mapping" "sqs2s3-lambda-trigger" {
  event_source_arn = aws_sqs_queue.sqs2s3-sqs.arn
  function_name    = aws_lambda_function.sqs2s3-copy.arn
  batch_size = 1
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
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.source_bucket}", "arn:aws:s3:::${var.destination_bucket}"]
    },
    {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.source_bucket}/*", "arn:aws:s3:::${var.destination_bucket}/*"]
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
