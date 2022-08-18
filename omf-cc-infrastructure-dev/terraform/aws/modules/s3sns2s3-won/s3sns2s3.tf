resource "aws_lambda_function" "s3sns2s3-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2s3-${var.name}-${var.region_code}"
  role          = aws_iam_role.s3sns2s3-s3copy.arn
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
    }
  }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-s3sns2s3-${var.name}-${var.region_code}"
    )
  )
}

resource "aws_lambda_permission" "s3sns2s3-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket}"
}

resource "aws_sns_topic" "s3sns2s3-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s3sns2s3-${var.name}-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2s3-${var.name}-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.source_bucket}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-snstopic-s3sns2s3-${var.name}-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "s3sns2s3-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3sns2s3-snstopic.arn
}

resource "aws_sns_topic_subscription" "s3sns2s3-subscription" {
  topic_arn = aws_sns_topic.s3sns2s3-snstopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3sns2s3-copy.arn
  depends_on = [aws_lambda_function.s3sns2s3-copy, aws_lambda_permission.s3sns2s3-allowsns]
}

resource "aws_iam_role" "s3sns2s3-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2s3-${var.name}"

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
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-s3sns2s3-${var.name}"
    )
  )

}

resource "aws_iam_policy" "s3sns2s3-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.source_bucket}", "arn:aws:s3:::${var.destination_bucket}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.source_bucket}/*", "arn:aws:s3:::${var.destination_bucket}/*"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}"
    )
  )

}

resource "aws_iam_policy_attachment" "s3sns2s3-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-${var.name}-attachment"
  policy_arn = aws_iam_policy.s3sns2s3-policy.arn
  roles = [aws_iam_role.s3sns2s3-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "s3sns2s3-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2s3-${var.name}-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2s3-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2s3-copy.function_name} lambda function"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-s3sns2s3-${var.name}-${var.region_code}"
    )
  )
}
