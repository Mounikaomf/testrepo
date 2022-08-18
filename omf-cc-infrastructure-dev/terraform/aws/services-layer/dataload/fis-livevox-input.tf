resource "aws_glue_job" "fis-livevoxinput-raw2prepared" {
  name = "${var.account_code}-${var.env}-gluejob-fis-livevoxinput-${var.region_code}"
  role_arn     = aws_iam_role.fis-livevoxinput-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/livevoxinput/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "FIS_LIVEVOXINPUT_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--logging_table"       = "${var.account_code}-${var.env}-fis-livevoxinput-${var.region_code}"
    "--class"               = "GlueApp"
    "--config_bucket"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/LiveVoxInput"
    "--target_prefix"       = "prepared/LiveVoxInput"
    "--temporary_prefix"    = "temporary"
    "--version_glue"        = "${trimspace(data.aws_s3_bucket_object.omfeds-glue-latest.body)}"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--enable-auto-scaling" = "true"
    "--copybook_prefix"     = "appcode/glue/omfeds/livevoxinput/copybook"
    "--extra-jars"          = "s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/spark-cobol-assembly-2.4.11-SNAPSHOT.jar,s3://${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/glue/extra-jars/cobol-parser-assembly-2.4.11-SNAPSHOT.jar"
    
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-livevoxinput-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_glue_trigger" "fis-livevoxinput-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-livevoxinput-raw2prepared-${var.region_code}"
  schedule = "cron(30 10 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-livevoxinput-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-livevoxinput-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}

resource "aws_iam_role" "fis-livevoxinput-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-fis-livevoxinput-raw2prepared"

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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-fis-livevoxinput-raw2prepared",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy" "fis-livevoxinput-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-fis-livevoxinput-glue"
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
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*", "arn:aws:s3:::${var.account_code}-storage-dev-omfeds-s3-common-ue1-all-lambdas-all/*", "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"]
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-fis-livevoxinput-glue",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_iam_policy_attachment" "fis-livevoxinput-attachment-glue" {
  name = "${var.account_code}-${var.env}-iampolicy-fis-livevoxinput-attachment-glue"
  roles      = [aws_iam_role.fis-livevoxinput-glue-role.name]
  policy_arn = aws_iam_policy.fis-livevoxinput-glue-policy.arn
}

resource "aws_dynamodb_table" "fis-livevoxinput-table" {
  name           = "${var.account_code}-${var.env}-fis-livevoxinput-${var.region_code}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key       = "file_name"
  range_key = "processed_datetime"

  attribute {
    name = "file_name"
    type = "S"
  }
  attribute {
    name = "processed_datetime"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-fis-livevoxinput-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}