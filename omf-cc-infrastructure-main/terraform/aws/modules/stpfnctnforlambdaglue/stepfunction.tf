resource "aws_sfn_state_machine" "stpfnctnforlambdaglue-stepfunction" {
  name     = "${var.account_code}-${var.env}-stpfnctnforlambdaglue-cc-${var.name}-${var.region_code}"
  role_arn = aws_iam_role.stpfnctnforlambdaglue.arn
  definition = templatefile(
  "../../../stepfunction/fis/fis.tpl",
  {
    #glue part
    job_name                   = "${var.glue_job_name}"
    bucket                     = "${var.source_bucket}"
    bucket_config              = "${var.bucket_config}"
    copybook_prefix            = "${var.copybook_prefix}"
    header_copybook_prefix     = "${var.header_copybook_prefix}"

    #lambda part
    prep2exchange_function_name     = "${var.prep2exchange_function_name}"
    target_bucket                   = "${var.target_bucket}"
    sf_function_name                = "${var.sf_function_name}"
    sql_query_file                  = "CALL INGESTION_UTILS.SP_CR_LOAD_STAGE_TO_MAIN_USING_MAPPING('FIS','cards_stage', {0}, 'CARDS', 'FIS_STG', 'CARDHOLDER_MASTER', 'FIS_BASE', 'CARDHOLDER_MASTER', 'APPEND', '', '')"

  }
  )
}

resource "aws_iam_role" "stpfnctnforlambdaglue" {
  name = "${var.account_code}-${var.env}-iamrole-stpfnctnforlambdaglue-${var.name}"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Sid": "",
            "Principal": {
                "Service": "states.amazonaws.com"
            }
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "stpfnctnforlambdaglue" {
  name = "${var.account_code}-${var.env}-iampolicy-stpfnctnforlambdaglue-${var.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:*",
                "s3:*",
                "cloudwatch:*",
                "dynamodb:*",
                "lambda:*",
                "eks:*",
                "events:*",
                "logs:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "stpfnctnforlambdaglue" {
  name = "${var.account_code}-${var.env}-attach-stpfnctnforlambdaglue-${var.name}"
  roles      = [aws_iam_role.stpfnctnforlambdaglue.name]
  policy_arn = aws_iam_policy.stpfnctnforlambdaglue.arn
}
