//resource "aws_iam_role" "sftp-user" {
//  name = "${var.iam-role-name}-${var.username}-sftp"
//
//  assume_role_policy = jsonencode({
//    Version = "2012-10-17"
//    Statement = [
//      {
//        Action = "sts:AssumeRole"
//        Effect = "Allow"
//        Sid    = ""
//        Principal = {
//          Service = "transfer.amazonaws.com"
//        }
//      },
//    ]
//  })
//  path = "/"
//
////  tags = var.tags
//}
//
//resource "aws_iam_role_policy" "sftp-user-s3fullaccess" {
//  name = "${var.iam-policy-name}-${var.username}-sftp-s3fullaccess"
//  role = aws_iam_role.sftp-user.id
//  policy = <<POLICY
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Sid": "AllowFullAccesstoS3",
//            "Effect": "Allow",
//            "Action": [
//              "s3:ListAllMyBuckets",
//              "s3:GetBucketLocation"
//            ],
//            "Resource": "*"
//        }
//    ]
//}
//POLICY
//}
//
//resource "aws_iam_role_policy" "sftp-user-AllowListingOfUserFolder" {
//  name = "${var.iam-policy-name}-${var.username}-sftp-AllowListingOfUserFolder"
//  role = aws_iam_role.sftp-user.id
//  policy = <<POLICY
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Sid": "AllowListingOfUserFolder",
//            "Effect": "Allow",
//            "Action": ["s3:ListBucket"],
//            "Resource": "${var.aws-s3-arn}"
//        }
//    ]
//}
//POLICY
//}
//
//resource "aws_iam_role_policy" "sftp-user-HomeDirObjectAccess" {
//  name = "${var.iam-policy-name}-${var.username}-sftp-HomeDirObjectAccess"
//  role = aws_iam_role.sftp-user.id
//  //var.path should include "username/*" for simple user access, or "*" for root user
//  policy = <<POLICY
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Sid": "HomeDirObjectAccess",
//            "Effect": "Allow",
//            "Action": [
//              "s3:PutObject",
//              "s3:GetObject",
//              "s3:GetObjectVersion",
//              "s3:DeleteObject",
//              "s3:DeleteObjectVersion"
//            ],
//            "Resource": "${var.aws-s3-arn}/${var.path}"
//        }
//    ]
//}
//POLICY
//}
//
//resource "aws_transfer_user" "sftp-user" {
//  server_id      = "${var.aws-sftp-id}"
//  user_name      = "${var.username}"
//  role           = "${aws_iam_role.sftp-user.arn}"
//  home_directory = format("/%s/%s", "${var.aws-s3-id}", "${var.username}/")
//
////  tags = var.tags
//}
//
//resource "aws_transfer_ssh_key" "sftp-user-public-key" {
//  server_id = "${var.aws-sftp-id}"
//  user_name = "${aws_transfer_user.sftp-user.user_name}"
//  body      = "${data.aws_ssm_parameter.sftp-user-public-key.value}"
//}
//
//resource "aws_ssm_parameter" "sftp-user-public-key" {
//  name  = "/omf/eds/base/sftp-datasource/${var.username}/public_key"
//  type  = "String"
//  value = "put your ssh here"
//  overwrite = false
//}
//
//data "aws_ssm_parameter" "sftp-user-public-key" {
//  name = "/omf/eds/base/sftp-datasource/${var.username}/public_key"
//  // using depends_on to exclude situation with right empty "aws_ssm_parameter" "sftp-user-public-key"
//  // in "aws_transfer_ssh_key" "sftp-user-public-key"
//  // see README.md
//  depends_on = [
//    aws_ssm_parameter.sftp-user-public-key,
//  ]
//}
