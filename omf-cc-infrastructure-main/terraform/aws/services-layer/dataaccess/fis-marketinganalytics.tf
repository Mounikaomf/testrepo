data "aws_ssm_parameter" "sqs2s3-marketinganalytics-destinationbucket" {
  name = "/${var.account_code}/${var.env}/dataaccess/s3/marketinganalytics/destinationbucket"
}

data "aws_ssm_parameter" "sqs2s3-marketinganalytics-sns-name" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/fis-marketinganalytics/name"
}

resource "aws_lambda_function" "sqs2s3-marketinganalytics-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2s3-marketinganalytics-${var.region_code}"
  role          = aws_iam_role.sqs2s3-marketinganalytics-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.sns_s3_copy_file"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      DESTINATION_BUCKET    = data.aws_ssm_parameter.sqs2s3-marketinganalytics-destinationbucket.value
      CONFIG_FILE           = ""
      SOURCE_PREFIX_FILTER  = "/raw/FOS statement index file"
      DESTINATION_PREFIX    = "FOS statement index file"
      APPEND_DATETIME       = false
      APPEND_DATE           = ""
    }
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2s3-marketinganalytics-${var.region_code}",
      "ApplicationSubject", "FIS-MarketingAnalytics"
    )
  )

}

resource "aws_lambda_permission" "sqs2s3-marketinganalytics-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2s3-marketinganalytics-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
}

resource "aws_sqs_queue" "sqs2s3-marketinganalytics-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2s3-marketinganalytics-${var.region_code}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 180
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Id": "sqsmarketinganalytics",
  "Statement":[
    {
      "Sid":"sqs2s3-marketinganalytics-sqs",
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2s3-marketinganalytics-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.sqs2s3-marketinganalytics-sns-name.value}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2s3-marketinganalytics-${var.region_code}",
      "ApplicationSubject", "FIS-MarketingAnalytics"
    )
  )

}

resource "aws_sqs_queue_policy" "sqs2s3-marketinganalytics-sqs-policy" {
  queue_url = aws_sqs_queue.sqs2s3-marketinganalytics-sqs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqsmarketinganalytics",
  "Statement": [
    {
      "Sid": "sqs2s3-marketinganalytics-sqs",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sqs2s3-marketinganalytics-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.sqs2s3-marketinganalytics-sns-name.value}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "sqs2s3-marketinganalytics-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2s3-marketinganalytics-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.sqs2s3-marketinganalytics-sns-name.value}"
}

resource "aws_sns_topic_subscription" "sqs2s3-marketinganalytics-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.sqs2s3-marketinganalytics-sns-name.value}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs2s3-marketinganalytics-sqs.arn
  depends_on = [aws_lambda_function.sqs2s3-marketinganalytics-copy, aws_lambda_permission.sqs2s3-marketinganalytics-allowsns]
}

resource "aws_lambda_event_source_mapping" "sqs2s3-marketinganalytics-lambda-trigger" {
  event_source_arn = aws_sqs_queue.sqs2s3-marketinganalytics-sqs.arn
  function_name    = aws_lambda_function.sqs2s3-marketinganalytics-copy.arn
  batch_size = 1
}

resource "aws_iam_role" "sqs2s3-marketinganalytics-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-sqs2s3-marketinganalytics"

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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sqs2s3-marketinganalytics",
      "ApplicationSubject", "FIS-MarketingAnalytics"
    )
  )

}

resource "aws_iam_role_policy" "sqs2s3-marketinganalytics-lambda-sqs-policy" {
  name = "${var.account_code}-${var.env}-lambdasqs-s3sns2s3-marketinganalytics"
  role = "${aws_iam_role.sqs2s3-marketinganalytics-s3copy.id}"
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
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::${data.aws_ssm_parameter.sqs2s3-marketinganalytics-destinationbucket.value}/*"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}", "arn:aws:s3:::${data.aws_ssm_parameter.sqs2s3-marketinganalytics-destinationbucket.value}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}/*", "arn:aws:s3:::${data.aws_ssm_parameter.sqs2s3-marketinganalytics-destinationbucket.value}/*"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "sqs2s3-marketinganalytics-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sqs2s3-marketinganalytics-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.sqs2s3-marketinganalytics-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.sqs2s3-marketinganalytics-copy.function_name} lambda function"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-sqs2s3-marketinganalytics-${var.region_code}",
      "ApplicationSubject", "FIS-MarketingAnalytics"
    )
  )
}
