locals {
  luminate_common_tags = {
    Application = "Luminate"
    ApplicationSubject = "Luminate"
  }
}

resource "aws_glue_trigger" "luminate-sf2products-schedule" {
  name     = "${var.account_code}-${var.env}-gluetrigger-luminate-sf2products-${var.region_code}"
  schedule = "cron(30 13 * * ? *)"

  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.luminate-sf2products.name
  }

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-luminate-sf2products-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "luminate-sf2products" {
  name              = "${var.account_code}-${var.env}-gluejob-sf2products-luminate-${var.region_code}"
  role_arn          = aws_iam_role.luminate-sf2products-glue-role.arn
  glue_version      = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"


  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/luminate/exchange2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"              = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
    "--config_bucket"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--config_key"          = "appcode/glue/omfeds/luminate/luminate_config.json"
    "--source_prefix"       = "fraud_hot_file_report/out"
    "--target_bucket"       = "${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}"
    "--target_prefix"       = "fraud_hot_file_request_data/out"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--JOB_NAME"            = "${var.account_code}-${var.env}-gluejob-sf2products-luminate-${var.region_code}"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-sf2products-luminate-${var.region_code}"
    )
  )

}

resource "aws_iam_role" "luminate-sf2products-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-luminate-sf2products"

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
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-luminate-sf2products"
    )
  )

}

resource "aws_iam_policy" "luminate-sf2products-glue-policy" {
  name   = "${var.account_code}-${var.env}-iampolicy-luminate-sf2products-glue"
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
                "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
              ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
                "arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-luminate-con-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*"
               ]
        }
    ]
}
EOF

  tags = merge(
    local.luminate_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-luminate-sf2products-glue"
    )
  )
}

resource "aws_iam_policy_attachment" "luminate-sf2products-attachment-glue" {
  name       = "${var.account_code}-${var.env}-iampolicy-luminate-sf2products-attachmentglue"
  roles      = [aws_iam_role.luminate-sf2products-glue-role.name]
  policy_arn = aws_iam_policy.luminate-sf2products-glue-policy.arn
}
