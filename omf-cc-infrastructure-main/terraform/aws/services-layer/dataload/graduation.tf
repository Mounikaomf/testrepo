locals {
  graduation_apr_common_tags = {
    Application = "Graduation"
    ApplicationSubject = "GraduationAprCli"
  }
}

#s3 prepared to s3 exchange bucket lambda
module "graduation-dataload-sqs2s3" {
  source                = "../../modules/sqs2s3"
  account_code          = var.account_code
  append_date           = ""
  append_datetime       = ""
  config_file           = ""
  destination_bucket    = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  destination_prefix    = "graduation/in"
  env                   = var.env
  name                  = "graduation-dataload"
  region_code           = var.region_code
  snstopic_arn          = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-graduation-s32sns-${var.region_code}"
  source_bucket         = "${var.account_code}-${var.env}-s3-cc-graduation-ingestion-con-${var.region_code}"
  source_prefix_filter  = "/prepared"
  version_lambda        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = local.graduation_apr_common_tags
}

#Creating Glue job raw2prepared graduation
resource "aws_glue_job" "graduation-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-graduation-${var.region_code}"
  role_arn     = aws_iam_role.graduation-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/graduation/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "GRADUATION_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-graduation-ingestion-con-${var.region_code}"
    "--config_path"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/graduation/graduationschema.txt"
    "--source_prefix"       = "raw"
    "--target_prefix"       = "prepared"
    "--temporary_prefix"    = "temporary"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--TempDir"             = "s3://${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/graduation/application"
    "--version_glue"        = "${trimspace(data.aws_s3_bucket_object.omfeds-glue-latest.body)}"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.graduation_apr_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-graduation-${var.region_code}"
    )
  )

}

resource "aws_glue_trigger" "graduation-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-graduation-raw2prepared-${var.region_code}"
  schedule = "cron(30 0 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.graduation-raw2prepared.name
  }

  tags = merge(
    local.graduation_apr_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-graduation-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "graduation-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-graduation-raw2prepared"

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
    local.graduation_apr_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-graduation-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "graduation-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-graduation-raw2prepared-glue"
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
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-graduation-ingestion-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-graduation-ingestion-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all/*", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"]
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
    local.graduation_apr_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-graduation-raw2prepared-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "graduation-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-graduation-raw2prepared-attachmentglue"
  roles      = [aws_iam_role.graduation-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.graduation-raw2prepared-glue-policy.arn
}
 