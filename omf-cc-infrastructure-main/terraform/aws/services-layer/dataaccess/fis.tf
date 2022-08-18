module "fis-sqs2sftp-accmaint" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-accmaint"
  region_code = var.region_code
  sftp_target_directory = "incoming"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-accmaint-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/Account Maintenance batch file"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-AccMaint"
    )
  )
}

module "fis-sqs2sftp-ereports" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-ereports"
  region_code = var.region_code
  sftp_target_directory = "incoming"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-ereports-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/eReports"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-eReports"
    )
  )
}

module "fis-sqs2sftp-boshreports" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-boshreports"
  region_code = var.region_code
  sftp_target_directory = "incoming"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-boshreports-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/BOSH reports"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-BOSHReports"
    )
  )
}

module "fis-sqs2sftp-gu010d" {
  source = "../../modules/sqs2batch"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-gu010d"
  region_code = var.region_code
  sftp_target_directory = "incoming"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-gu010d-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/cardholder_master"
  job_name = aws_batch_compute_environment.batch-sqs2sftp.compute_environment_name
  job_definition = aws_batch_job_definition.batch-job-definition-sqs2sftp.name
  job_queue = aws_batch_job_queue.batch-queue-sqs2sftp.name
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-CardholderMaster"
    )
  )
}

module "fis-sqs2sftp-gu011d" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-gu011d"
  region_code = var.region_code
  sftp_target_directory = "incoming"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-gu011d-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/nameaddress"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-NameAddress"
    )
  )
}

module "fis-sqs2sftp-analytixreports" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-analytixreports"
  region_code = var.region_code
  sftp_target_directory = "ANALYTIX"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/fisoffload/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-analytixreports-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/Analytix Reports"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-AnalytixReports"
    )
  )
}

module "fis-sqs2sftp-GU045" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-GU045"
  region_code = var.region_code
  sftp_target_directory = "/from_lambda"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-GU045-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/generalledger"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-GeneralLedger"
    )
  )
}

module "fis-sqs2sftp-WebBank" {
  source = "../../modules/sqs2sftp"

  account_code = var.account_code
  env = var.env
  feedname = "objectname"
  name = "fis-WebBank"
  region_code = var.region_code
  sftp_target_directory = "/from_lambda"
  sftp_target_hostname = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/hostname"
  sftp_target_pass_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/password"
  sftp_target_port = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/port"
  sftp_target_user_ssm = "/${var.account_code}/acc/dataaccess/sftp/eftwebbank/user"
  snstopic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.account_code}-${var.env}-fis-WebBank-${var.region_code}"
  source_bucket = "${var.account_code}-${var.env}-s3-cc-fis-con-${var.region_code}"
  version_lambda = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  source_filter_prefix = "raw/WebBank settlement file"
  tags_var = merge(
    local.fis_common_tags,
    map(
      "ApplicationSubject", "FIS-WebBank"
    )
  )
}
