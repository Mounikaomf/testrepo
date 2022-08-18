locals {
  luminate_common_tags = {
    Application = "Luminate"
    ApplicationSubject = "Luminate"
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

resource "aws_security_group" "luminate-fromsnowflake2s3" {
  name        = "${var.account_code}-${var.env}-lambda-luminate-fromsnowflake2s3-${var.region_code}"
  description = "Allow luminate-fromsnowflake2s3 outbound traffic"
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
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-luminate-fromsnowflake2s3-${var.region_code}"
    )
  )

}

resource "aws_lambda_function" "luminate-fromsnowflake2s3" {
  function_name = "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-luminate-${var.region_code}"
  role          = aws_iam_role.luminate-fromsnowflake2s3.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.snowflake_offload_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.luminate-private-subnet-0.value, data.aws_ssm_parameter.luminate-private-subnet-1.value]
    security_group_ids = [aws_security_group.luminate-fromsnowflake2s3.id]
  }
  environment {
    variables = {
      DESTINATION_BUCKET               = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
      DESTINATION_PREFIX               = "fraud_hot_file_snowflake_data/out"
      SQL_QUERIES_JSON_FILE            = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/sql_queries.json"
      SQL_QUERY_USECASE                = "fraud_hot_file_unlod_to_s3"
      SSM_SNOWFLAKE_USER               = "/${var.account_code}/acc/datastorage/snowflake/user"
      SSM_SNOWFLAKE_PASSWORD           = "/${var.account_code}/acc/datastorage/snowflake/password"
      SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER = "/${var.account_code}/acc/datastorage/snowflake/accound_id"
      SSM_SNOWFLAKE_WAREHOUSE          = "/${var.account_code}/acc/datastorage/snowflake/warehouse"
      SSM_SNOWFLAKE_ROLE               = "/${var.account_code}/acc/datastorage/snowflake/role"
      SNOWFLAKE_SOURCE_DATABASE        = "CARDS"
      SNOWFLAKE_SOURCE_SCHEMA          = "INGESTION_UTILS"
      STORAGE_S3_INTEGRATION           = ""
    }
  }

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-luminate-${var.region_code}"
    )
  )

}

resource "aws_cloudwatch_event_rule" "luminate-lambda-cron" {
  name                = "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-luminate-${var.region_code}"
  description         = "trigger for lambda fromsnowflake2s3"
  schedule_expression = "cron(0 13 * * ? *)"

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-luminate-${var.region_code}"
    )
  )

}

resource "aws_cloudwatch_event_target" "luminate-lambda-cron-target" {
  rule = "${aws_cloudwatch_event_rule.luminate-lambda-cron.name}"
  target_id = "${aws_lambda_function.luminate-fromsnowflake2s3.function_name}"
  arn = "${aws_lambda_function.luminate-fromsnowflake2s3.arn}"
}

resource "aws_lambda_permission" "luminate-allows3-fromsnowflake2s3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.luminate-fromsnowflake2s3.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_lambda_permission" "luminate-allowcloudwatchevent-fromsnowflake2s3" {
  statement_id  = "AllowCloudwatchEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.luminate-fromsnowflake2s3.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.luminate-lambda-cron.arn
}

resource "aws_iam_role" "luminate-fromsnowflake2s3" {
  name = "${var.account_code}-${var.env}-iamrole-luminate-fromsnowflake2s3"

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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-luminate-fromsnowflake2s3"
    )
  )

}

resource "aws_iam_policy" "luminate-fromsnowflake2s3-lambda" {
  name   = "${var.account_code}-${var.env}-iampolicy-luminate-fromsnowflake2s3-lambda"
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
        "Resource": [
          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
          "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        ]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": [
          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",
          "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
        ]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
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
    },
    {
      "Action": [
          "sqs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-luminate-fromsnowflake2s3-lambda"
    )
  )
}

resource "aws_iam_policy_attachment" "luminate-attachment-fromsnowflake2s3-lambda" {
  name       = "${var.account_code}-${var.env}-iampolicy-fromsnowflake2s3-luminateattachmentlambda"
  policy_arn = aws_iam_policy.luminate-fromsnowflake2s3-lambda.arn
  roles      = [aws_iam_role.luminate-fromsnowflake2s3.name]
}

resource "aws_cloudwatch_metric_alarm" "luminate-fromsnowflake2s3-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-fromsnowflake2s3-luminate-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.luminate-fromsnowflake2s3.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.luminate-fromsnowflake2s3.function_name} lambda function"

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-fromsnowflake2s3-luminate-${var.region_code}"
    )
  )
}
