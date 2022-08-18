variable "env" {}
variable "project_name" {}
variable "service_type" {}
variable "region_code" {}
variable "account_code" {}

locals {
  infra_common_tags = {
    Application = "CC-Infra"
    ApplicationSubject = "CC-Infra"
  }
}
