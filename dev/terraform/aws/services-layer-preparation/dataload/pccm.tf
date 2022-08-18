locals {
  pccm_common_tags = {
    Application = "PCCM"
    ApplicationSubject = "PCCM"
  }
}

module "s3-pccm" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "pccm"
  security_classification = "con"
  region = var.region_code
  tags_var = local.pccm_common_tags
}
