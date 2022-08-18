data "aws_ssm_parameter" "livevoxinput-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "livevoxinput-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "livevoxinput-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

resource "aws_security_group" "livevoxinput-snowflake" {
  name        = "${var.account_code}-${var.env}-lambda-livevoxinput-sf-${var.region_code}"
  description = "Allow livevoxinput-snowflake outbound traffic"
  vpc_id      = data.aws_ssm_parameter.livevoxinput-vpc-id.value
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

#Lambda to call snowflake procedure to load stage to main
resource "aws_lambda_function" "livevoxinput-sfstg2main" {
  function_name = "${var.account_code}-${var.env}-lambda-livevoxinput-sfstg2main-${var.region_code}"
  role          = aws_iam_role.livevoxinput-sfstg2main.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.livevoxinput-private-subnet-0.value, data.aws_ssm_parameter.livevoxinput-private-subnet-1.value]
    security_group_ids = [aws_security_group.livevoxinput-snowflake.id]
  }
  environment {
    variables = {
      SSM_SNOWFLAKE_USER               = "/${var.account_code}/acc/datastorage/snowflake/user"
      SSM_SNOWFLAKE_PASSWORD           = "/${var.account_code}/acc/datastorage/snowflake/password"
      SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER = "/${var.account_code}/acc/datastorage/snowflake/accound_id"
      SSM_SNOWFLAKE_WAREHOUSE          = "/${var.account_code}/acc/datastorage/snowflake/warehouse"
      SSM_SNOWFLAKE_ROLE               = "/${var.account_code}/acc/datastorage/snowflake/role"
      SNOWFLAKE_SOURCE_DATABASE        = "CARDS"
      SNOWFLAKE_SOURCE_SCHEMA          = "INGESTION_UTILS"
      STORAGE_S3_INTEGRATION           = ""
      SQL_QUERIES_JSON_FILE            = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/sql_queries.json"
      SQL_QUERY_USECASE                = "livevox_input_load_stage_to_main"

    }
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-livevoxinput-sfstg2main-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_lambda_permission" "livevoxinput-sfstg2main-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.livevoxinput-sfstg2main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_iam_role" "livevoxinput-sfstg2main" {
  name = "${var.account_code}-${var.env}-iamrole-livevoxinput-sfstg2main"

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
        "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-livevoxinput-sfstg2main",
        "ApplicationSubject", "FIS-LiveVox"
      )
  )

}

resource "aws_iam_policy" "livevoxinput-sfstg2main-lambda" {
  name   = "${var.account_code}-${var.env}-iampolicy-livevoxinput-sfstg2main-lambda"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-livevoxinput-sfstg2main-lambda",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy_attachment" "attachment-livevoxinput-sfstg2main-lambda" {
  name       = "${var.account_code}-${var.env}-iampolicy-livevoxinput-sfstg2main-attachment-lambda"
  policy_arn = aws_iam_policy.livevoxinput-sfstg2main-lambda.arn
  roles      = [aws_iam_role.livevoxinput-sfstg2main.name]
}

resource "aws_cloudwatch_metric_alarm" "livevoxinput-sfstg2main-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-livevoxinput-sfstg2main-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.livevoxinput-sfstg2main.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.livevoxinput-sfstg2main.function_name} lambda function"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-livevoxinput-sfstg2main-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}


#Lambda to call snowflake procedure to unload to S3
resource "aws_lambda_function" "livevoxinput-unload2s3" {
  function_name = "${var.account_code}-${var.env}-lambda-livevoxinput-unload2s3-${var.region_code}"
  role          = aws_iam_role.livevoxinput-unload2s3.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.livevoxinput-private-subnet-0.value, data.aws_ssm_parameter.livevoxinput-private-subnet-1.value]
    security_group_ids = [aws_security_group.livevoxinput-snowflake.id]
  }
  environment {
    variables = {
      SSM_SNOWFLAKE_USER               = "/${var.account_code}/acc/datastorage/snowflake/user"
      SSM_SNOWFLAKE_PASSWORD           = "/${var.account_code}/acc/datastorage/snowflake/password"
      SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER = "/${var.account_code}/acc/datastorage/snowflake/accound_id"
      SSM_SNOWFLAKE_WAREHOUSE          = "/${var.account_code}/acc/datastorage/snowflake/warehouse"
      SSM_SNOWFLAKE_ROLE               = "/${var.account_code}/acc/datastorage/snowflake/role"
      SNOWFLAKE_SOURCE_DATABASE        = "CARDS"
      SNOWFLAKE_SOURCE_SCHEMA          = "INGESTION_UTILS"
      STORAGE_S3_INTEGRATION           = ""
      SQL_QUERIES_JSON_FILE            = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/sql_queries.json"
      SQL_QUERY_USECASE                = "livevox_input_file_unload_to_s3"

    }
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-livevoxinput-unload2s3-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_lambda_permission" "livevoxinput-unload2s3-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.livevoxinput-unload2s3.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_iam_role" "livevoxinput-unload2s3" {
  name = "${var.account_code}-${var.env}-iamrole-livevoxinput-unload2s3"

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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-livevoxinput-unload2s3",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy" "livevoxinput-unload2s3-lambda" {
  name   = "${var.account_code}-${var.env}-iampolicy-livevoxinput-unload2s3-lambda"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-livevoxinput-unload2s3-lambda",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy_attachment" "attachment-livevoxinput-unload2s3-lambda" {
  name       = "${var.account_code}-${var.env}-iampolicy-livevoxinput-unload2s3-attachment-lambda"
  policy_arn = aws_iam_policy.livevoxinput-unload2s3-lambda.arn
  roles      = [aws_iam_role.livevoxinput-unload2s3.name]
}

resource "aws_cloudwatch_metric_alarm" "livevoxinput-unload2s3-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-livevoxinput-unload2s3-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.livevoxinput-unload2s3.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.livevoxinput-unload2s3.function_name} lambda function"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-livevoxinput-unload2s3-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}


#Stepfunction to call above lambdas
resource "aws_sfn_state_machine" "livevoxinput-stepfunction" {
  name     = "${var.account_code}-${var.env}-fis-livevoxinput-stepfunction-${var.region_code}"
  role_arn = aws_iam_role.livevoxinput-stepfunction.arn
  definition = templatefile(
  "../../../stepfunction/livevoxinput/livevoxinput_step.json",
  {

    #lambda part
    sfstg2main_lambda      = aws_lambda_function.livevoxinput-sfstg2main.function_name
    unload2s3_lambda     = aws_lambda_function.livevoxinput-unload2s3.function_name

  }
  )

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-livevoxinput-stepfunction-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}

resource "aws_iam_role" "livevoxinput-stepfunction" {
  name = "${var.account_code}-${var.env}-iamrole-livevoxinput-stepfunction"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Sid": "",
            "Principal": {
                "Service": "states.amazonaws.com"
            }
        }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-livevoxinput-stepfunction",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy" "livevoxinput-stepfunction" {
  name = "${var.account_code}-${var.env}-iampolicy-livevoxinput-stepfunction"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "cloudwatch:*",
                "lambda:*",
                "events:*",
                "logs:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-livevoxinput-stepfunction",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy_attachment" "livevoxinput-stepfunction" {
  name = "${var.account_code}-${var.env}-pattach-livevoxinput-stepfunction"
  roles      = [aws_iam_role.livevoxinput-stepfunction.name]
  policy_arn = aws_iam_policy.livevoxinput-stepfunction.arn
}

resource "aws_cloudwatch_event_rule" "livevoxinput-s3filecreated-rule" {
  name        = "${var.account_code}-${var.env}-livevoxinput-s3filecreated-rule-${var.region_code}"
  description = "Capture created file event in sfexchange bucket livevoxinput"

  event_pattern = <<EVENT
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"]
    },
    "object": {
      "key" : [{"prefix" : "FIS/LIVEVOXINPUT/TO-BE-PROCESSED/"}]
    }
  }
}
EVENT

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-livevoxinput-s3filecreated-rule-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_cloudwatch_event_target" "livevoxinput-s3filecreated-target" {
  rule      = aws_cloudwatch_event_rule.livevoxinput-s3filecreated-rule.name
  target_id = "RunStepFunction"
  arn       = aws_sfn_state_machine.livevoxinput-stepfunction.arn
  role_arn  = aws_iam_role.livevoxinput-eventbridge.arn
}

resource "aws_iam_role" "livevoxinput-eventbridge" {
  name = "${var.account_code}-${var.env}-iamrole-livevoxinput-eventbridge"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Sid": "",
            "Principal": {
                "Service": "events.amazonaws.com"
            }
        }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-livevoxinput-eventbridge",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy" "livevoxinput-eventbridge" {
  name = "${var.account_code}-${var.env}-iampolicy-livevoxinput-eventbridge"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "${aws_sfn_state_machine.livevoxinput-stepfunction.arn}"
            ]
        }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-livevoxinput-eventbridge",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy_attachment" "livevoxinput-eventbridge" {
  name = "${var.account_code}-${var.env}-pattach-livevoxinput-eventbridge"
  roles      = [aws_iam_role.livevoxinput-eventbridge.name]
  policy_arn = aws_iam_policy.livevoxinput-eventbridge.arn
}