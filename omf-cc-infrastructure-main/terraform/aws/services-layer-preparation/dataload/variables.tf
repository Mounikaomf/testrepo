variable "env" {}
variable "project_name" {}
variable "service_type" {}
variable "region_code" {}
variable "account_code" {}

locals {
  powercurve_common_tags = {
    Application = "PowerCurve"
    ApplicationSubject = "PowerCurve"
  }
}