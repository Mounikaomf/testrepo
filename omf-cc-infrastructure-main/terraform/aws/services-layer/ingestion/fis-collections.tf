resource "aws_lambda_function" "s3sns2s3-fis-collections-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2s3-fis-collections-ingestion-${var.region_code}"
  role          = aws_iam_role.s3sns2s3-fis-collections-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.sns_s3_copy_file_with_filename_filter"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      DESTINATION_BUCKET    = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
      CONFIG_FILE           = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/collections_raw_config.json"
      aws_region            = "${var.region_code}"
      SOURCE_PREFIX_FILTER  = "fisvgs/Collections"
      DESTINATION_PREFIX    = "raw"
      aws_region            = var.region_code
    }
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-s3sns2s3-fis-collections-ingestion-${var.region_code}",
      "ApplicationSubject", "FIS-Collections"
    )
  )

}

resource "aws_lambda_permission" "s3sns2s3-fis-collections-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-fis-collections-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}"
}

resource "aws_sns_topic" "s3sns2s3-fis-collections-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s3sns2s3-fis-collections-ingestion-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2s3-fis-collections-ingestion-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}"
        }
      }
    }
  ]
}
POLICY

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-snstopic-s3sns2s3-fis-collections-ingestion-${var.region_code}",
      "ApplicationSubject", "FIS-Collections"
    )
  )

}

resource "aws_lambda_permission" "s3sns2s3-fis-collections-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2s3-fis-collections-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3sns2s3-fis-collections-snstopic.arn
}

resource "aws_sns_topic_subscription" "s3sns2s3-fis-collections-subscription" {
  topic_arn = aws_sns_topic.s3sns2s3-fis-collections-snstopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3sns2s3-fis-collections-copy.arn
  depends_on = [aws_lambda_function.s3sns2s3-fis-collections-copy, aws_lambda_permission.s3sns2s3-fis-collections-allowsns]
}

resource "aws_iam_role" "s3sns2s3-fis-collections-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2s3-fis-collections-ingestion"

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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-s3sns2s3-fis-collections-ingestion",
      "ApplicationSubject", "FIS-Collections"
    )
  )

}

resource "aws_iam_policy" "s3sns2s3-fis-collections-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-fis-collections-ingestion"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}/*"]
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2s3-fis-collections-ingestion",
      "ApplicationSubject", "FIS-Collections"
    )
  )

}

resource "aws_iam_policy_attachment" "s3sns2s3-fis-collections-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-fis-collections-ingestion-attachment"
  policy_arn = aws_iam_policy.s3sns2s3-fis-collections-policy.arn
  roles = [aws_iam_role.s3sns2s3-fis-collections-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "s3sns2s3-fis-collections-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2s3-fis-collections-ingestion-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2s3-fis-collections-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2s3-fis-collections-copy.function_name} lambda function"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-s3sns2s3-fis-collections-ingestion-${var.region_code}",
      "ApplicationSubject", "FIS-Collections"
    )
  )
}
