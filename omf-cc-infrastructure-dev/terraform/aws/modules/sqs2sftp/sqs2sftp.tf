data "aws_ssm_parameter" "sqs2sftp-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "sqs2sftp-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "sqs2sftp-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}
data "aws_ssm_parameter" "sqs2sftp-target-port" {
  name = var.sftp_target_port
}

resource "aws_security_group" "sqs2sftp-copy" {
   name = "${var.account_code}-${var.env}-lambda-sqs2sftp-${var.name}-${var.region_code}"
   description = "Allow sqs2sftp-copy outbound traffic"
   vpc_id      = data.aws_ssm_parameter.sqs2sftp-vpc-id.value
   egress {
       from_port        = data.aws_ssm_parameter.sqs2sftp-target-port.value
       to_port          = data.aws_ssm_parameter.sqs2sftp-target-port.value
       protocol         = "tcp"
       cidr_blocks      = ["0.0.0.0/0"]
       ipv6_cidr_blocks = ["::/0"]
     }
   egress {
     from_port        = "443"
     to_port          = "443"
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     ipv6_cidr_blocks = ["::/0"]
   }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2sftp-${var.name}-${var.region_code}"
    )
  )

 }

resource "aws_lambda_function" "sqs2sftp-copy" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2sftp-${var.name}-${var.region_code}"
  role          = aws_iam_role.sqs2sftp-s3copy.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${var.version_lambda}.zip"
  handler       = "s3snsoperations.sns2sftp_deliver_file"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [ data.aws_ssm_parameter.sqs2sftp-private-subnet-0.value, data.aws_ssm_parameter.sqs2sftp-private-subnet-1.value ]
    security_group_ids = [ aws_security_group.sqs2sftp-copy.id ]
  }
  environment {
    variables = {
      aws_region            = var.region_code
      SOURCE_FILTER_PREFIX            = var.source_filter_prefix
      SFTP_TARGET_HOSTNAME            = var.sftp_target_hostname
      SFTP_TARGET_USER_SSM            = var.sftp_target_user_ssm
      SFTP_TARGET_PASS_SSM            = var.sftp_target_pass_ssm
      SFTP_TARGET_PORT                = var.sftp_target_port
      SFTP_TARGET_DIRECTORY           = var.sftp_target_directory
      FEEDNAME                        = var.feedname
    }
  }

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2sftp-${var.name}-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "sqs2sftp-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2sftp-copy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket}"
}

resource "aws_sqs_queue" "sqs2sftp-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2sftp-${var.name}-${var.region_code}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 900
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2sftp-${var.name}-${var.region_code}",
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
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2sftp-${var.name}-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue_policy" "sqs2sftp-sqs-policy" {
  queue_url = aws_sqs_queue.sqs2sftp-sqs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sqs2sftp-sqs.arn}",
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

resource "aws_lambda_permission" "sqs2sftp-allowsns" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs2sftp-copy.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.snstopic_arn
}

resource "aws_sns_topic_subscription" "sqs2sftp-subscription" {
  topic_arn = var.snstopic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs2sftp-sqs.arn
}

resource "aws_lambda_event_source_mapping" "sqs2sftp-lambda-trigger" {
  event_source_arn = aws_sqs_queue.sqs2sftp-sqs.arn
  function_name    = aws_lambda_function.sqs2sftp-copy.arn
  batch_size = 1
  depends_on = [ aws_sqs_queue.sqs2sftp-sqs ]
}

resource "aws_iam_role" "sqs2sftp-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-sqs2sftp-${var.name}"
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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sqs2sftp-${var.name}"
    )
  )
  
}

resource "aws_iam_role_policy" "sqs2sftp-lambda-sqs-policy" {
  name = "${var.account_code}-${var.env}-lambdasqs-sqs2sftp-${var.name}"
  role = "${aws_iam_role.sqs2sftp-s3copy.id}"
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
          "ssm:Describe*",
          "ssm:Get*",
          "ssm:List*"
            ],
      "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": "ec2:*",
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
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"]
    },
    {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.source_bucket}"]
    },
    {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*"]
    },
    {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.source_bucket}/*"]
    },
    {
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": [ "${aws_sqs_queue.sqs2sftp-sqs.arn}" ]
    }
  ]
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "sqs2sftp-copy-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sqs2sftp-${var.name}-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.sqs2sftp-copy.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.sqs2sftp-copy.function_name} lambda function"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-sqs2sftp-${var.name}-${var.region_code}"
    )
  )
}
