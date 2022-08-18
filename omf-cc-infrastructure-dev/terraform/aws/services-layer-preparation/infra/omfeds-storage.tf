module "s3-infra-bucket" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "infra"
  category = "bucket"
  security_classification = "ltd"
  region = var.region_code
  tags_var = local.infra_common_tags
}

module "s3-infra-temp" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "infra"
  category = "temp"
  security_classification = "ltd"
  region = var.region_code
  tags_var = local.infra_common_tags

}
