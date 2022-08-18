locals {
  acxiom_common_tags = {
    Application = "Acxiom"
    ApplicationSubject = "Acxiom"
  }
}

module "acxiom-dataaccess-sqs2sftp" {
  source               = "../../modules/sqs2sftp"
  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "acxiom-dataaccess"
  region_code = var.region_code
  sftp_target_directory = ""
  sftp_target_hostname  = "/${var.account_code}/acc/dataaccess/sftp/acxiom/hostname"
  sftp_target_pass_ssm  = "/${var.account_code}/acc/dataaccess/sftp/acxiom/pass"
  sftp_target_user_ssm  = "/${var.account_code}/acc/dataaccess/sftp/acxiom/user"
  sftp_target_port      = "/${var.account_code}/acc/dataaccess/sftp/acxiom/port"
  source_bucket         = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  version_lambda        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  snstopic_arn          = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-acxiom-dataaccess-${var.region_code}"
  source_filter_prefix  = "acxiom_directmail_encrypted/out"
  tags_var = local.acxiom_common_tags
}

resource "aws_lambda_function" "acxiom-sqs2encrypt" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2encrypt-acxiom-${var.region_code}"
  role          = aws_iam_role.acxiom-sqs2encrypt.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.gpg_encrypt_file"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      TARGET_PREFIX         = "*"
      PUBLIC_KEY_SSM        = "/${var.account_code}/acc/sftp-datatarget/acxiom_directmail/public_key"
      FEEDNAME              = "AcxiomDirectMail"
      SOURCE_FILTER_PREFIX  = "acxiom_directmail/out"
      TARGET_S3_BUCKET      = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
      TARGET_S3_PREFIX      = "acxiom_directmail_encrypted/out"
    }
  }

  tags = merge(
    local.acxiom_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2encrypt-acxiom-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "acxiom-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acxiom-sqs2encrypt.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_sqs_queue" "acxiom-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2encrypt-acxiom-${var.region_code}"
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
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2encrypt-acxiom-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-encrypt-acxiom-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.acxiom_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2encrypt-acxiom-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue_policy" "acxiom-sqs-policy" {
  queue_url = aws_sqs_queue.acxiom-sqs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.acxiom-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-encrypt-acxiom-${var.region_code}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "acxiom-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acxiom-sqs2encrypt.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-encrypt-acxiom-${var.region_code}"
}

resource "aws_sns_topic_subscription" "acxiom-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-encrypt-acxiom-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.acxiom-sqs.arn
  depends_on = [aws_lambda_function.acxiom-sqs2encrypt, aws_lambda_permission.acxiom-allowsns]
}

resource "aws_lambda_event_source_mapping" "acxiom-lambda-trigger" {
  event_source_arn = aws_sqs_queue.acxiom-sqs.arn
  function_name    = aws_lambda_function.acxiom-sqs2encrypt.arn
  batch_size = 1
}

resource "aws_iam_role" "acxiom-sqs2encrypt" {
  name = "${var.account_code}-${var.env}-iamrole-acxiom-sqs2encrypt"

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
    local.acxiom_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-acxiom-sqs2encrypt"
    )
  )

}

resource "aws_iam_policy" "acxiom-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-sqs2encrypt-acxiom-lambda"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",  "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"]
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
    local.acxiom_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-sqs2encrypt-acxiom-lambda"
    )
  )

}

resource "aws_iam_policy_attachment" "acxiom-attachment-lambda" {
  name = "${var.account_code}-${var.env}-iampolicy-sqs2encrypt--acxiomattachmentlambda"
  policy_arn = aws_iam_policy.acxiom-lambda.arn
  roles = [aws_iam_role.acxiom-sqs2encrypt.name]
}

resource "aws_cloudwatch_metric_alarm" "acxiom-sqs2encrypt-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sqs2encrypt-acxiom-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.acxiom-sqs2encrypt.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.acxiom-sqs2encrypt.function_name} lambda function"

  tags = merge(
    local.acxiom_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-sqs2encrypt-acxiom-lambda"
    )
  )
}
