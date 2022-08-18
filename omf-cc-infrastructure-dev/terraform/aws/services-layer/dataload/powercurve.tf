data "aws_ssm_parameter" "powercurve-vpc-id" {
  name = "/${var.account_code}/acc/vpc/id"
}
data "aws_ssm_parameter" "powercurve-private-subnet-0" {
  name = "/${var.account_code}/acc/vpc/subnets/private/0"
}
data "aws_ssm_parameter" "powercurve-private-subnet-1" {
  name = "/${var.account_code}/acc/vpc/subnets/private/1"
}

data "aws_ssm_parameter" "powercurve-postgress-password" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/password"
}

data "aws_ssm_parameter" "powercurve-postgress-username" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/username"
}

data "aws_ssm_parameter" "powercurve-postgress-hostname" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/hostname"
}

data "aws_ssm_parameter" "powercurve-postgress-cidrblocks" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/cidr_blocks"
}

data "aws_ssm_parameter" "powercurve-postgress-database" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/database"
}

data "aws_ssm_parameter" "powercurve-postgress-schema1" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/schema1"
}

data "aws_ssm_parameter" "powercurve-postgress-table-applicant" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/applicant"
}

data "aws_ssm_parameter" "powercurve-postgress-table-bureaudata" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/bureaudata"
}

data "aws_ssm_parameter" "powercurve-postgress-table-premiers1" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/premiers1"
}

data "aws_ssm_parameter" "powercurve-postgress-table-premiers2" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/premiers2"
}

data "aws_ssm_parameter" "powercurve-postgress-table-errors" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/errors"
}

data "aws_ssm_parameter" "powercurve-postgress-table-luminate" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/luminate"
}

data "aws_ssm_parameter" "powercurve-postgress-table-application" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/application"
}

data "aws_ssm_parameter" "powercurve-postgress-table-finaldecresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/finaldecresults"
}

data "aws_ssm_parameter" "powercurve-postgress-table-finaldecsystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/finaldecsystem"
}

data "aws_ssm_parameter" "powercurve-postgress-table-postbureauomsystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauomsystem"
}

data "aws_ssm_parameter" "powercurve-postgress-table-postbureauxsresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauxsresults"
}

data "aws_ssm_parameter" "powercurve-postgress-table-postbureauxssystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauxssystem"
}

data "aws_ssm_parameter" "powercurve-postgress-table-prebureauresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/prebureauresults"
}

data "aws_ssm_parameter" "powercurve-postgress-table-prebureausystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/prebureausystem"
}

data "aws_ssm_parameter" "powercurve-postgress-table-postbureauomresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauomresults"
}


module "powercurve-dataload-s3sns2s3" {
  source               = "../../modules/s3sns2s3"
  name                 = "powercurve-dataload"
  config_file          = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/lambda/config.v${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}/powercurve_exchange_config.json"
  destination_bucket   = "${var.account_code}-acc-s3-cc-sfexchange-con-${var.region_code}"
  source_bucket        = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
  account_code         = var.account_code
  env                  = var.env
  region_code          = var.region_code
  version_lambda       = "${trimspace(data.aws_s3_bucket_object.omfeds-lambda-latest.body)}"
  append_date          = ""
  append_datetime      = ""
  destination_prefix   = ""
  source_prefix_filter = ""
  notification_filter_prefix = "prepared/"
  notification_filter_suffix = ".parquet"
  tags_var = local.powercurve_common_tags
}

resource "aws_glue_catalog_database" "powercurve-catalogdatabase" {
  name = "${var.env}-powercurve-catalogdatabase"
}

resource "aws_security_group" "powercurve-raw2prepared-glue-connection" {
  name = "${var.account_code}-${var.env}-powercurve-glue-raw2prepared-${var.region_code}"
  description = "Allow traffic for powercurve glue connection"
  vpc_id      = data.aws_ssm_parameter.powercurve-vpc-id.value
  egress {
    from_port        = "0"
    to_port          = "0"
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port = "0"
    protocol  = "-1"
    to_port   = "0"
    self      = true
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-powercurve-glue-raw2prepared-${var.region_code}"
    )
  )

}

resource "aws_glue_connection" "powercurve-raw2prepared" {
  connection_properties = {
    JDBC_CONNECTION_URL = data.aws_ssm_parameter.powercurve-postgress-hostname.value
    PASSWORD            = data.aws_ssm_parameter.powercurve-postgress-password.value
    USERNAME            = data.aws_ssm_parameter.powercurve-postgress-username.value
  }
  physical_connection_requirements {
    subnet_id = data.aws_ssm_parameter.powercurve-private-subnet-0.value
    security_group_id_list = [ aws_security_group.powercurve-raw2prepared-glue-connection.id ]
    //try hardcode
    availability_zone = "us-east-1a"
  }

  name = "${var.account_code}-${var.env}-glueconnection-powercurve-raw2prepared-${var.region_code}"

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-glueconnection-powercurve-raw2prepared-${var.region_code}"
    )
  )

}

//need to recreate according terraform definition, create new connection and crawler
resource "aws_glue_crawler" "powercurve-crawler" {
  database_name = aws_glue_catalog_database.powercurve-catalogdatabase.name
  name = "${var.account_code}-${var.env}-gluecrawler-powercurve-raw2prepared-${var.region_code}"
  role          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  table_prefix  = ""
  schedule      = "cron(0 * * * ? *)"
  jdbc_target {
    connection_name = aws_glue_connection.powercurve-raw2prepared.name
    path = "${data.aws_ssm_parameter.powercurve-postgress-database.value}/%"
  }

  configuration = jsonencode(
  {
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    Version = 1
  }
  )

}

resource "aws_glue_job" "powercurve-applicant-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-applicant-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-applicant.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-applicant.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-applicant.value}"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "applicant"
    "--JOB_NAME"                 = "POWERCURVE_APPLICANT_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-applicant-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-applicant-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-applicant-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-applicant-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-applicant-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-bureaudata-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-bureaudata-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-bureaudata.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-bureaudata.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-bureaudata.value}"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "bureaudata"
    "--JOB_NAME"                 = "POWERCURVE_BUREAUDATA_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-bureaudata-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-bureaudata-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-bureaudata-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-bureaudata-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-bureaudata-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-premiers1-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-premiers1-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-premiers1.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-premiers1.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-premiers1.value}"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "premiers1"
    "--JOB_NAME"                 = "POWERCURVE_PREMIERS1_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-premiers1-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-premiers1-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-premiers1-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-premiers1-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-premiers1-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-premiers2-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-premiers2-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-premiers2.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-premiers2.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-premiers2.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "premiers2"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_PREMIERS2_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-premiers2-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-premiers2-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-premiers2-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-premiers2-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-premiers2-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-errors-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-errors-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-errors.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-errors.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-errors.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "errors"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_ERRORS_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-errors-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-errors-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-errors-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-errors-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-errors-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-luminate-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-luminate-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-luminate.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-luminate.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-luminate.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "luminate"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_LUMINATE_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-luminate-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-luminate-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-luminate-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-luminate-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-luminate-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-application-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-application-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-application.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-application.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-application.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "application"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_APPLICATION_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-application-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-application-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-application-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-application-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-application-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-finaldecresults-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-finaldecresults-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-finaldecresults.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-finaldecresults.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-finaldecresults.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "finaldecresults"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_FINALDECRESULTS_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-finaldecresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-finaldecresults-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-finaldecresults-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-finaldecresults-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-finaldecresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-finaldecsystem-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-finaldecsystem-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-finaldecsystem.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-finaldecsystem.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-finaldecsystem.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "finaldecsystem"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_FINALDECSYSTEM_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-finaldecsystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-finaldecsystem-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-finaldecsystem-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-finaldecsystem-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-finaldecsystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-postbureauomsystem-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-postbureauomsystem-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomsystem.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomsystem.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomsystem.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "postbureauomsystem"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_POSTBUREAUOMSYSTEM_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-postbureauomsystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-postbureauomsystem-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauomsystem-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-postbureauomsystem-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauomsystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-postbureauxsresults-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-postbureauxsresults-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxsresults.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxsresults.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxsresults.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "postbureauxsresults"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_POSTBUREAUXSRESULTS_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-postbureauxsresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-postbureauxsresults-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauxsresults-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-postbureauxsresults-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauxsresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-postbureauxssystem-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-postbureauxssystem-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxssystem.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxssystem.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-postbureauxssystem.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "postbureauxssystem"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_POSTBUREAUXSSYSTEM_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-postbureauxssystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-postbureauxssystem-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauxssystem-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-postbureauxssystem-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauxssystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-prebureauresults-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-prebureauresults-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-prebureauresults.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-prebureauresults.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-prebureauresults.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "prebureauresults"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_PREBUREAURESULTS_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-prebureauresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-prebureauresults-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-prebureauresults-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-prebureauresults-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-prebureauresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_job" "powercurve-prebureausystem-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-prebureausystem-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-prebureausystem.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-prebureausystem.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-prebureausystem.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "prebureausystem"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_PREBUREAUSYSTEM_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-prebureausystem-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-prebureausystem-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-prebureausystem-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-prebureausystem-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-prebureausystem-raw2prepared-${var.region_code}"
    )
  )
}

//need to replace connection into env-var
resource "aws_glue_job" "powercurve-postbureauomresults-raw2prepared-job" {
  name              = "${var.account_code}-${var.env}-gluejob-powercurve-postbureauomresults-raw2prepared-${var.region_code}"
  role_arn          = aws_iam_role.powercurve-raw2prepared-glue-role.arn
  glue_version      = "3.0"
  connections       = [aws_glue_connection.powercurve-raw2prepared.name]
  worker_type       = "G.1X"
  number_of_workers = "2"

  command {
    script_location = "s3://${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/raw2prepared.py"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--bucket"                   = "${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}"
    "--target_prefix"            = "prepared/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomresults.value}"
    "--raw_layer_prefix"         = "raw/${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomresults.value}"
    "--pii_fields_config_path"   = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/PII_fields.json"
    "--rds_database"             = aws_glue_catalog_database.powercurve-catalogdatabase.name
    "--table"                    = "${data.aws_ssm_parameter.powercurve-postgress-database.value}_${data.aws_ssm_parameter.powercurve-postgress-schema1.value}_${data.aws_ssm_parameter.powercurve-postgress-table-postbureauomresults.value}"
    "--job_bookmark_config_path" = "${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/appcode/glue/omfeds/powercurve/options_jobBookmark_keys.json"
    "--feed_name"                = "postbureauomresults"
    "--job-bookmark-option"      = "job-bookmark-disable"
    "--JOB_NAME"                 = "POWERCURVE_POSTBUREAUOMRESULTS_GLUE_JOB"
    "--enable-auto-scaling"      = "true"
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluejob-powercurve-postbureauomresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_glue_trigger" "powercurve-postbureauomresults-raw2prepared-schedule" {
  name = "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauomresults-raw2prepared-${var.region_code}"
  schedule = "cron(30 * * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.powercurve-postbureauomresults-raw2prepared-job.name
  }

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-gluetrigger-powercurve-postbureauomresults-raw2prepared-${var.region_code}"
    )
  )
}

resource "aws_iam_role" "powercurve-raw2prepared-glue-role" {
  name = "${var.account_code}-${var.env}-iamrole-powercurve-raw2prepared"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iamrole-powercurve-raw2prepared"
    )
  )

}

resource "aws_iam_policy" "powercurve-raw2prepared-glue-policy" {
  name = "${var.account_code}-${var.env}-iampolicy-powercurve-raw2prepared-glue"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:*",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListAllMyBuckets",
                "s3:GetBucketAcl",
                "ec2:DescribeVpcEndpoints",
                "ec2:DescribeRouteTables",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcAttribute",
                "iam:ListRolePolicies",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket"
            ],
            "Resource": [
                "arn:aws:s3:::aws-glue-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::aws-glue-*/*",
                "arn:aws:s3:::*/*aws-glue-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::crawler-public*",
                "arn:aws:s3:::aws-glue-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:AssociateKmsKey"
            ],
            "Resource": [
                "arn:aws:logs:*:*:/aws-glue/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "aws-glue-service-resource"
                    ]
                }
            },
            "Resource": [
                "arn:aws:ec2:*:*:network-interface/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:instance/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*Object*",
            "Resource": [
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-powercurve-con-${var.region_code}/*",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-cc-infra-appcode-ltd-${var.region_code}/*",
              "arn:aws:s3:::${var.account_code}-${var.env}-s3-infra-temp-ltd-${var.region_code}/*"
            ]
        },
        {
          "Effect": "Allow",
          "Action": [
              "ssm:Describe*",
              "ssm:Get*",
              "ssm:List*"
                ],
          "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF

  tags = merge(
    local.powercurve_common_tags,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-iampolicy-powercurve-raw2prepared-glue"
    )
  )

}

resource "aws_iam_policy_attachment" "powercurve-raw2prepared-attachment-glue" {
  name = "${var.account_code}-${var.env}-iamrole-powercurve-raw2prepared-attachmentglue"
  roles      = [aws_iam_role.powercurve-raw2prepared-glue-role.name]
  policy_arn = aws_iam_policy.powercurve-raw2prepared-glue-policy.arn
}