resource "aws_glue_job" "fis-colldialeroutput-raw2prepared" {
  name              = "${var.account_code}-${var.env}-gluejob-fis-colldialeroutput-${var.region_code}"
  role_arn          = aws_iam_role.fis-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  number_of_workers = "2"
  worker_type       = "G.1X"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/colldialeroutput/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--JOB_NAME"            = "FIS_COLLDIALEROUTPUT_GLUE_JOB"
    "--bucket"              = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
    "--class"               = "GlueApp"
    "--config_path"         = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/colldialeroutput/colldialeroutputschema.txt"
    "--source_prefix"       = "raw/CollDialerOutput"
    "--target_prefix"       = "prepared/CollDialerOutput"
    "--temporary_prefix"    = "temporary"
    "--version_glue"        = "${trimspace(data.aws_s3_bucket_object.omfeds-glue-latest.body)}"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--enable-auto-scaling" = "true"
    
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-fis-colldialeroutput-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )

}

resource "aws_glue_trigger" "fis-colldialeroutput-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-fis-colldialeroutput-raw2prepared-${var.region_code}"
  schedule = "cron(30 13 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.fis-colldialeroutput-raw2prepared.name
  }

  tags = merge(
    local.fis_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-fis-colldialeroutput-raw2prepared-${var.region_code}",
      "ApplicationSubject", "FIS-LiveVox"
    )
  )
}