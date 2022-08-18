//data "aws_ssm_parameter" "pccm-destination-bucket" {
//  name = "/${var.account_code}/acc/s3/cc/sfexchange/con"
//}
//
//module "pccm-dataload-s3sns2s3" {
//  source                     = "../../modules/s3sns2s3"
//  name                       = "pccm-dataload"
//  config_file                = ""
//  destination_bucket         = data.aws_ssm_parameter.pccm-destination-bucket.value
//  source_bucket              = "${var.account_code}-${var.env}-s3-cc-pccm-con-${var.region_code}"
//  account_code               = var.account_code
//  env                        = var.env
//  region_code                = var.region_code
//  version_lambda             = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
//  append_date                = ""
//  append_datetime            = ""
//  destination_prefix         = ""
//  source_prefix_filter       = ""
//  notification_filter_prefix = ""
//  notification_filter_suffix = ""
//}
//
//resource "aws_glue_job" "pccm-feedback-raw2prepared" {
//  name              = "${var.account_code}-${var.env}-gluejob-pccm-feedback-${var.region_code}"
//  role_arn          = aws_iam_role.pccm-raw2prepared-role.arn
//  glue_version      = "2.0"
//  worker_type       = "Standard"
//  number_of_workers = "5"
//
//  command {
//    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/pccm/raw2prepared.py"
//    python_version = "3"
//  }
//
//  execution_property {
//    max_concurrent_runs = 1
//  }
//
//  default_arguments = {
//    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
//    "--TempDir"             = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/powercurve/feedback"
//    "--source_prefix"       = "raw/powercurve/feedback"
//    "--target_prefix"       = "prepared/powercurve/feedback"
//    "--aws_region"          = var.region_code
//    "--table"               = "PCCM_FEEDBACK"
//    "--config_path"         = "feedback_config.json"
//    "--job-bookmark-option" = "job-bookmark-enable"
//    "--JOB_NAME"            = "POWERCURVE_FEEDBACK_GLUE_JOB"
//  }
//
//}
//
//resource "aws_glue_job" "pccm-results-raw2prepared" {
//  name              = "${var.account_code}-${var.env}-gluejob-pccm-results-${var.region_code}"
//  role_arn          = aws_iam_role.pccm-raw2prepared-role.arn
//  glue_version      = "2.0"
//  worker_type       = "Standard"
//  number_of_workers = "5"
//
//  command {
//    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/pccm/raw2prepared.py"
//    python_version  = "3"
//  }
//
//  execution_property {
//    max_concurrent_runs = 1
//  }
//
//  default_arguments = {
//    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
//    "--TempDir"             = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/powercurve/results"
//    "--source_prefix"       = "raw/powercurve/results"
//    "--target_prefix"       = "prepared/powercurve/results"
//    "--table"               = "PCCM_RESULTS"
//    "--config_path"         = "results_config.json"
//    "--job-bookmark-option" = "job-bookmark-enable"
//    "--JOB_NAME"            = "POWERCURVE_RESULTS_GLUE_JOB"
//  }
//
//}
//
//resource "aws_iam_role" "pccm-raw2prepared-role" {
//  name = "${var.account_code}-${var.env}-iamrole-pccm-raw2prepared"
//
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": "sts:AssumeRole",
//      "Principal": {
//        "Service": "glue.amazonaws.com"
//      },
//      "Effect": "Allow",
//      "Sid": ""
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_policy" "pccm-raw2prepared-policy" {
//  name = "${var.account_code}-${var.env}-iampolicy-pccm-raw2prepared"
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
//resource "aws_iam_policy_attachment" "pccm-raw2prepared-attachment" {
//  name = "${var.account_code}-${var.env}-iampolicy-pccm-raw2prepared-attachment"
//  roles      = [aws_iam_role.pccm-raw2prepared-role.name]
//  policy_arn = aws_iam_policy.pccm-raw2prepared-policy.arn
//}
