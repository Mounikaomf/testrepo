locals {
  customerview_common_tags = {
    Application = "CustomerView"
    ApplicationSubject = "CustomerView"
  }
}

module "customerview-dataload-s3sns2s3" {
  source               = "../../modules/s3sns2s3"
  name                 = "customerview-dataload"
  config_file          = ""
  destination_bucket   = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  source_bucket        = "${var.account_code}-${var.env}-s3-cc-customerview-con-${var.region_code}"
  account_code         = var.account_code
  env                  = var.env
  region_code          = var.region_code
  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date          = ""
  append_datetime      = false
  destination_prefix   = "CUSTOMERPAN/TO-BE-PROCESSED"
  source_prefix_filter = "/prepared"
  notification_filter_prefix = "prepared/"
  notification_filter_suffix = ".parquet"
  tags_var = local.customerview_common_tags
}

resource "aws_glue_job" "customerview-raw2prepared" {
  name              = "${var.account_code}-${var.env}-gluejob-customerview-raw2prepared"
  role_arn          = aws_iam_role.customerview-raw2prepared-role.arn
  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = "2"


  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/customerview/raw2prepared.py"
    python_version  = "3"
  }

  default_arguments = {
    # ... potentially other arguments ...

    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-customerview-con-${var.region_code}"
    "--target_prefix"       = "prepared"
    "--source_prefix"       = "raw"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.customerview_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-customerview-raw2prepared"
    )
  )
}

resource "aws_glue_trigger" "customerview-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-customerview-raw2prepared-${var.region_code}"
  schedule = "cron(0 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.customerview-raw2prepared.name
  }

  tags = merge(
    local.customerview_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-customerview-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "customerview-raw2prepared-role" {
  name = "${var.account_code}-${var.env}-iamrole-customerview-raw2prepared"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = merge(
    local.customerview_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-customerview-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "customerview-raw2prepared-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-customerview-raw2prepared"
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
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-customerview-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-customerview-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*"]
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
    local.customerview_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-customerview-raw2prepared"
    )
  )

}

resource "aws_iam_policy_attachment" "customerview-raw2prepared-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-customerview-raw2prepared-attachment"
  roles      = [aws_iam_role.customerview-raw2prepared-role.name]
  policy_arn = aws_iam_policy.customerview-raw2prepared-policy.arn
}
