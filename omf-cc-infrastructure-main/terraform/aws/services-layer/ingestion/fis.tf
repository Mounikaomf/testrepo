data "aws_ssm_parameter" "batch-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "batch-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "batch-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

locals {
  notification_filter_prefixes = [
   "fisvgs/Account+Maintenance+batch+file/",
   "fisvgs/Analytix+Reports/",
   "fisvgs/BOSH+reports/", 
   "fisvgs/eReports/",
   "fisvgs/GU090D/", 
   "fisvgs/GU011D/", 
   "fisvgs/GU045D/", 
   "fisvgs/GU052D/",
   "fisvgs/GU050D/",
   "fisvgs/FOS+statement+index+file/",
   "fisvgs/WebBank+settlement+file/"
  ]
  fis_common_tags = {
    Application = "FIS"
  }
}

module "fis-trailer-s3sns2batch" {
  source               = "../../modules/s3sns2batchtrailer"
  destination_bucket   = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  source_bucket = "${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}"
  config_file          = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/fis_raw_config.json"
  account_code = var.account_code
  env = var.env
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  region_code = var.region_code
  name = "fis-gu010d"
  source_filter_prefix = "fisvgs/GU010D"
  destination_prefix = "raw/cardholder_master"
  append_datetime = ""
  append_date     = ""
  job_name = aws_batch_compute_environment.batch-fis-trailer.compute_environment_name
  job_definition = aws_batch_job_definition.batch-job-definition-fis-trailer.name
  job_queue = aws_batch_job_queue.batch-queue-fis-trailer.name
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

module "fis-s3sns2s3" {
  source               = "../../modules/s3sns2s3-won"
  name                 = "fis-ingestion"
  config_file          = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/fis_raw_config.json"
  destination_bucket   = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  source_bucket        = "${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}"
  account_code         = var.account_code
  env                  = var.env
  region_code          = var.region_code
  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date          = ""
  append_datetime      = ""
  destination_prefix   = ""
  source_prefix_filter = ""
  notification_filter_prefixes = ""
  notification_filter_suffix = ""
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS"
    )
  )
}

resource "aws_s3_bucket_notification" "s3sns2s3-fis-notification" {
  bucket = "${var.account_code}-acc-s3-ingestion-sftpfisvgs-con-${var.region_code}"

  dynamic "topic" {
    for_each = local.notification_filter_prefixes
    content {
      topic_arn     = module.fis-s3sns2s3.snstopic-arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = topic.value
    }
  }

  topic {
    topic_arn     = module.fis-trailer-s3sns2batch.snstopic-arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "fisvgs/GU010D/"
  }

  topic {
    topic_arn     = aws_sns_topic.s3sns2s3-telephony-snstopic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "fisvgs/Telephony/"
  }

  topic {
    topic_arn     = aws_sns_topic.s3sns2s3-fis-collections-snstopic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "fisvgs/Collections/"
  }

  depends_on = [
    module.fis-trailer-s3sns2batch,
    module.fis-s3sns2s3,
    aws_sns_topic.s3sns2s3-telephony-snstopic,
    aws_sns_topic.s3sns2s3-fis-collections-snstopic
  ]
}


#Batch
resource "aws_iam_role" "ecs-fis-trailer-role" {
  name = "${var.account_code}-${var.env}-iamrole-ecs-fis-trailer"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-ecs-fis-trailer",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

resource "aws_iam_role_policy_attachment" "ecs-fis-trailer-attachment" {
  role       = aws_iam_role.ecs-fis-trailer-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-fis-trailer-ssm-attachment" {
  role       = aws_iam_role.ecs-fis-trailer-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-fis-trailer-policy.arn
}

resource "aws_iam_instance_profile" "ecs-fis-trailer-profile" {
  name = "${var.account_code}-${var.env}-profile-ecs-fis-trailer"
  role = aws_iam_role.ecs-fis-trailer-role.name
}

resource "aws_iam_role" "aws-batch-fis-trailer-role" {
  name = "${var.account_code}-${var.env}-iamrole-batch-fis-trailer"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "batch.amazonaws.com"
        }
    }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-batch-fis-trailer",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

#Get access batch to parameter store
resource "aws_iam_policy" "aws-batch-ssm-fis-trailer-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-batch-ssm-fis-trailer"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:List"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "s3:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "SNS:*",
            "Resource": [
              "arn:aws:sns:*:*:*"
            ]
        },
        {
          "Action": [
            "logs:*"
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-batch-ssm-fis-trailer",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_iam_role_policy_attachment" "aws-batch-fis-trailer-attachment" {
  role       = aws_iam_role.aws-batch-fis-trailer-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy_attachment" "aws-batch-fis-trailer-ssm-attachment" {
  role       = aws_iam_role.aws-batch-fis-trailer-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-fis-trailer-policy.arn
}

resource "aws_security_group" "batch-fis-trailer" {
  name = "${var.account_code}-${var.env}-batch-fis-trailer-${var.region_code}"
  description = "Allow batch outbound traffic"
  vpc_id      = data.aws_ssm_parameter.batch-vpc-id.value

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-fis-trailer-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

resource "aws_launch_template" "launch-template-fis-trailer" {
  name = "${var.account_code}-${var.env}-launch-template-fis-trailer-${var.region_code}"

  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 250
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("../../../batch/launch_template.tftpl", { user = "/${var.account_code}/${var.env}/dataaccess/jfrog/username", pass = "/${var.account_code}/${var.env}/dataaccess/jfrog/password" }))

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.fis_common_tags,
      map(
        "ApplicationSubject", "FIS-CardholderMaster"
      )
    )
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-launch-template-fis-trailer-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

#If you need to delete batch_compute_environment, delete batch_job_queue at first
resource "aws_batch_compute_environment" "batch-fis-trailer" {
  compute_environment_name_prefix = "${var.account_code}-${var.env}-batch-fis-trailer-${var.region_code}-"

  compute_resources {
    instance_role = aws_iam_instance_profile.ecs-fis-trailer-profile.arn
    instance_type = ["optimal"]
    security_group_ids = [ aws_security_group.batch-fis-trailer.id ]
    subnets = [ data.aws_ssm_parameter.batch-private-subnet-0.value, data.aws_ssm_parameter.batch-private-subnet-1.value ]
    max_vcpus = 256
    min_vcpus = 0
    type = "EC2"
    launch_template {
        launch_template_id = aws_launch_template.launch-template-fis-trailer.id
        version = aws_launch_template.launch-template-fis-trailer.latest_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  service_role = aws_iam_role.aws-batch-fis-trailer-role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws-batch-fis-trailer-attachment]

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-fis-trailer-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_batch_job_queue" "batch-queue-fis-trailer" {
  name     = "${var.account_code}-${var.env}-batch-queue-fis-trailer-${var.region_code}"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.batch-fis-trailer.arn,
  ]

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-queue-fis-trailer-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

# Batch Job Definition
resource "aws_batch_job_definition" "batch-job-definition-fis-trailer" {
  name = "${var.account_code}-${var.env}-batch-job-definition-fis-trailer-${var.region_code}"
  type = "container"

  timeout {
      attempt_duration_seconds = 36000
  }

  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["python", "fisfilevalidation.py"],
    "image": "jfafn.jfrog.io/${trimspace(data.aws_s3_bucket_object.omfeds-jfrog-latest.body)}",
    "memory": 16384,
    "vcpus": 8
}
CONTAINER_PROPERTIES

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-job-definition-fis-trailer-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}
