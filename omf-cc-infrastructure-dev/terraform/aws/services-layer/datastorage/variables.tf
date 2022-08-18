variable "version_glue" {}
variable "version_lambda" {}

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