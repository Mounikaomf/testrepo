resource "aws_lambda_function" "s3sns2sftp-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-s3sns2sftp-${var.name}-${var.region_code}"
  role          = aws_iam_role.s3sns2sftp-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${var.version_lambda}.zip"
  handler       = "s3snsoperations.sns2sftp_deliver_file"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      aws_region            = var.region_code
      SFTP_TARGET_HOSTNAME            = var.sftp_target_hostname
      SFTP_TARGET_USER_SSM            = var.sftp_target_user_ssm
      SFTP_TARGET_PASS_SSM            = var.sftp_target_pass_ssm
      SFTP_TARGET_PORT                = var.sftp_target_port
      SFTP_TARGET_DIRECTORY           = var.sftp_target_directory
      FEEDNAME                        = var.feedname
    }
  }
}

resource "aws_lambda_permission" "s3sns2sftp-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2sftp-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket}"
}

resource "aws_sns_topic" "s3sns2sftp-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s3sns2sftp-${var.name}-${var.region_code}"

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
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2sftp-${var.name}-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.source_bucket}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "s3sns2sftp-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3sns2sftp-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.s3sns2sftp-snstopic.arn
}

resource "aws_sns_topic_subscription" "s3sns2sftp-subscription" {
  topic_arn = aws_sns_topic.s3sns2sftp-snstopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3sns2sftp-copy.arn
  depends_on = [aws_lambda_function.s3sns2sftp-copy, aws_lambda_permission.s3sns2sftp-allowsns]
}

resource "aws_s3_bucket_notification" "s3sns2sftp-notification" {
  bucket = var.source_bucket

  topic {
    topic_arn     = aws_sns_topic.s3sns2sftp-snstopic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.notification_filter_prefix
    filter_suffix = var.notification_filter_suffix
  }
  depends_on = [
    aws_lambda_function.s3sns2sftp-copy,
    aws_sns_topic.s3sns2sftp-snstopic
  ]
}

resource "aws_iam_role" "s3sns2sftp-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s3sns2sftp-${var.name}"

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
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3sns2sftp-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2sftp-${var.name}"
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
        "Sid": "ListObjectsInBucket",
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"/*"]
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

resource "aws_iam_policy_attachment" "s3sns2sftp-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s3sns2sftp-${var.name}-attachment"
  policy_arn = aws_iam_policy.s3sns2sftp-policy.arn
  roles = [aws_iam_role.s3sns2sftp-s3copy.name]
}

resource "aws_cloudwatch_metric_alarm" "s3sns2sftp-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-s3sns2sftp-${var.name}-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.s3sns2sftp-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.s3sns2sftp-copy.function_name} lambda function"
}
