data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "s3sns2batch-failure-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s3sns2batch-failure-trailer-${var.name}-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_caller_identity.current.account_id}"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2batch-failure-trailer-${var.name}-${var.region_code}"
    }
  ]
}
POLICY

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-snstopic-s3sns2batch-failure-trailer-${var.name}-${var.region_code}"
    )
  )
  
}

resource "aws_lambda_function" "s3sns2batch-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2batch-trailer-${var.name}-${var.region_code}"
  role          = aws_iam_role.s3sns2batch-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${var.version_lambda}.zip"
  handler       = "batchoperations.fis_batch_lambda_handler"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  
  environment {
    variables = {
      TARGET_PREFIX         = "*"
      DESTINATION_BUCKET    = var.destination_bucket
      aws_region            = var.region_code
      SOURCE_FILTER_PREFIX  = var.source_filter_prefix
      DESTINATION_PREFIX    = var.destination_prefix
      CONFIG_FILE           = var.config_file
      APPEND_DATETIME       = var.append_datetime
      APPEND_DATE           = var.append_date
      SNS_FAILED_TRANSFERS  = aws_sns_topic.s3sns2batch-failure-snstopic.arn
      JOB_NAME              = var.job_name
      JOB_QUEUE             = var.job_queue
      JOB_DEFINITION        = var.job_definition
    }
  }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-s3sns2batch-trailer-${var.name}-${var.region_code}"
    )
  )
}

resource "aws_lambda_permission" "s3sns2batch-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2batch-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket}"
}

resource "aws_sns_topic" "s3sns2batch-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s3sns2batch-trailer-${var.name}-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2batch-trailer-${var.name}-${var.region_code}",
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
      "ApplicationComponent", "${var.account_code}-${var.env}-snstopic-s3sns2batch-trailer-${var.name}-${var.region_code}"
    )
  )  
}

resource "aws_lambda_permission" "s3sns2batch-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2batch-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3sns2batch-snstopic.arn
}

resource "aws_sns_topic_subscription" "s3sns2batch-subscription" {
  topic_arn = aws_sns_topic.s3sns2batch-snstopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3sns2batch-copy.arn
  depends_on = [aws_lambda_function.s3sns2batch-copy, aws_lambda_permission.s3sns2batch-allowsns]
}

resource "aws_iam_role" "s3sns2batch-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2batch-trailer-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "batch.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-s3sns2batch-trailer-${var.name}"
    )
  )  
}

resource "aws_iam_policy" "s3sns2batch-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2batch-trailer-${var.name}"
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
    },
    {
            "Effect": "Allow",
            "Action": [
                "batch:*"
            ],
            "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2batch-trailer-${var.name}"
    )
  )  
}

resource "aws_iam_policy_attachment" "s3sns2batch-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2batch-trailer-${var.name}-attachment"
  policy_arn = aws_iam_policy.s3sns2batch-policy.arn
  roles = [aws_iam_role.s3sns2batch-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "s3sns2batch-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2batch-trailer-${var.name}-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2batch-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2batch-copy.function_name} lambda function"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-s3sns2batch-trailer-${var.name}-${var.region_code}"
    )
  ) 
}