locals {
  bnf_common_tags = {
    Application = "BNF"
    ApplicationSubject = "BNF"
  }
}

module "bnf-dataload-sqs2s3" {
  source               = "../../modules/sqs2s3"
  account_code = var.account_code
  append_date = ""
  append_datetime = ""
  config_file = ""
  destination_bucket = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  destination_prefix = "BNF/TO-BE-PROCESSED"
  env = var.env
  name = "bnf-dataload"
  region_code = var.region_code
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-sns-dataload-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
  source_prefix_filter = "/prepared"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = local.bnf_common_tags
}

#s3sns2glue lambda
resource "aws_lambda_function" "bnf-s3sns2glue" {
  function_name = "${var.account_code}-${var.env}-lambda-bnf-s3sns2glue-${var.region_code}"
  role          = aws_iam_role.bnf-s3sns2glue.arn
  s3_bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  s3_key        = "appcode/lambda/omfeds_lambda_python_${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}.zip"
  handler       = "s3sns2glue.s3_to_sns_to_glue_trigger"
  memory_size   = 8096
  timeout       = 900
  runtime       = "python3.7"
  environment {
    variables = {
      APPEND_DATETIME       = false
      APPEND_DATE           = ""
      GLUE_JOB_NAME         = aws_glue_job.bnf-raw2prepared.name
    }
  }

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-lambda-bnf-s3sns2glue-${var.region_code}"
    )
  )

}

resource "aws_lambda_permission" "bnf-s3sns2glue-allows3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bnf-s3sns2glue.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
}

resource "aws_lambda_permission" "bnf-s3sns2glue-allowsns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bnf-s3sns2glue.arn
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-s3sns2glue-${var.region_code}"
}

resource "aws_sns_topic_subscription" "bnf-s3sns2glue-subscription" {
  topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-bnf-s3sns2glue-${var.region_code}"
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bnf-s3sns2glue.arn
  depends_on = [aws_lambda_function.bnf-s3sns2glue, aws_lambda_permission.bnf-s3sns2glue-allowsns]
}

resource "aws_iam_role" "bnf-s3sns2glue" {
  name = "${var.account_code}-${var.env}-iamrole-bnf-s3sns2glue"

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
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-bnf-s3sns2glue"
    )
  )

}

resource "aws_iam_role_policy" "bnf-s3sns2glue-lambda-sqs-policy" {
  name = "${var.account_code}-${var.env}-lambdasqs-bnf-s3sns2glue"
  role = "${aws_iam_role.bnf-s3sns2glue.id}"
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
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object*",
        "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}/*"]
    },
    {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "glue:*",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "bnf-s3sns2glue-lambda-alarm" {
  alarm_name          = "${var.account_code}-${var.env}-alarm-bnf-s3sns2glue-${var.region_code}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = "${aws_lambda_function.bnf-s3sns2glue.function_name}"
  }

  alarm_actions       = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-snstopic-failure-all-${var.region_code}"]

  alarm_description = "This metric monitors fails of ${aws_lambda_function.bnf-s3sns2glue.function_name} lambda function"

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-alarm-bnf-s3sns2glue-${var.region_code}"
    )
  )
}

#GlueJob for BNF
resource "aws_glue_job" "bnf-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-bnf-${var.region_code}"
  role_arn     = aws_iam_role.bnf-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "10"
  worker_type       = "G.2X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/bnf/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 10
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-bnf-${var.region_code}"
    "--JOB_NAME"            = "${var.account_code}-${var.env}-bnf-raw2prepared-${var.region_code}"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
    "--config_bucket"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/bnf"
    "--target_prefix"       = "prepared"
    "--config_key"          = "appcode/glue/omfeds/bnf/bnf_config.json"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-bnf-${var.region_code}"
    )
  )

}

# resource "aws_glue_trigger" "bnf-raw2prepared-schedule" {
#   name = "${var.account_code}-${var.env}-gluetrigger-bnf-raw2prepared-${var.region_code}"
#   schedule = "cron(30 6 * * ? *)"
#   type     = "SCHEDULED"

#   actions {
#     job_name = aws_glue_job.bnf-raw2prepared.name
#   }

#   tags = merge(
#     local.bnf_common_tags,
#     map(
#       "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-bnf-raw2prepared-${var.region_code}"
#     )
#   )
# }

resource "aws_iam_role" "bnf-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-bnf-raw2prepared"

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
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-bnf-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "bnf-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-bnf-raw2prepared-glue"
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
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all/*", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"]
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
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-bnf-raw2prepared-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "bnf-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-bnf-raw2prepared-attachmentglue"
  roles      = [aws_iam_role.bnf-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.bnf-raw2prepared-glue-policy.arn
}
