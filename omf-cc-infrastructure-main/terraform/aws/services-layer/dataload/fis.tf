locals {
  fis_common_tags = {
    Application = "FIS"
  }
}

data "aws_ssm_parameter" "fis-destination-bucket" {
  name = "/${var.account_code}/acc/s3/cc/sfexchange/con"
}

data "aws_ssm_parameter" "fis-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "fis-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "fis-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

module "fis-dataload-s3sns2s3" {
  source               = "../../modules/sqs2s3"
  account_code = var.account_code
  append_date = ""
  append_datetime = ""
  config_file = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/fis_exchange_config.json"
  destination_bucket = data.aws_ssm_parameter.fis-destination-bucket.value
  destination_prefix = ""
  env = var.env
  name = "fis-dataload"
  region_code = var.region_code
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-sfexchange-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  source_prefix_filter = ""
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-customerview-raw2prepared",
      "ApplicationSubject", "FIS"
    )
  )
}


resource "aws_glue_job" "fis-paymentallocation-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-paymentallocation-${var.region_code}"
  role_arn     = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/fis/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-fis-paymentallocation-${var.region_code}"
    "--JOB_NAME"            = "FIS_PAYMENTALLOCATION_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--bucket_config"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/paymentallocation"
    "--target_prefix"       = "prepared/paymentallocation"
    "--copybook_prefix"     = "appcode/glue/omfeds/fis/paymentallocation/copybook"
    "--header_copybook_prefix" = "appcode/glue/omfeds/fis/paymentallocation/header-copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-paymentallocation-${var.region_code}",
      "ApplicationSubject", "FIS-PaymentAllocation"
    )
  )

}

resource "aws_glue_trigger" "fis-paymentallocation-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-paymentallocation-raw2prepared-${var.region_code}"
  schedule = "cron(30 9 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-paymentallocation-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-paymentallocation-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-PaymentAllocation"
    )
  )
}

resource "aws_glue_job" "fis-cardholder_plan-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-cardholder_plan-${var.region_code}"
  role_arn     = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/fis/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-fis-cardholder_plan-${var.region_code}"
    "--JOB_NAME"            = "FIS_CARDHOLDER_PLAN_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--bucket_config"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/cardholder_plan"
    "--target_prefix"       = "prepared/cardholder_plan"
    "--copybook_prefix"     = "appcode/glue/omfeds/fis/cardholder_plan/copybook"
    "--header_copybook_prefix" = "appcode/glue/omfeds/fis/cardholder_plan/header-copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-cardholder_plan-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderPlan"
    )
  )

}

resource "aws_glue_trigger" "fis-cardholder_plan-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-cardholder_plann-raw2prepared-${var.region_code}"
  schedule = "cron(30 9 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-cardholder_plan-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-cardholder_plann-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderPlan"
    )
  )
}

resource "aws_glue_job" "fis-nameaddress-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-nameaddress-${var.region_code}"
  role_arn     = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/fis/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-fis-nameaddress-${var.region_code}"
    "--JOB_NAME"            = "FIS_NAMEADDRESS_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--bucket_config"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/nameaddress"
    "--target_prefix"       = "prepared/nameaddress"
    "--copybook_prefix"     = "appcode/glue/omfeds/fis/nameaddress/copybook"
    "--header_copybook_prefix" = "appcode/glue/omfeds/fis/nameaddress/header-copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-nameaddress-${var.region_code}",
      "ApplicationSubject", "FIS-NameAddress"
    )
  )

}

resource "aws_glue_trigger" "fis-nameaddress-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-nameaddress-raw2prepared-${var.region_code}"
  schedule = "cron(30 9 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-nameaddress-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-nameaddress-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-NameAddress"
    )
  )
}

resource "aws_glue_job" "fis-posteditems-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-posteditems-${var.region_code}"
  role_arn     = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/fis/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-fis-posteditems-${var.region_code}"
    "--JOB_NAME"            = "FIS_POSTEDITEMS_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--bucket_config"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/posteditems"
    "--target_prefix"       = "prepared/posteditems"
    "--copybook_prefix"     = "appcode/glue/omfeds/fis/posteditems/copybook"
    "--header_copybook_prefix" = "appcode/glue/omfeds/fis/posteditems/header-copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-posteditems-${var.region_code}",
      "ApplicationSubject", "FIS-PostedItems"
    )
  )

}

resource "aws_glue_trigger" "fis-posteditems-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-posteditems-raw2prepared-${var.region_code}"
  schedule = "cron(30 9 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-posteditems-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-posteditems-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-PostedItems"
    )
  )
}

resource "aws_glue_job"  "fis-cardholder_master-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-cardholder_master-${var.region_code}"
  role_arn     = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/fis/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-fis-cardholder_master-${var.region_code}"
    "--JOB_NAME"            = "FIS_CARDHOLDER_MASTER_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--bucket_config"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/cardholder_master"
    "--target_prefix"       = "prepared/cardholder_master"
    "--copybook_prefix"     = "appcode/glue/omfeds/fis/cardholder_master/copybook"
    "--header_copybook_prefix" = "appcode/glue/omfeds/fis/cardholder_master/header-copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-cardholder_master-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_glue_trigger" "fis-cardholder_master-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-cardholder_master-raw2prepared-${var.region_code}"
  schedule = "cron(30 9 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-cardholder_master-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-cardholder_master-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

//resource "aws_sqs_queue" "fis-stepfunction" {
//  name                      = "${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//  delay_seconds             = 90
//  max_message_size          = 2048
//  message_retention_seconds = 86400
//  receive_wait_time_seconds = 10
//  visibility_timeout_seconds = 900
//  policy = <<EOF
//{
//  "Version":"2012-10-17",
//  "Id": "sqspolicy",
//  "Statement":[
//    {
//      "Sid":"sqs2s3",
//      "Effect":"Allow",
//      "Principal":"*",
//      "Action":"sqs:SendMessage",
//      "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}",
//      "Condition":{
//        "ArnEquals":{
//          "aws:SourceArn":"arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//        }
//      }
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_sqs_queue_policy" "fis-stepfunction-policy" {
//  queue_url = aws_sqs_queue.fis-stepfunction.id
//  policy = <<POLICY
//{
//  "Version": "2012-10-17",
//  "Id": "sqspolicy",
//  "Statement": [
//    {
//      "Sid": "sqs2s3",
//      "Effect": "Allow",
//      "Principal": "*",
//      "Action": "sqs:SendMessage",
//      "Resource": "${aws_sqs_queue.fis-stepfunction.arn}",
//      "Condition": {
//        "ArnEquals": {
//          "aws:SourceArn": "arn:aws:sns:*:*:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//        }
//      }
//    }
//  ]
//}
//POLICY
//}
//
//resource "aws_lambda_permission" "fis-stepfunction-allowsns" {
//  statement_id  = "AllowExecutionFromSNS"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.fis-stepfunction.arn
//  principal     = "sns.amazonaws.com"
//  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//}
//
//resource "aws_sns_topic_subscription" "fis-stepfunction-subscription" {
//  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-stepfunction-${var.region_code}"
//  protocol  = "sqs"
//  endpoint  = aws_sqs_queue.fis-stepfunction.arn
//  depends_on = [aws_lambda_function.fis-stepfunction, aws_lambda_permission.fis-stepfunction-allowsns]
//}
//
//resource "aws_lambda_function" "fis-stepfunction" {
//  function_name = "${var.account_code}-${var.env}-lambda-stepfunction-fis-${var.region_code}"
//  role          = aws_iam_role.fis-lambda4stepfunction.arn
//  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
//  handler       = "s3snsoperations.convert_parameters_trigger_stepfunction"
//  memory_size   = 8096
//  timeout       = 900
//  runtime       = "python3.7"
//  environment {
//    variables = {
//      AWS_REGION_CUSTOM      = var.region_code
//      ENVIRONMENT            = var.env
//      ACCOUNT                = var.account_code
//      CONFIG_BUCKET          = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//      CONFIG_KEY             = "appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/fis_stepfunction_config.json"
//    }
//  }
//  tags = {
//    Creator = "omf eds devops team"
//  }
//}
//
//resource "aws_lambda_event_source_mapping" "fis-stepfunction-lambda-trigger" {
//  event_source_arn = aws_sqs_queue.fis-stepfunction.arn
//  function_name    = aws_lambda_function.fis-stepfunction.arn
//  batch_size = 1
//}
//
//resource "aws_lambda_function" "fis-prep2exchange-stepfunction" {
//  function_name = "${var.account_code}-${var.env}-lambda-prep2exchange-stepfunction-fis-${var.region_code}"
//  role          = aws_iam_role.fis-lambda4stepfunction.arn
//  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
//  handler       = "s3snsoperations.s3_copy_folder_to_s3"
//  memory_size   = 8096
//  timeout       = 900
//  runtime       = "python3.7"
//  environment {
//    variables = {
//      DESTINATION_BUCKET    = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
//    }
//  }
//  tags = {
//    Creator = "omf eds devops team"
//  }
//}
//
//resource "aws_security_group" "fis-load2snowflake" {
//  name        = "${var.account_code}-${var.env}-lambda-fis-load2snowflake-${var.region_code}"
//  description = "Allow fis-load2snowflake outbound traffic"
//  vpc_id      = data.aws_ssm_parameter.fis-vpc-id.value
//  egress {
//    from_port        = 0
//    to_port          = 0
//    protocol         = "-1"
//    cidr_blocks      = ["0.0.0.0/0"]
//    ipv6_cidr_blocks = ["::/0"]
//  }
//}
//
//resource "aws_lambda_function" "fis-load2snowflake" {
//  function_name = "${var.account_code}-${var.env}-lambda-load2snowflake-fis-${var.region_code}"
//  role          = aws_iam_role.fis-lambda4stepfunction.arn
//  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
//  handler       = "snowflake_operations.execute_procedure"
//  memory_size   = 8096
//  timeout       = 900
//  runtime       = "python3.7"
//  vpc_config {
//    subnet_ids         = [data.aws_ssm_parameter.fis-private-subnet-0.value, data.aws_ssm_parameter.fis-private-subnet-1.value]
//    security_group_ids = [aws_security_group.fis-load2snowflake.id]
//  }
//  environment {
//    variables = {
//      SSM_SNOWFLAKE_USER               = "/${var.account_code}/acc/datastorage/snowflake/user"
//      SSM_SNOWFLAKE_PASSWORD           = "/${var.account_code}/acc/datastorage/snowflake/password"
//      SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER = "/${var.account_code}/acc/datastorage/snowflake/accound_id"
//      SSM_SNOWFLAKE_WAREHOUSE          = "/${var.account_code}/acc/datastorage/snowflake/warehouse"
//      SSM_SNOWFLAKE_ROLE               = "/${var.account_code}/acc/datastorage/snowflake/role"
//      SNOWFLAKE_SOURCE_DATABASE        = "CARDS"
//      SNOWFLAKE_SOURCE_SCHEMA          = "INGESTION_UTILS"
//      STORAGE_S3_INTEGRATION           = ""
//    }
//  }
//  tags = {
//    Creator = "omf eds devops team"
//  }
//}
//
//resource "aws_lambda_permission" "fis-allows3-load2snowflake" {
//  statement_id  = "AllowS3Bucket"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.fis-load2snowflake.arn
//  principal     = "s3.amazonaws.com"
//  source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con--con-${var.region_code}"
//}

resource "aws_iam_role" "fis-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-fis-raw2prepared"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-fis-raw2prepared",
      "ApplicationSubject", "FIS"
    )
  )

}

resource "aws_iam_policy" "fis-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-fis-raw2prepared-glue"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:*",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListAllMyBuckets",
                "s3:GetBucketAcl",
                "ec2:DescribeVpcEndpoints",
                "ec2:DescribeRouteTables",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcAttribute",
                "iam:ListRolePolicies",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket"
            ],
            "Resource": [
                "arn:aws:s3:::aws-glue-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::aws-glue-*/*",
                "arn:aws:s3:::*/*aws-glue-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::crawler-public*",
                "arn:aws:s3:::aws-glue-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:AssociateKmsKey"
            ],
            "Resource": [
                "arn:aws:logs:*:*:/aws-glue/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "aws-glue-service-resource"
                    ]
                }
            },
            "Resource": [
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:instance/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all/*", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"]
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
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-fis-raw2prepared-glue",
      "ApplicationSubject", "FIS"
    )
  )

}

resource "aws_iam_policy_attachment" "fis-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-fis-raw2prepared-attachmentglue"
  roles      = [aws_iam_role.fis-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.fis-raw2prepared-glue-policy.arn
}


//resource "aws_iam_role" "fis-lambda4stepfunction" {
//  name = "${var.account_code}-${var.env}-iamrole-fis-lambda4stepfunction"
//
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": "sts:AssumeRole",
//      "Principal": {
//        "Service": "lambda.amazonaws.com"
//      },
//      "Effect": "Allow",
//      "Sid": ""
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_policy" "fis-lambda4stepfunction" {
//  name   = "${var.account_code}-${var.env}-iampolicy-fis-lambda4stepfunction"
//  policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": [
//        "logs:CreateLogGroup",
//        "logs:CreateLogStream",
//        "logs:PutLogEvents"
//      ],
//      "Effect": "Allow",
//      "Resource": "arn:aws:logs:*:*:*"
//    },
//    {
//        "Sid": "ListObjectsInBucket",
//        "Effect": "Allow",
//        "Action": ["s3:ListBucket"],
//        "Resource": [
//          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
//          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
//        ]
//    },
//    {
//        "Sid": "AllObjectActions",
//        "Effect": "Allow",
//        "Action": "s3:*Object*",
//        "Resource": [
//          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",
//          "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}/*"
//        ]
//    },
//    {
//        "Effect": "Allow",
//        "Action": "s3:*",
//        "Resource": "*"
//    },
//    {
//      "Effect": "Allow",
//      "Action": [
//          "ssm:Describe*",
//          "ssm:Get*",
//          "ssm:List*"
//            ],
//      "Resource": "*"
//    },
//    {
//      "Sid": "VisualEditor0",
//      "Effect": "Allow",
//      "Action": "ec2:*",
//      "Resource": "*"
//    },
//    {
//      "Action": [
//          "sqs:*"
//      ],
//      "Effect": "Allow",
//      "Resource": "*"
//    },
//    {
//            "Effect": "Allow",
//            "Action": "states:*",
//            "Resource": "*"
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_policy_attachment" "fis-attachment-lambda4stepfunction" {
//  name       = "${var.account_code}-${var.env}-iampolicy-stepfunction-fisattachmentlambda"
//  policy_arn = aws_iam_policy.fis-lambda4stepfunction.arn
//  roles      = [aws_iam_role.fis-lambda4stepfunction.name]
//}
