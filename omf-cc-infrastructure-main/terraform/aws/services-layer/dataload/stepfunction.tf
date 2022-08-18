//out of scope
//resource "aws_sfn_state_machine" "fis-stepfunction" {
//  name     = "${var.account_code}-${var.env}-fis-cardholder_master-stepfunction-cc-${var.region_code}"
//  role_arn = aws_iam_role.fis-stepfunction.arn
//  definition = templatefile(
//  "../../../stepfunction/fis/fis.tpl",
//  {
//    #glue part
//    job_name             = aws_glue_job.fis-cardholder_master-raw2prepared.name
//    bucket               = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
//    bucket_config        = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//    copybook_prefix      = "appcode/glue/omfeds/fis/cardholder_master/copybook"
//    header_copybook_prefix = "appcode/glue/omfeds/fis/cardholder_master/header-copybook"
//
//    #lambda part
//    prep2exchange_function_name     = "${var.account_code}-${var.env}-lambda-prep2exchange-stepfunction-fis-${var.region_code}"
//    target_bucket                   = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
//    sf_function_name                = "${var.account_code}-${var.env}-lambda-load2snowflake-fis-${var.region_code}"
//    sql_query_file                  = "CALL INGESTION_UTILS.SP_CR_LOAD_STAGE_TO_MAIN_USING_MAPPING('FIS','cards_stage', {0}, 'CARDS', 'FIS_STG', 'CARDHOLDER_MASTER', 'FIS_BASE', 'CARDHOLDER_MASTER', 'APPEND', '', '')"
//
//  }
//  )
//}
//
//resource "aws_iam_role" "fis-stepfunction" {
//  name = "${var.account_code}-${var.env}-iamrole-fis-stepfunction"
//  assume_role_policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Action": "sts:AssumeRole",
//            "Effect": "Allow",
//            "Sid": "",
//            "Principal": {
//                "Service": "states.amazonaws.com"
//            }
//        }
//    ]
//}
//  EOF
//}
//
//resource "aws_iam_policy" "fis-stepfunction" {
//  name = "${var.account_code}-${var.env}-iampolicy-fis-stepfunction"
//  policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Effect": "Allow",
//            "Action": [
//                "glue:*",
//                "s3:*",
//                "cloudwatch:*",
//                "dynamodb:*",
//                "lambda:*",
//                "eks:*",
//                "events:*",
//                "logs:*"
//            ],
//            "Resource": [
//                "*"
//            ]
//        }
//    ]
//}
//EOF
//}
//
//resource "aws_iam_policy_attachment" "fis-stepfunction" {
//  name = "${var.account_code}-${var.env}-pattach-fis-stepfunction"
//  roles      = [aws_iam_role.fis-stepfunction.name]
//  policy_arn = aws_iam_policy.fis-stepfunction.arn
//}
