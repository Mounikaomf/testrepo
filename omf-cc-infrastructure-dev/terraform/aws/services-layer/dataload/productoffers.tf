locals {
  productoffer_common_tags = {
    Application = "ProductOffers"
    ApplicationSubject = "ProductOffers"
  }
}

module "productoffers-dataload-s3sns2s3" {
  source                     = "../../modules/s3sns2s3"
  name                       = "productoffers-dataload"
  config_file                = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/productoffers_exchange_config.json"
  destination_bucket         =  "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  source_bucket              = "${var.account_code}-${var.env}-s3-cc-productoffers-con-${var.region_code}"
  account_code               = var.account_code
  env                        = var.env
  region_code                = var.region_code
  version_lambda             = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date                = ""
  append_datetime            = ""
  destination_prefix         = ""
  source_prefix_filter       = ""
  notification_filter_prefix = "prepared/"
  notification_filter_suffix = ".parquet"
  tags_var                   = local.productoffer_common_tags 
}

resource "aws_glue_crawler" "productoffers-data-catalog" {
  database_name = "${var.account_code}-${var.env}-datacatalog-productoffers-${var.region_code}"
  name          = "${var.account_code}-${var.env}-datacatalog-crawler-productoffers-${var.region_code}"
  role          = aws_iam_role.productoffers-raw2prepared-role.name
  table_prefix  = "product_offer_"
  schedule      = "cron(*/30 * * * ? *)"

  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
        TableLevelConfiguration = 2
      }
      Version = 1
    }
  )

  s3_target {
    path = "s3://${var.account_code}-storage-${var.env}-omfeds-s3-raw-${var.region_code}-all-offerdb-all/export"
  }

  tags = merge(
    local.productoffer_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-datacatalog-crawler-productoffers-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "productoffers-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-productoffers-${var.region_code}"
  role_arn          = aws_iam_role.productoffers-raw2prepared-role.arn
  glue_version      = "3.0"
  number_of_workers = "2"
  worker_type       = "G.2X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/productoffers/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-productoffers-con-${var.region_code}"
    "--source_prefix"       = "raw"
    "--target_prefix"       = "prepared"
    "--temporary_prefix"    = "temporary"
    "--config_path"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/productoffers/raw2prepared_config.json"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--TempDir"             = "s3://${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/productoffers/application"
    "--JOB_NAME"            = "PRODUCTOFFERS_GLUE_JOB"
    "--enable-auto-scaling" = "true"

  }

  tags = merge(
    local.productoffer_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-productoffers-${var.region_code}"
    )
  )

}

resource "aws_glue_trigger" "productoffers-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-productoffers-raw2prepared-${var.region_code}"
  schedule = "cron(0 * * * ? *)"
  type     = "SCHEDULED"
  actions {
    job_name = aws_glue_job.productoffers-raw2prepared-job.name
  }

  tags = merge(
    local.productoffer_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-productoffers-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "productoffers-raw2prepared-role" {
  name = "${var.account_code}-${var.env}-iamrole-productoffers-raw2prepared"

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
    local.productoffer_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-productoffers-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "productoffers-raw2prepared-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-productoffers-raw2prepared"
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
              "ssm:Describe*",
              "ssm:Get*",
              "ssm:List*"
                ],
          "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": [
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-productoffers-con-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-storage-uat-omfeds-s3-raw-${var.region_code}-all-offerdb-all"
              ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-productoffers-con-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-storage-uat-omfeds-s3-raw-${var.region_code}-all-offerdb-all/*"
               ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["kms:*"],
            "Resource": "*"
        }
    ]
}
EOF

  tags = merge(
    local.productoffer_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-productoffers-raw2prepared"
    )
  )

}

resource "aws_iam_policy_attachment" "productoffers-raw2prepared-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-productoffers-raw2prepared-attachment"
  roles      = [aws_iam_role.productoffers-raw2prepared-role.name]
  policy_arn = aws_iam_policy.productoffers-raw2prepared-policy.arn
}
