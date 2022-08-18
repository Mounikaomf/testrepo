variable "version_lambda" {}
variable "version_glue" {}

variable "env" {}
variable "project_name" {}
variable "service_type" {}
variable "region_code" {}
variable "account_code" {}

locals {
  fis_common_tags = {
    Application = "FIS"
  }
}

locals {
  report314a_common_tags = {
    Application = "314a"
    ApplicationSubject = "314a"
  }
}
