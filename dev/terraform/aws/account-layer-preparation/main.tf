module "account-layer-preparation-ingestion" {
    source = "./ingestion"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "ingestion"
}

module "account-layer-preparation-datastorage"{
    source= "./datastorage"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "datastorage"
}

module "account-layer-preparation-infra"{
    source= "./infra"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "infra"
}

module "account-layer-preparation-dataexchange"{
    source= "./dataexchange"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "dataexchange"
}
