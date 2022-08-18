resource "aws_sns_topic" "s32sns-snstopic" {
  name = "${var.account_code}-${var.env}-snstopic-s32sns-${var.name}-${var.region_code}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:${var.account_code}-${var.env}-snstopic-s3sns2sftp-${var.name}-${var.region_code}",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:::${var.source_bucket}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "s32sns-s3copy" {
  name = "${var.account_code}-${var.env}-iamrole-s32sns-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s32sns-s3bucketaccess-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-s32sns-${var.name}s3bucketaccess"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": ["arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*"]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "s32sns-s3bucketaccess-attachment" {
  name = "${var.account_code}-${var.env}-iampolicy-s32sns-${var.name}s3bucketaccess-attachment"
  roles      = [aws_iam_role.s32sns-s3copy.name]
  policy_arn = aws_iam_policy.s32sns-s3bucketaccess-policy.arn
}

