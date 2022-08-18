locals {
  infra_common_tags = {
    Application = "CC-Infra"
    ApplicationSubject = "CC-Infra"
  }
}

module "s3-infra-storage" {
  source = "../../modules/s3"
  account_code = var.account_code
  env = var.env
  domain = "infra"
  category = "storage"
  security_classification = "ltd"
  region = var.region_code
  tags_var = local.infra_common_tags
}
