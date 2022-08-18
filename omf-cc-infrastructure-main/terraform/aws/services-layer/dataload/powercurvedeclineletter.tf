data "aws_ssm_parameter" "declineletter-powercurve-sns-name" {
  name = "/${var.account_code}/${var.env}/dataaccess/sns/declineletter/powercurve/name"
}

resource "aws_glue_job" "powercurve-declineleter-fromdb2raw-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-declineleter-fromdb2raw-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-declineleter-fromdb2raw-glue-role.arn
  glue_version      = "3.0"
  #Connection from powercurve.tf
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "5"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/declineletter/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--target_bucket"            = "${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}"
    "--target_prefix"            = "prepared/"
    "--config_path"              = "appcode/glue/omfeds/declineletter/config.yaml"
    "--feed_name"                = "declineletter"
    "--JOB_NAME"                 = "POWERCURVE_DECLINELETTER_GLUE_JOB"
    "--glue_connection_name"     = aws_glue_connection.powercurve-raw2prepared.name
    "--code_base_bucket"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--enable-auto-scaling"      = "true"
    "--look_back_days"             = "1"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-declineleter-fromdb2raw-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-declineleter-fromdb2raw-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-declineleter-fromdb2raw-${var.region_code}"
  schedule = "cron(30 10 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-declineleter-fromdb2raw-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-declineleter-fromdb2raw-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "powercurve-declineleter-fromdb2raw-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-powercurve-declineleter-fromdb2raw"

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
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-powercurve-declineleter-fromdb2raw"
    )
  )

}

resource "aws_iam_policy" "powercurve-declineleter-fromdb2raw-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-powercurve-declineleter-fromdb2raw-glue"
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
            "Action": ["s3:ListBucket"],
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}/*",
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
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-powercurve-declineleter-fromdb2raw-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "powercurve-declineleter-fromdb2raw-attachment-glue" {
  name = "${var.account_code}-${var.env}-iamrole-powercurve-declineleter-fromdb2raw-attachment-glue"
  roles      = [aws_iam_role.powercurve-declineleter-fromdb2raw-glue-role.name]
  policy_arn = aws_iam_policy.powercurve-declineleter-fromdb2raw-glue-policy.arn
}

#Lambda to copy from raw to exchange bucket
module "declineletter-dataload-sqs2s3" {
  source                = "../../modules/sqs2s3"
  name                  = "declineletter-dataload"
  account_code          = var.account_code
  env                   = var.env
  region_code           = var.region_code
  append_date           = ""
  append_datetime       = ""
  config_file           = ""
  destination_bucket    = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  destination_prefix    = "declineletter"
  snstopic_arn          = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${data.aws_ssm_parameter.declineletter-powercurve-sns-name.value}"
  source_bucket         = "${var.account_code}-${var.env}-s3-cc-declineletter-con-${var.region_code}"
  source_prefix_filter  = "/prepared"
  version_lambda        = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  tags_var = local.powercurve_common_tags
}