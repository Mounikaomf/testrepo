locals {
  historical_common_tags = {
    Application = "Historical"
    ApplicationSubject = "Historical"
  }
}

#s3sns2s3 historical lambda
resource "aws_lambda_function" "s3sns2s3-historical" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2s3-historical-${var.region_code}"
  role          = aws_iam_role.s3sns2s3-historical.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3operations.reprocess_data_glue_historical_to_raw"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      APPEND_DATETIME       = false
      APPEND_DATE           = ""
      VERSION_LAMBDA        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}" 
      aws_region            = var.region_code            
    }
  }

  tags = merge(
    local.historical_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-s3sns2s3-historical-${var.region_code}"
    )
  )

}

resource "aws_iam_role" "s3sns2s3-historical" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2s3-historical"

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
    local.historical_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-s3sns2s3-historical"
    )
  )

}

resource "aws_iam_role_policy" "s3sns2s3-historical-lambda-sqs-policy" {
  name = "${var.account_code}-${var.env}-lambdasqs-s3sns2s3-historical"
  role = "${aws_iam_role.s3sns2s3-historical.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
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
        "Resource": ["arn:aws:s3:::*"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::*/*"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "glue:*",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "s3sns2s3-historical-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2s3-historical-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2s3-historical.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2s3-historical.function_name} lambda function"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-s3sns2s3-historical-${var.region_code}",
      "ApplicationSubject", "FIS-Collections"
    )
  )
}
