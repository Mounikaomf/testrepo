locals {
  gradmaint_common_tags = {
    Application = "Graduation"
    ApplicationSubject = "GraduationMaint"
  }
}

data "aws_ssm_parameter" "graduation-maintenance-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "graduation-maintenance-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "graduation-maintenance-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

data "aws_ssm_parameter" "graduation-maintenance-destination-path" {
  name = "/${var.account_code}/acc/exchange/gradmaint/destination"
}

module "graduation-maintenance" {
  source = "../../modules/sqs2batch"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "graduation-maintenance"
  region_code = var.region_code
  sftp_target_directory = data.aws_ssm_parameter.graduation-maintenance-destination-path.value
  sftp_target_hostname = "/${var.account_code}/acc/exchange/vgs/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/exchange/vgs/password"
  sftp_target_port = "/${var.account_code}/acc/exchange/vgs/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/exchange/vgs/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-graduation-maintenance-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-vgsexchange-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "graduationmaintenance/inout"
  job_name = aws_batch_compute_environment.batch-graduation-maintenance.compute_environment_name
  job_definition = aws_batch_job_definition.batch-job-definition-graduation-maintenance.name
  job_queue = aws_batch_job_queue.batch-queue-graduation-maintenance.name
  tags_var = local.gradmaint_common_tags
}

resource "aws_iam_role" "ecs-graduation-maintenance-role" {
  name = "${var.account_code}-${var.env}-iamrole-ecs-graduation-maintenance"

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
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-ecs-graduation-maintenance"
    )
  )

}

resource "aws_iam_role_policy_attachment" "ecs-graduation-maintenance-attachment" {
  role       = aws_iam_role.ecs-graduation-maintenance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-graduation-maintenance-attach" {
  role       = aws_iam_role.ecs-graduation-maintenance-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-graduation-maintenance-policy.arn
}

resource "aws_iam_instance_profile" "ecs-graduation-maintenance-profile" {
  name = "${var.account_code}-${var.env}-profile-ecs-graduation-maintenance"
  role = aws_iam_role.ecs-graduation-maintenance-role.name

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-profile-ecs-graduation-maintenance"
    )
  )
}

resource "aws_iam_role" "aws-batch-graduation-maintenance-role" {
  name = "${var.account_code}-${var.env}-iamrole-batch-graduation-maintenance"

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
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-batch-graduation-maintenance"
    )
  )
}

#Get access batch to parameter store
resource "aws_iam_policy" "aws-batch-ssm-graduation-maintenance-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-batch-ssm-graduation-maintenance"
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
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-batch-ssm-graduation-maintenance"
    )
  )
}

resource "aws_iam_role_policy_attachment" "aws-batch-graduation-maintenance-attachment" {
  role       = aws_iam_role.aws-batch-graduation-maintenance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy_attachment" "aws-batch-graduation-maintenance-attach" {
  role       = aws_iam_role.aws-batch-graduation-maintenance-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-graduation-maintenance-policy.arn
}

resource "aws_security_group" "batch-graduation-maintenance" {
  name = "${var.account_code}-${var.env}-batch-graduation-maintenance-${var.region_code}"
  description = "Allow batch outbound traffic"
  vpc_id      = data.aws_ssm_parameter.graduation-maintenance-vpc-id.value

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-graduation-maintenance-${var.region_code}"
    )
  )
}

resource "aws_launch_template" "launch-template-graduation-maintenance" {
  name = "${var.account_code}-${var.env}-launch-template-graduation-maintenance-${var.region_code}"

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

    tags = local.gradmaint_common_tags
  }

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-launch-template-graduation-maintenance-${var.region_code}"
    )
  )

}

#If you need to delete batch_compute_environment, delete batch_job_queue at first
resource "aws_batch_compute_environment" "batch-graduation-maintenance" {
  compute_environment_name_prefix = "${var.account_code}-${var.env}-batch-graduation-maintenance-${var.region_code}-"

  compute_resources {
    instance_role = aws_iam_instance_profile.ecs-graduation-maintenance-profile.arn
    instance_type = ["optimal"]
    max_vcpus = 256
    min_vcpus = 0
    security_group_ids = [ aws_security_group.batch-graduation-maintenance.id ]
    subnets = [ data.aws_ssm_parameter.graduation-maintenance-private-subnet-0.value, data.aws_ssm_parameter.graduation-maintenance-private-subnet-1.value ]
    type = "EC2"
    launch_template {
        launch_template_id = aws_launch_template.launch-template-graduation-maintenance.id
        version = aws_launch_template.launch-template-graduation-maintenance.latest_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  service_role = aws_iam_role.aws-batch-graduation-maintenance-role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws-batch-graduation-maintenance-attachment]

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-graduation-maintenance-${var.region_code}"
    )
  )
}

resource "aws_batch_job_queue" "batch-queue-graduation-maintenance" {
  name     = "${var.account_code}-${var.env}-batch-queue-graduation-maintenance-${var.region_code}"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.batch-graduation-maintenance.arn,
  ]

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-queue-graduation-maintenance-${var.region_code}"
    )
  )
}

# Batch Job Definition
resource "aws_batch_job_definition" "batch-job-definition-graduation-maintenance" {
  name = "${var.account_code}-${var.env}-batch-job-definition-graduation-maintenance-${var.region_code}"
  type = "container"

  timeout {
      attempt_duration_seconds = 7200
  }

  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["python", "s3snsoperations.py"],
    "image": "jfafn.jfrog.io/${trimspace(data.aws_s3_bucket_object.omfeds-jfrog-latest.body)}",
    "memory": 8192,
    "vcpus": 2
}
CONTAINER_PROPERTIES

  retry_strategy {
    attempts = 3
  }

  tags = merge(
    local.gradmaint_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-job-definition-graduation-maintenance-${var.region_code}"
    )
  )
}