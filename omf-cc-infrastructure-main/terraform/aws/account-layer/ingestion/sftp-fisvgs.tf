locals {
  fis_common_tags = {
    Application = "FIS"
    ApplicationSubject = "SFTP"
  }
}

resource "aws_transfer_server" "sftp-fisvgs" {
  endpoint_type = "PUBLIC"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-ingestion-sftp-fisvgs-${var.region_code}",
      "Name", "${var.account_code}-${var.env}-ingestion-sftp-fisvgs-${var.region_code}"
    )
  )

}

resource "aws_ssm_parameter" "sftp-fisvgs-url" {
  name  = "/${var.account_code}/${var.env}/ingestion/sftp/fisvgs/url"
  type  = "String"
  value = "${aws_transfer_server.sftp-fisvgs.endpoint}"
  overwrite = true
}

module "sftp-s3-fisvgs" {
  source = "../../modules/s3"
  account_code = var.account_code
  env = var.env
  domain = "ingestion"
  category = "sftpfisvgs"
  security_classification = "con"
  region = var.region_code
  tags_var = local.fis_common_tags
}

resource "aws_iam_role" "sftp-fisvgsuseraccess" {
  name = "${var.account_code}-${var.env}-iamrole-sftp-user"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      },
    ]
  })
  path = "/"

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-sftp-user"
    )
  )

}

resource "aws_iam_role_policy" "sftp-fisvgsuseraccess-s3fullaccess" {
  name = "${var.account_code}-${var.env}-iampolicy-sftp-s3fullaccess"
  role = aws_iam_role.sftp-fisvgsuseraccess.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFullAccesstoS3",
            "Effect": "Allow",
            "Action": [
              "s3:ListAllMyBuckets",
              "s3:GetBucketLocation"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy" "sftp-fisvgsuseraccess-AllowListingOfUserFolder" {
  name = "${var.account_code}-${var.env}-iampolicy-sftp-AllowListingOfUserFolder"
  role = aws_iam_role.sftp-fisvgsuseraccess.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListingOfUserFolder",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": "arn:aws:s3:::${var.account_code}-${var.env}-s3-ingestion-sftpfisvgs-con-${var.region_code}"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy" "sftp-fisvgsuseraccess-HomeDirObjectAccess" {
  name = "${var.account_code}-${var.env}-iampolicy-sftp-HomeDirObjectAccess"
  role = aws_iam_role.sftp-fisvgsuseraccess.id
  //var.path should include "username/*" for simple user access, or "*" for root user
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "HomeDirObjectAccess",
            "Effect": "Allow",
            "Action": [
              "s3:*"
            ],
            "Resource": "arn:aws:s3:::${var.account_code}-${var.env}-s3-ingestion-sftpfisvgs-con-${var.region_code}/fisvgs/*"
        }
    ]
}
POLICY
}

resource "aws_transfer_user" "sftp-user" {
  server_id      = "${aws_transfer_server.sftp-fisvgs.id}"
  user_name      = "fisvgs"
  role           = "${aws_iam_role.sftp-fisvgsuseraccess.arn}"
  home_directory = format("/%s/%s", "${var.account_code}-${var.env}-s3-ingestion-sftpfisvgs-con-${var.region_code}", "fisvgs/")

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "fisvgs"
    )
  )
}

resource "aws_transfer_ssh_key" "sftp-user-public-key" {
  server_id      = "${aws_transfer_server.sftp-fisvgs.id}"
  user_name = "${aws_transfer_user.sftp-user.user_name}"
  body      = "${data.aws_ssm_parameter.sftp-user-public-key-data.value}"
}

data "aws_ssm_parameter" "sftp-user-public-key-data" {
  name ="/${var.account_code}/${var.env}/ingestion/sftp/fisvgs/public_key"
  // using depends_on to exclude situation with right empty "aws_ssm_parameter" "sftp-user-public-key"
  // in "aws_transfer_ssh_key" "sftp-user-public-key"
  // see README.md
}
