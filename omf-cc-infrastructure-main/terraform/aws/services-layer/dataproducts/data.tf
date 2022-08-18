data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_s3_bucket_object" "omfeds-lambda-latest" {
  bucket  = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key     = "appcode/lambda/omfeds_lambda_python_latest.txt"
}

data "aws_s3_bucket_object" "omfeds-glue-latest" {
  bucket  = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
  key     = "appcode/glue/omfeds_glue_latest.txt"
}
