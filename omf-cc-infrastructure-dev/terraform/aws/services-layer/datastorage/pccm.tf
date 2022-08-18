//data "aws_ssm_parameter" "pccm-extract-file-vpc-id" {
//  name = "/${var.account_code}/acc/vpc/id"
//}
//
//data "aws_ssm_parameter" "pccm-extract-file-private-subnet-0" {
//  name = "/${var.account_code}/acc/vpc/subnets/private/0"
//}
//
//data "aws_ssm_parameter" "pccm-extract-file-private-subnet-1" {
//  name = "/${var.account_code}/acc/vpc/subnets/private/1"
//}
//
//module "pccm-extract-file-sqs2s3" {
//  source =    "../../modules/sqs2s3"
//
//  account_code = var.account_code
//  append_date = ""
//  append_datetime = ""
//  config_file = ""
//  destination_bucket = "${var.account_code}-${var.env}-s3-cc-pccm-integration-con-${var.region_code}"
//  destination_prefix = "pccm/extract_file_unload/out"
//  env = var.env
//  name = "pccm-extractfile"
//  region_code = var.region_code
//  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-acc-sfexchange-s32sns-${var.region_code}"
//  source_bucket = "${var.account_code}-${var.env}-acc-s3-cc-sfexchange-con-${var.region_code}"
//  source_prefix_filter = "pccm/extract_file_unload/out"
//  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
//}
//
//
//resource "aws_security_group" "pccm-fromsnowflake2s3" {
//  name        = "${var.account_code}-${var.env}-lambda-pccm-fromsnowflake2s3-${var.region_code}"
//  description = "Allow pccm-fromsnowflake2s3 outbound traffic"
//  vpc_id      = data.aws_ssm_parameter.pccm-extract-file-vpc-id.value
//  egress {
//    from_port        = 0
//    to_port          = 0
//    protocol         = "-1"
//    cidr_blocks      = ["0.0.0.0/0"]
//    ipv6_cidr_blocks = ["::/0"]
//  }
//}
//
//resource "aws_lambda_function" "pccm-extract-file-fromsnowflake2s3" {
//  function_name = "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-pccm-extractfile-${var.region_code}"
//  role          = aws_iam_role.pccm-extract-file-fromsnowflake2s3.arn
//  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
//  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
//  handler       = "snowflake_operations.snowflake_offload_procedure"
//  memory_size   = 4096
//  timeout       = 180
//  runtime       = "python3.7"
//  vpc_config {
//    subnet_ids         = [data.aws_ssm_parameter.pccm-extract-file-private-subnet-0.value, data.aws_ssm_parameter.pccm-extract-file-private-subnet-1.value]
//    security_group_ids = [aws_security_group.pccm-fromsnowflake2s3.id]
//  }
//  environment {
//    variables = {
//      DESTINATION_BUCKET               = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
//      DESTINATION_PREFIX               = "pccm/extract_file_unload/out/"
//      SQL_QUERIES_JSON_FILE            = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/sql_queries.json"
//      SQL_QUERY_USECASE                = "pccm_extract_file_unload_to_s3"
//      SSM_SNOWFLAKE_USER               = "/${var.account_code}/acc/datastorage/snowflake/user"
//      SSM_SNOWFLAKE_PASSWORD           = "/${var.account_code}/acc/datastorage/snowflake/password"
//      SSM_SNOWFLAKE_ACCOUNT_IDENTIFIER = "/${var.account_code}/acc/datastorage/snowflake/accound_id"
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
//resource "aws_cloudwatch_event_rule" "pccm-extract-file-lambda-cron" {
//  name                = "${var.account_code}-${var.env}-lambda-fromsnowflake2s3-pccmextractfile-${var.region_code}"
//  description         = "trigger for lambda fromsnowflake2s3 pccm-extract-file"
//  schedule_expression = "cron(0 6 * * ? *)"
//}
//
//resource "aws_cloudwatch_event_target" "pccm-extract-file-lambda-cron-target" {
//  rule = "${aws_cloudwatch_event_rule.pccm-extract-file-lambda-cron.name}"
//  target_id = "${aws_lambda_function.pccm-extract-file-fromsnowflake2s3.function_name}"
//  arn = "${aws_lambda_function.pccm-extract-file-fromsnowflake2s3.arn}"
//}
//
//resource "aws_lambda_permission" "pccm-allowcloudwatchevent-fromsnowflake2s3" {
//  statement_id  = "AllowCloudwatchEvent"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.pccm-extract-file-fromsnowflake2s3.arn
//  principal     = "events.amazonaws.com"
//  source_arn    = aws_cloudwatch_event_rule.pccm-extract-file-lambda-cron.arn
//}
//
//resource "aws_lambda_permission" "pccm-extract-file-allows3-fromsnowflake2s3" {
//  statement_id  = "AllowS3Bucket"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.pccm-extract-file-fromsnowflake2s3.arn
//  principal     = "s3.amazonaws.com"
//  source_arn    = "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
//}
//
//resource "aws_iam_role" "pccm-extract-file-fromsnowflake2s3" {
//  name = "${var.account_code}-${var.env}-iamrole-pccm-extract-file-fromsnowflake2s3"
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
//resource "aws_iam_policy" "pccm-extract-file-policy" {
//  name = "${var.account_code}-${var.env}-iampolicy-pccm-extract-file"
//  policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Effect": "Allow",
//            "Action": [
//                "glue:*",
//                "s3:GetBucketLocation",
//                "s3:ListBucket",
//                "s3:ListAllMyBuckets",
//                "s3:GetBucketAcl",
//                "ec2:DescribeVpcEndpoints",
//                "ec2:DescribeRouteTables",
//                "ec2:CreateNetworkInterface",
//                "ec2:DeleteNetworkInterface",
//                "ec2:DescribeNetworkInterfaces",
//                "ec2:DescribeSecurityGroups",
//                "ec2:DescribeSubnets",
//                "ec2:DescribeVpcAttribute",
//                "iam:ListRolePolicies",
//                "iam:GetRole",
//                "iam:GetRolePolicy",
//                "cloudwatch:PutMetricData"
//            ],
//            "Resource": [
//                "*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "s3:CreateBucket"
//            ],
//            "Resource": [
//                "arn:aws:s3:::aws-glue-*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "s3:GetObject",
//                "s3:PutObject",
//                "s3:DeleteObject"
//            ],
//            "Resource": [
//                "arn:aws:s3:::aws-glue-*/*",
//                "arn:aws:s3:::*/*aws-glue-*/*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "s3:GetObject"
//            ],
//            "Resource": [
//                "arn:aws:s3:::crawler-public*",
//                "arn:aws:s3:::aws-glue-*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "logs:CreateLogGroup",
//                "logs:CreateLogStream",
//                "logs:PutLogEvents",
//                "logs:AssociateKmsKey"
//            ],
//            "Resource": [
//                "arn:aws:logs:*:*:/aws-glue/*"
//            ]
//        },
//        {
//            "Effect": "Allow",
//            "Action": [
//                "ec2:CreateTags",
//                "ec2:DeleteTags"
//            ],
//            "Condition": {
//                "ForAllValues:StringEquals": {
//                    "aws:TagKeys": [
//                        "aws-glue-service-resource"
//                    ]
//                }
//            },
//            "Resource": [
//                "arn:aws:ec2:*:*:network-interface/*",
//                "arn:aws:ec2:*:*:security-group/*",
//                "arn:aws:ec2:*:*:instance/*"
//            ]
//        },
//        {
//          "Effect": "Allow",
//          "Action": [
//              "ssm:Describe*",
//              "ssm:Get*",
//              "ssm:List*"
//                ],
//          "Resource": "*"
//        },
//        {
//            "Effect": "Allow",
//            "Action": "s3:*",
//            "Resource": "*"
//        }
//    ]
//}
//EOF
//}
//
//resource "aws_iam_policy_attachment" "pccm-extract-file-attachment" {
//  name = "${var.account_code}-${var.env}-iampolicy-pccm-extract-file-fromsnowflake2s3"
//  roles      = [aws_iam_role.pccm-extract-file-fromsnowflake2s3.name]
//  policy_arn = aws_iam_policy.pccm-extract-file-policy.arn
//}
