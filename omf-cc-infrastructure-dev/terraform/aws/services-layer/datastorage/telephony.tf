locals {
  telephony_common_tags = {
    Application = "Telephony"
    ApplicationSubject = "Telephony"
  }
}

data "aws_ssm_parameter" "telephony-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "telephony-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "telephony-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

resource "aws_security_group" "telephony-snowflake" {
  name        = "${var.account_code}-${var.env}-lambda-telephony-sf-${var.region_code}"
  description = "Allow telephony-snowflake outbound traffic"
  vpc_id      = data.aws_ssm_parameter.telephony-vpc-id.value
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

#Lambda to call snowflake procedure to load stage to main telephony-callbycall
resource "aws_lambda_function" "telephony-callbycall-sfstg2main" {
  function_name = "${var.account_code}-${var.env}-lambda-telephony-callbycall-sfstg2main-${var.region_code}"
  role          = aws_iam_role.telephony-sfstg2main.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.telephony-private-subnet-0.value, data.aws_ssm_parameter.telephony-private-subnet-1.value]
    security_group_ids = [aws_security_group.telephony-snowflake.id]
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
      SQL_QUERY_USECASE                = "fis_telephony_call_by_call_load_stage_to_main"

    }
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-telephony-callbycall-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-callbycall-sfstg2main-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-callbycall-sfstg2main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_sqs_queue" "telephony-callbycall-sfstg2main-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2sf-telephony-callbycall-sfstg2main-${var.region_code}"
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
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2sf-telephony-callbycall-sfstg2main-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-callbycall-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2sf-telephony-callbycall-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-callbycall-sfstg2main-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-callbycall-sfstg2main.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-callbycall-${var.region_code}"
}

resource "aws_sns_topic_subscription" "telephony-callbycall-sfstg2main-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-callbycall-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.telephony-callbycall-sfstg2main-sqs.arn
  depends_on = [aws_lambda_function.telephony-callbycall-sfstg2main, aws_lambda_permission.telephony-callbycall-sfstg2main-allowsns]
}

resource "aws_lambda_event_source_mapping" "telephony-callbycall-sfstg2main-lambda-trigger" {
  event_source_arn = aws_sqs_queue.telephony-callbycall-sfstg2main-sqs.arn
  function_name    = aws_lambda_function.telephony-callbycall-sfstg2main.arn
  batch_size = 1
}

resource "aws_cloudwatch_metric_alarm" "telephony-callbycall-sfstg2main-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-telephony-callbycall-sfstg2main-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.telephony-callbycall-sfstg2main.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.telephony-callbycall-sfstg2main.function_name} lambda function"

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-telephony-callbycall-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )
}

#Lambda to call snowflake procedure to load stage to main telephony-calldisposition
resource "aws_lambda_function" "telephony-calldisposition-sfstg2main" {
  function_name = "${var.account_code}-${var.env}-lambda-telephony-calldisposition-sfstg2main-${var.region_code}"
  role          = aws_iam_role.telephony-sfstg2main.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.telephony-private-subnet-0.value, data.aws_ssm_parameter.telephony-private-subnet-1.value]
    security_group_ids = [aws_security_group.telephony-snowflake.id]
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
      SQL_QUERY_USECASE                = "fis_telephony_call_disposition_load_stage_to_main"

    }
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-telephony-calldisposition-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-calldisposition-sfstg2main-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-calldisposition-sfstg2main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_sqs_queue" "telephony-calldisposition-sfstg2main-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2sf-telephony-calldisposition-sfstg2main-${var.region_code}"
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
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2sf-telephony-calldisposition-sfstg2main-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-calldisposition-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2sf-telephony-calldisposition-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-calldisposition-sfstg2main-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-calldisposition-sfstg2main.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-calldisposition-${var.region_code}"
}

resource "aws_sns_topic_subscription" "telephony-calldisposition-sfstg2main-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-calldisposition-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.telephony-calldisposition-sfstg2main-sqs.arn
  depends_on = [aws_lambda_function.telephony-calldisposition-sfstg2main, aws_lambda_permission.telephony-calldisposition-sfstg2main-allowsns]
}

resource "aws_lambda_event_source_mapping" "telephony-calldisposition-sfstg2main-lambda-trigger" {
  event_source_arn = aws_sqs_queue.telephony-calldisposition-sfstg2main-sqs.arn
  function_name    = aws_lambda_function.telephony-calldisposition-sfstg2main.arn
  batch_size = 1
}

resource "aws_cloudwatch_metric_alarm" "telephony-calldisposition-sfstg2main-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-telephony-calldisposition-sfstg2main-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.telephony-calldisposition-sfstg2main.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.telephony-calldisposition-sfstg2main.function_name} lambda function"

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-telephony-calldisposition-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )
}

#Lambda to call snowflake procedure to load stage to main telephony-ivrdetails
resource "aws_lambda_function" "telephony-ivrdetails-sfstg2main" {
  function_name = "${var.account_code}-${var.env}-lambda-telephony-ivrdetails-sfstg2main-${var.region_code}"
  role          = aws_iam_role.telephony-sfstg2main.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.telephony-private-subnet-0.value, data.aws_ssm_parameter.telephony-private-subnet-1.value]
    security_group_ids = [aws_security_group.telephony-snowflake.id]
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
      SQL_QUERY_USECASE                = "fis_telephony_ivr_details_load_stage_to_main"

    }
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-telephony-ivrdetails-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-ivrdetails-sfstg2main-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-ivrdetails-sfstg2main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_sqs_queue" "telephony-ivrdetails-sfstg2main-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2sf-telephony-ivrdetails-sfstg2main-${var.region_code}"
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
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2sf-telephony-ivrdetails-sfstg2main-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-ivrdetails-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2sf-telephony-ivrdetails-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-ivrdetails-sfstg2main-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-ivrdetails-sfstg2main.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-ivrdetails-${var.region_code}"
}

resource "aws_sns_topic_subscription" "telephony-ivrdetails-sfstg2main-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-ivrdetails-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.telephony-ivrdetails-sfstg2main-sqs.arn
  depends_on = [aws_lambda_function.telephony-ivrdetails-sfstg2main, aws_lambda_permission.telephony-ivrdetails-sfstg2main-allowsns]
}

resource "aws_lambda_event_source_mapping" "telephony-ivrdetails-sfstg2main-lambda-trigger" {
  event_source_arn = aws_sqs_queue.telephony-ivrdetails-sfstg2main-sqs.arn
  function_name    = aws_lambda_function.telephony-ivrdetails-sfstg2main.arn
  batch_size = 1
}

resource "aws_cloudwatch_metric_alarm" "telephony-ivrdetails-sfstg2main-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-telephony-ivrdetails-sfstg2main-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.telephony-ivrdetails-sfstg2main.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.telephony-ivrdetails-sfstg2main.function_name} lambda function"

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-telephony-ivrdetails-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )
}

#Lambda to call snowflake procedure to load stage to main telephony-skilllevel
resource "aws_lambda_function" "telephony-skilllevel-sfstg2main" {
  function_name = "${var.account_code}-${var.env}-lambda-telephony-skilllevel-sfstg2main-${var.region_code}"
  role          = aws_iam_role.telephony-sfstg2main.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "snowflake_operations.execute_procedure"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  vpc_config {
    subnet_ids         = [data.aws_ssm_parameter.telephony-private-subnet-0.value, data.aws_ssm_parameter.telephony-private-subnet-1.value]
    security_group_ids = [aws_security_group.telephony-snowflake.id]
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
      SQL_QUERY_USECASE                = "fis_telephony_skill_level_load_stage_to_main"

    }
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-telephony-skilllevel-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-skilllevel-sfstg2main-allows3" {
  statement_id  = "AllowS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-skilllevel-sfstg2main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
}

resource "aws_sqs_queue" "telephony-skilllevel-sfstg2main-sqs" {
  name                      = "${var.account_code}-${var.env}-sqs2sf-telephony-skilllevel-sfstg2main-${var.region_code}"
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
      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2sf-telephony-skilllevel-sfstg2main-${var.region_code}",
      "Condition":{
        "ArnEquals":{
          "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-skilllevel-${var.region_code}"
        }
      }
    }
  ]
}
EOF

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-sqs2sf-telephony-skilllevel-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_lambda_permission" "telephony-skilllevel-sfstg2main-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telephony-skilllevel-sfstg2main.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-skilllevel-${var.region_code}"
}

resource "aws_sns_topic_subscription" "telephony-skilllevel-sfstg2main-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-telephony-skilllevel-${var.region_code}"
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.telephony-skilllevel-sfstg2main-sqs.arn
  depends_on = [aws_lambda_function.telephony-skilllevel-sfstg2main, aws_lambda_permission.telephony-skilllevel-sfstg2main-allowsns]
}

resource "aws_lambda_event_source_mapping" "telephony-skilllevel-sfstg2main-lambda-trigger" {
  event_source_arn = aws_sqs_queue.telephony-skilllevel-sfstg2main-sqs.arn
  function_name    = aws_lambda_function.telephony-skilllevel-sfstg2main.arn
  batch_size = 1
}

resource "aws_cloudwatch_metric_alarm" "telephony-skilllevel-sfstg2main-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-telephony-skilllevel-sfstg2main-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.telephony-skilllevel-sfstg2main.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.telephony-skilllevel-sfstg2main.function_name} lambda function"

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-telephony-skilllevel-sfstg2main-${var.region_code}",
      "ApplicationSubject", "telephony"
    )
  )
}

#Role for all above lambdas
resource "aws_iam_role" "telephony-sfstg2main" {
  name = "${var.account_code}-${var.env}-iamrole-telephony-sfstg2main"

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
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-telephony-sfstg2main",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_iam_policy" "telephony-sfstg2main-lambda" {
  name   = "${var.account_code}-${var.env}-iampolicy-telephony-sfstg2main-lambda"
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
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-telephony-sfstg2main-lambda",
      "ApplicationSubject", "telephony"
    )
  )

}

resource "aws_iam_policy_attachment" "attachment-telephony-sfstg2main-lambda" {
  name       = "${var.account_code}-${var.env}-iampolicy-telephony-sfstg2main-attachment-lambda"
  policy_arn = aws_iam_policy.telephony-sfstg2main-lambda.arn
  roles      = [aws_iam_role.telephony-sfstg2main.name]
}