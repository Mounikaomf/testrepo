locals {
  equifax_common_tags = {
    Application = "Equifax"
    ApplicationSubject = "Equifax"
  }
}

resource "aws_s3_bucket_notification" "s3sns2s3-historical-equifax-notification" {
  bucket = "${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}"

  topic {
    topic_arn     = module.equifax-s3sns2s3.snstopic-arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "prepared/"
  }

  depends_on = [
    module.equifax-s3sns2s3
  ]

}

#Glue job 
resource "aws_glue_job" "equifax-raw2prepared-job" {
  name = "${var.account_code}-${var.env}-gluejob-equifax-${var.region_code}"
  role_arn     = aws_iam_role.equifax-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.2X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/equifax/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "EQUIFAX_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}"
    "--config_path"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/equifax/equifaxschema.txt"
    "--source_prefix"       = "raw"
    "--target_prefix"       = "prepared"
    "--temporary_prefix"    = "temporary"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--version_glue"        = "${trimspace(data.aws_s3_bucket_object.omfeds-glue-latest.body)}"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.equifax_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-equifax-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "equifax-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-equifax-raw2prepared-${var.region_code}"
  schedule = "cron(30 */1 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.equifax-raw2prepared-job.name
  }

  tags = merge(
    local.equifax_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-equifax-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "equifax-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-equifax-raw2prepared"

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
    local.equifax_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-equifax-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "equifax-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-equifax-raw2prepared-glue"
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
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", 
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}"
            ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}/*", 
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
    local.equifax_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-equifax-raw2prepared-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "equifax-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-equifax-raw2prepared-attachmentglue"
  roles      = [aws_iam_role.equifax-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.equifax-raw2prepared-glue-policy.arn
}

#Equifax s3sns2s3 prepared to exchange lambda
module "equifax-s3sns2s3" {
  source               = "../../modules/s3sns2s3-won"
  name                 = "equifax-dataload"
  config_file          = ""
  destination_bucket   = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  source_bucket        = "${var.account_code}-${var.env}-s3-cc-equifax-ingestion-con-${var.region_code}"
  account_code         = var.account_code
  env                  = var.env
  region_code          = var.region_code
  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date          = ""
  append_datetime      = false
  destination_prefix   = "equifax/in"
  source_prefix_filter = "/prepared"
  notification_filter_prefixes = ""
  notification_filter_suffix = ""
  tags_var = local.equifax_common_tags
}
