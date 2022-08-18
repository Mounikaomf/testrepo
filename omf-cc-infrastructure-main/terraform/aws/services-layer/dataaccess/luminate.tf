locals {
  luminate_common_tags = {
    Application = "Luminate"
    "ApplicationSubject" = "Luminate"
  }
}

data "aws_ssm_parameter" "luminate-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "luminate-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "luminate-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

resource "aws_security_group" "luminate-sqs2api" {
  name        = "${var.account_code}-${var.env}-lambda-luminate-sqs2api-${var.region_code}"
  description = "Allow luminate-sqs2api outbound traffic"
  vpc_id      = data.aws_ssm_parameter.luminate-vpc-id.value
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-luminate-sqs2api-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue" "luminate-dead-letter-queue-sqs2api" {
  name = "${var.account_code}-${var.env}-luminate-deadletterqueue-sqs2api-${var.region_code}"

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-luminate-deadletterqueue-sqs2api-${var.region_code}"
    )
  )

}

resource "aws_lambda_function" "luminate-sqs2api" {
  function_name = "${var.account_code}-${var.env}-lambda-sqs2api-luminate-${var.region_code}"
  role          = aws_iam_role.luminate-sqs2api.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3snsoperations.s32luminate"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.luminate-private-subnet-0.value, data.aws_ssm_parameter.luminate-private-subnet-1.value]
    security_group_ids = [aws_security_group.luminate-sqs2api.id]
  }
  environment {
    variables = {
      SCOPE                      = "https://api.equifax.com/business/luminate/v1/"
      AUTHORIZATION_ENDPOINT_SSM = "/${var.account_code}/${var.env}/dataaccess/auth/luminate/endpoint"
      API_ENDPOINT_SSM           = "/${var.account_code}/${var.env}/dataaccess/api/luminate/endpoint"
      SOURCE_FILTER_PREFIX       = "fraud_hot_file_request_data/out"
      CLIENT_SECRET_SSM          = "/${var.account_code}/${var.env}/dataaccess/api/luminate/clientsecret"
      CLIENT_ID_SSM              = "/${var.account_code}/${var.env}/dataaccess/api/luminate/clientid"

    }
  }
  
  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2api-luminate-${var.region_code}"
    )
  )
  
}

resource "aws_lambda_permission" "luminate-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.luminate-sqs2api.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"
}

resource "aws_sqs_queue" "luminate-sqs" {
  name                       = "${var.account_code}-${var.env}-luminate-sqs2api-${var.region_code}"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.luminate-dead-letter-queue-sqs2api.arn}\",\"maxReceiveCount\":2}"
  delay_seconds              = 90
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 180
  policy                     = <<EOF
{
  "Version":"2012-10-17",
  "Id": "sqspolicy",
  "Statement":[
    {
      "Sid":"luminatepolicy",
      "Effect":"Allow",
      "Principal":"*",
      "Action":"sqs:SendMessage",
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-luminate-sqs2api-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-luminate-sqs2api-${var.region_code}"
    )
  )

}

resource "aws_sqs_queue_policy" "luminate-sqs-policy" {
  queue_url = aws_sqs_queue.luminate-sqs.id
  policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "luminatepolicy",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.luminate-sqs.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "luminate-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.luminate-sqs2api.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"
}

resource "aws_sns_topic_subscription" "luminate-subscription" {
  topic_arn  = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-s32sns-luminate-${var.region_code}"
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.luminate-sqs.arn
  depends_on = [aws_lambda_function.luminate-sqs2api, aws_lambda_permission.luminate-allowsns]
}

resource "aws_lambda_event_source_mapping" "luminate-lambda-trigger" {
  event_source_arn = aws_sqs_queue.luminate-sqs.arn
  function_name    = aws_lambda_function.luminate-sqs2api.arn
  batch_size       = 1
}

resource "aws_iam_role" "luminate-sqs2api" {
  name = "${var.account_code}-${var.env}-iamrole-luminate-sqs2api"

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
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-luminate-sqs2api"
    )
  )

}

resource "aws_iam_policy" "luminate-lambda" {
  name   = "${var.account_code}-${var.env}-iampolicy-sqs2api-luminate-lambda"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",  "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"]
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
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-sqs2api-luminate-lambda"
    )
  )

}

resource "aws_iam_policy_attachment" "luminate-attachment-lambda" {
  name       = "${var.account_code}-${var.env}-iampolicy-sqs2api-luminateattachmentlambda"
  policy_arn = aws_iam_policy.luminate-lambda.arn
  roles      = [aws_iam_role.luminate-sqs2api.name]
}

resource "aws_cloudwatch_metric_alarm" "luminate-sqs2api-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-sqs2api-luminate-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.luminate-sqs2api.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.luminate-sqs2api.function_name} lambda function"

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-sqs2api-luminate-${var.region_code}"
    )
  )
}
