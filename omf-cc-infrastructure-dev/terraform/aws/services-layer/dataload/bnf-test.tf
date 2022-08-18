resource "aws_glue_job" "bnf-raw2prepared-test" {
  name = "${var.account_code}-${var.env}-gluejob-bnf-${var.region_code}-test"
  role_arn     = aws_iam_role.bnf-raw2prepared-glue-role.arn
  glue_version = "3.0"
  number_of_workers = "10"
  worker_type       = "G.2X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/bnf/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--logging_table"       = "${var.account_code}-${var.env}-bnf-${var.region_code}"
    "--JOB_NAME"            = "${var.account_code}-${var.env}-bnf-raw2prepared-${var.region_code}"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-bnf-con-${var.region_code}"
    "--config_bucket"       = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}"
    "--source_prefix"       = "raw/bnf"
    "--target_prefix"       = "prepared"
    "--config_key"          = "appcode/glue/omfeds/bnf/bnf_config.json"
    "--enable-auto-scaling" = "true"
  }

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-bnf-${var.region_code}-test"
    )
  )

}

resource "aws_glue_trigger" "bnf-raw2prepared-schedule-test" {
  name = "${var.account_code}-${var.env}-gluetrigger-bnf-raw2prepared-${var.region_code}-test"
  schedule = "cron(30 6 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.bnf-raw2prepared-test.name
  }

  tags = merge(
    local.bnf_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-bnf-raw2prepared-${var.region_code}-test"
    )
  )
}