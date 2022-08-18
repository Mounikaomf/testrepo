locals {
  onus_common_tags = {
    Application = "Onus"
    ApplicationSubject = "Onus"
  }
}

module "s3-onus" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "onus"
  security_classification = "con"
  region = var.region_code
  tags_var = local.onus_common_tags
}
