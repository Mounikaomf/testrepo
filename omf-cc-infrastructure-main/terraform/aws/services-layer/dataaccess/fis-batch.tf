data "aws_ssm_parameter" "sqs2sftp-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "sqs2sftp-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "sqs2sftp-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

resource "aws_iam_role" "ecs-sqs2sftp-role" {
  name = "${var.account_code}-${var.env}-iamrole-ecs-sqs2sftp"

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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-ecs-sqs2sftp",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_iam_role_policy_attachment" "ecs-sqs2sftp-attachment" {
  role       = aws_iam_role.ecs-sqs2sftp-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-sqs2sftp-attach" {
  role       = aws_iam_role.ecs-sqs2sftp-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-sqs2sftp-policy.arn
}

resource "aws_iam_instance_profile" "ecs-sqs2sftp-profile" {
  name = "${var.account_code}-${var.env}-profile-ecs-sqs2sftp"
  role = aws_iam_role.ecs-sqs2sftp-role.name

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-profile-ecs-sqs2sftp",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

resource "aws_iam_role" "aws-batch-sqs2sftp-role" {
  name = "${var.account_code}-${var.env}-iamrole-batch-sqs2sftp"

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
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-batch-sqs2sftp",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

#Get access batch to parameter store
resource "aws_iam_policy" "aws-batch-ssm-sqs2sftp-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-batch-ssm-sqs2sftp"
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
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-batch-ssm-sqs2sftp",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_iam_role_policy_attachment" "aws-batch-sqs2sftp-attachment" {
  role       = aws_iam_role.aws-batch-sqs2sftp-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy_attachment" "aws-batch-sqs2sftp-attach" {
  role       = aws_iam_role.aws-batch-sqs2sftp-role.name
  policy_arn = aws_iam_policy.aws-batch-ssm-sqs2sftp-policy.arn
}

resource "aws_security_group" "batch-sqs2sftp" {
  name = "${var.account_code}-${var.env}-batch-sqs2sftp-${var.region_code}"
  description = "Allow batch outbound traffic"
  vpc_id      = data.aws_ssm_parameter.sqs2sftp-vpc-id.value

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
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-sqs2sftp-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )

}

resource "aws_launch_template" "launch-template-sqs2sftp" {
  name = "${var.account_code}-${var.env}-launch-template-sqs2sftp-${var.region_code}"

  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 250
      delete_on_termination = true
      volume_type = "gp2"
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
      "ApplicationComponent", "${var.account_code}-${var.env}-launch-template-sqs2sftp-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

#If you need to delete batch_compute_environment, delete batch_job_queue at first
resource "aws_batch_compute_environment" "batch-sqs2sftp" {
  compute_environment_name_prefix = "${var.account_code}-${var.env}-batch-sqs2sftp-${var.region_code}-"

  compute_resources {
    instance_role = aws_iam_instance_profile.ecs-sqs2sftp-profile.arn
    instance_type = ["optimal"]
    max_vcpus = 256
    min_vcpus = 0
    security_group_ids = [ aws_security_group.batch-sqs2sftp.id ]
    subnets = [ data.aws_ssm_parameter.sqs2sftp-private-subnet-0.value, data.aws_ssm_parameter.sqs2sftp-private-subnet-1.value ]
    type = "EC2"
    launch_template {
        launch_template_id = aws_launch_template.launch-template-sqs2sftp.id
        version = aws_launch_template.launch-template-sqs2sftp.latest_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  service_role = aws_iam_role.aws-batch-sqs2sftp-role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws-batch-sqs2sftp-attachment]

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-sqs2sftp-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

resource "aws_batch_job_queue" "batch-queue-sqs2sftp" {
  name     = "${var.account_code}-${var.env}-batch-queue-sqs2sftp-${var.region_code}"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.batch-sqs2sftp.arn,
  ]

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-queue-sqs2sftp-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

# Batch Job Definition
resource "aws_batch_job_definition" "batch-job-definition-sqs2sftp" {
  name = "${var.account_code}-${var.env}-batch-job-definition-sqs2sftp-${var.region_code}"
  type = "container"

  timeout {
      attempt_duration_seconds = 36000
  }

  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["python", "s3snsoperations.py"],
    "image": "jfafn.jfrog.io/${trimspace(data.aws_s3_bucket_object.omfeds-jfrog-latest.body)}",
    "memory": 32768,
    "vcpus": 16
}
CONTAINER_PROPERTIES

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-batch-job-definition-sqs2sftp-${var.region_code}",
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}