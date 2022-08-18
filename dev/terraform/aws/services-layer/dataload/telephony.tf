locals {
  telephony_common_tags = {
    Application = "Telephony"
    ApplicationSubject = "Telephony"
  }
}

#Glue Job
resource "aws_glue_job" "telephony-raw2prepared-job" {
  name = "${var.account_code}-${var.env}-gluejob-telephony-${var.region_code}"
  role_arn     = aws_iam_role.telephony-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/telephony/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "TELEPHONY_GLUE_JOB"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}"
    "--config_path"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/telephony/raw2prepared_config.json"
    "--class"               = "GlueApp"
    "--source_prefix"       = "raw/"
    "--target_prefix"       = "prepared"
    "--temporary_prefix"    = "temporary"
    "--TempDir"             = "s3://${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/telephony/application"
    "--version_glue"        = "${trimspace(data.aws_s3_bucket_object.omfeds-glue-latest.body)}"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-telephony-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "telephony-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-telephony-raw2prepared-${var.region_code}"
  schedule = "cron(0 */2 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.telephony-raw2prepared-job.name
  }

  tags = merge(
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-telephony-${var.region_code}",
      "ApplicationSubject", "Telephony"
    )
  )
}

resource "aws_iam_role" "telephony-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-telephony-raw2prepared"

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
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-telephony-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "telephony-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-telephony-raw2prepared-glue"
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
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}"
            ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}/*", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/*"
            ]
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
    local.telephony_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-telephony-raw2prepared-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "telephony-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-telephony-raw2prepared-attachment-glue"
  roles      = [aws_iam_role.telephony-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.telephony-raw2prepared-glue-policy.arn
}

#s3 prepared to s3 exchange bucket lambda
module "telephony-dataload-sqs2s3" {
  source                = "../../modules/sqs2s3"
  account_code          = var.account_code
  append_date           = ""
  append_datetime       = ""
  config_file           = ""
  destination_bucket    = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  destination_prefix    = "FIS/Telephony"
  env                   = var.env
  name                  = "telephony-dataload"
  region_code           = var.region_code
  snstopic_arn          = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-telephony-s32sns-${var.region_code}"
  source_bucket         = "${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}"
  source_prefix_filter  = "/prepared"
  version_lambda        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = local.telephony_common_tags
}

#Copy to exchange lambda
# May nedeed when we decide use copy lambda with different handler
# resource "aws_lambda_function" "sqs2s3-telephony-copy" {
#   function_name = "${var.account_code}-${var.env}-lambda-sqs2s3-telephony-dataload-${var.region_code}"
#   role          = aws_iam_role.sqs2s3-telephony-s3copy.arn
#   s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
#   s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
#   #TODO change handler
#   handler       = "s3snsoperations.ITSHOULDBECHANGED"
#   memory_size   = 8096
#   timeout       = 900
#   runtime       = "python3.7"
#   environment {
#     variables = {
#       TARGET_PREFIX         = "*"
#       DESTINATION_BUCKET    = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
#       aws_region            = "${var.region_code}"
#       SOURCE_PREFIX_FILTER  = "/prepared"
#       DESTINATION_PREFIX    = "telephony/TO-BE-PROCESSED"
#       VERSION_LAMBDA        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"

#     }
#   }

#   tags = merge(
#     local.telephony_common_tags,
#     map(
#       "ApplicationComponent", "${var.account_code}-${var.env}-lambda-sqs2s3-telephony-dataload-${var.region_code}"
#     )
#   )

# }

# resource "aws_lambda_permission" "sqs2s3-telephony-allows3" {
#   statement_id  = "AllowExecutionFromS3Bucket"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.sqs2s3-telephony-copy.arn
#   principal     = "s3.amazonaws.com"
#   source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}"
# }

# resource "aws_sqs_queue" "sqs2s3-telephony-sqs" {
#   name                      = "${var.account_code}-${var.env}-sqs2s3-telephony-dataload-${var.region_code}"
#   delay_seconds             = 90
#   max_message_size          = 2048
#   message_retention_seconds = 86400
#   receive_wait_time_seconds = 10
#   visibility_timeout_seconds = 900
#   policy = <<EOF
# {
#   "Version":"2012-10-17",
#   "Id": "sqspolicy",
#   "Statement":[
#     {
#       "Sid":"sqs2s3",
#       "Effect":"Allow",
#       "Principal":"*",
#       "Action":"sqs:SendMessage",
#       "Resource":"arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-sqs2s3-telephony-dataload-${var.region_code}",
#       "Condition":{
#         "ArnEquals":{
#           "aws:SourceArn":"arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-s3sns2s3-telephony-ingestion-${var.region_code}"
#         }
#       }
#     }
#   ]
# }
# EOF

#   tags = merge(
#     local.telephony_common_tags,
#     map(
#       "ApplicationComponent", "${var.account_code}-${var.env}-sqs2s3-telephony-dataload-${var.region_code}"
#     )
#   )

# }

# resource "aws_lambda_permission" "sqs2s3-telephony-allowsns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.sqs2s3-telephony-copy.arn
#   principal     = "sns.amazonaws.com"
#   source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-s3sns2s3-telephony-ingestion-${var.region_code}"
# }

# resource "aws_sns_topic_subscription" "sqs2s3-subscription" {
#   topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-s3sns2s3-telephony-ingestion-${var.region_code}"
#   protocol  = "sqs"
#   endpoint  = aws_sqs_queue.sqs2s3-telephony-sqs.arn
#   depends_on = [aws_lambda_function.sqs2s3-telephony-copy, aws_lambda_permission.sqs2s3-telephony-allowsns]
# }

# resource "aws_lambda_event_source_mapping" "sqs2s3-telephony-lambda-trigger" {
#   event_source_arn = aws_sqs_queue.sqs2s3-telephony-sqs.arn
#   function_name    = aws_lambda_function.sqs2s3-telephony-copy.arn
#   batch_size = 1
# }

# resource "aws_iam_role" "sqs2s3-telephony-s3copy" {
#   name = "${var.account_code}-${var.env}-iamrole-sqs2s3-telephony-dataload"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF

#   tags = merge(
#     local.telephony_common_tags,
#     map(
#       "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sqs2s3-telephony-dataload"
#     )
#   )

# }

# resource "aws_iam_policy" "sqs2s3-telephony-lambda" {
#   name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-telephony-dataload-lambda"
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents"
#       ],
#       "Effect": "Allow",
#       "Resource": "arn:aws:logs:*:*:*"
#     },
#     {
#         "Action": [
#             "sqs:*"
#         ],
#         "Effect": "Allow",
#         "Resource": "*"
#     },
#     {
#             "Sid": "ListObjectsInBucket",
#             "Effect": "Allow",
#             "Action": ["s3:ListBucket"],
#             "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"]
#     },
#     {
#             "Sid": "AllObjectActions",
#             "Effect": "Allow",
#             "Action": "s3:*Object*",
#             "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-telephony-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}/*"]
#     },
#     {
#             "Effect": "Allow",
#             "Action": "s3:*",
#             "Resource": "*"
#     },
#     {
#             "Action": [
#                 "sqs:ChangeMessageVisibility",
#                 "sqs:DeleteMessage",
#                 "sqs:GetQueueAttributes",
#                 "sqs:ReceiveMessage"
#             ],
#             "Effect": "Allow",
#             "Resource": "*"
#     },
#     {
#             "Effect": "Allow",
#             "Action": [
#                 "ssm:Describe*",
#                 "ssm:Get*",
#                 "ssm:List*"
#             ],
#             "Resource": "*"
#     }
#   ]
# }
# EOF

#   tags = merge(
#     local.telephony_common_tags,
#     map(
#       "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-s3sns2s3-telephony-dataload-lambda"
#     )
#   )
  
# }

# resource "aws_iam_policy_attachment" "sqs2s3-telephony-attachment-lambda" {
#   name = "${var.account_code}-${var.env}-iampolicy-s3sns2s3-telephony-dataload-attachmentlambda"
#   policy_arn = aws_iam_policy.sqs2s3-telephony-lambda.arn
#   roles = [aws_iam_role.sqs2s3-telephony-s3copy.name]
# }
