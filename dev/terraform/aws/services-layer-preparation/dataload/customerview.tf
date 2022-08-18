locals {
  customerview_common_tags = {
    Application = "CustomerView"
    ApplicationSubject = "CustomerView"
  }
}

module "s3-customerview" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "customerview"
  security_classification = "con"
  region = var.region_code
  tags_var = local.customerview_common_tags
}
