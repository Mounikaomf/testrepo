locals {
  onus_common_tags = {
    Application = "Onus"
    ApplicationSubject = "Onus"
  }
}

data "aws_ssm_parameter" "onus-sns-foreigner-account-id" {
  name = "/${var.account_code}/acc/ingestion/sqs/omfcards/accountid"
}

resource "aws_glue_job" "onus-s32sns" {
  name = "${var.account_code}-${var.env}-s32sns-onus-${var.region_code}"
  role_arn     = aws_iam_role.onus-s32sns-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "4"
  worker_type       = "G.2X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/s32sns.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "${var.account_code}-${var.env}-onus-s32sns-${var.region_code}"
    "--bucket"              = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
    "--source_prefix"       = "onus_data/out"
    "--sns_arn"             = aws_sns_topic.onus-glue2offload.arn
    "--config_bucket"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--config_key"          = "appcode/glue/omfeds/onus/onus_message_schema.json"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.onus_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-s32sns-onus-${var.region_code}"
    )
  )

}
resource "aws_glue_trigger" "onus-s32sns-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-onus-s32sns-${var.region_code}"
  schedule = "cron(0 03 ? * WED *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.onus-s32sns.name
  }

  tags = merge(
    local.onus_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-onus-s32sns-${var.region_code}"
    )
  )
}

resource "aws_sns_topic" "onus-glue2offload" {
  name = "${var.account_code}-${var.env}-onus-glue2offload-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_ssm_parameter.onus-sns-foreigner-account-id.value}"
      },
      "Action": [
                "SNS:Publish",
                "SNS:Subscribe"
                ],
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-onus-glue2offload-${var.region_code}"
    }
  ]
}
POLICY

  tags = merge(
    local.onus_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-onus-glue2offload-${var.region_code}"
    )
  )

}

resource "aws_ssm_parameter" "onus-glue2offload-sns-topicarn" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/onusglue2offload/topicarn"
  type = "String"
  value = aws_sns_topic.onus-glue2offload.arn
}

resource "aws_iam_role" "onus-s32sns-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-onus-s32sns"

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
    local.onus_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-onus-s32sns"
    )
  )

}

resource "aws_iam_policy" "onus-s32sns-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-onus-s32sns-glue"
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
            "Resource": ["arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all/*", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sns:*",
            "Resource": ["${aws_sns_topic.onus-glue2offload.arn}"]
        }
    ]
}
EOF

  tags = merge(
    local.onus_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-onus-s32sns-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "onus-s32sns-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-onus-s32sns-attachmentglue"
  roles      = [aws_iam_role.onus-s32sns-glue-role.name]
  policy_arn = aws_iam_policy.onus-s32sns-glue-policy.arn
}
