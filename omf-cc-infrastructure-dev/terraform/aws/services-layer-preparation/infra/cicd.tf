module "cicd-s3-appcode" {
  source                  = "../../modules/s3"
  account_code            = var.account_code
  env                     = var.env
  domain                  = "cc-infra"
  category                = "appcode"
  security_classification = "ltd"
  region                  = var.region_code
  tags_var                = local.infra_common_tags
}

resource "aws_s3_bucket_object" "cicd-s3-lambda" {
  bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key        = "appcode/lambda/"
  content    = ""
  depends_on = [module.cicd-s3-appcode]
}

resource "aws_s3_bucket_object" "cicd-s3-glue" {
  bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key        = "appcode/glue/"
  content    = ""
  depends_on = [module.cicd-s3-appcode]
}

resource "aws_s3_bucket_object" "cicd-s3-sql" {
  bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key        = "appcode/sql/"
  content    = ""
  depends_on = [module.cicd-s3-appcode]
}

resource "aws_s3_bucket_object" "cicd-s3-jfrog-image" {
  bucket     = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key        = "appcode/jfrog-image/"
  content    = ""
  depends_on = [module.cicd-s3-appcode]
}

module "cicd-s3-temp" {
  source                  = "../../modules/s3"
  account_code            = var.account_code
  env                     = var.env
  domain                  = "cc-infra"
  category                = "temp"
  security_classification = "con"
  region                  = var.region_code
  tags_var                = local.infra_common_tags
}


#hardcoded values of Jenkins roles
resource "aws_iam_role" "cicd-jenkins-role" {
  name               = "${var.account_code}-${var.env}-iamrole-cc-infra-cicd-jenkins"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::014524682603:role/odop-cf-prod-jenkins-ue1-all-AgentIAMRole-1PFGKAX2ZB9FR",
          "arn:aws:iam::014524682603:role/odop-cf-prod-jenkins-ue1-all-MasterIAMRole-1VC99UC1OXJJZ"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(
    local.infra_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-cc-infra-cicd-jenkins"
    )
  )

}

resource "aws_iam_policy" "cicd-jenkins-policy" {
  name   = "${var.account_code}-${var.env}-iampolicy-cc-infra-cicd-jenkins"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "lambda:UpdateFunctionCode"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",
                "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": [
                "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
                "arn:aws:s3:::${var.account_code}-acc-s3-infra-storage-ltd-${var.region_code}"
            ]
        }
    ]
}
EOF

  tags = merge(
    local.infra_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-cc-infra-cicd-jenkins"
    )
  )

}

resource "aws_iam_policy_attachment" "cicd-jenkins-policy-attach" {
  name       = "${var.account_code}-${var.env}-pattach-cc-infra-cicd-jenkins"
  roles      = [aws_iam_role.cicd-jenkins-role.name]
  policy_arn = aws_iam_policy.cicd-jenkins-policy.arn
}
