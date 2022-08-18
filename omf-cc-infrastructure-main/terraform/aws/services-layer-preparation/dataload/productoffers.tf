locals {
  productoffer_common_tags = {
    Application = "ProductOffers"
    ApplicationSubject = "ProductOffers"
  }
}

module "s3-productoffers" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "productoffers"
  security_classification = "con"
  region = var.region_code
  tags_var = local.productoffer_common_tags
}
