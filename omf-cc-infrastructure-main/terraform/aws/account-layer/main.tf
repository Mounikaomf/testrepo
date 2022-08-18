module "account-layer-ingestion" {
    source = "./ingestion"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "ingestion"
}

module "account-layer-datastorage"{
    source = "./datastorage"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "datastorage"
}

module "account-layer-infra"{
    source = "./infra"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "infra"
}

module "account-layer-dataaccess"{
    source = "./dataaccess"
    account_code = var.account_code
    env = var.env
    project_name = var.project_name
    region_code = var.region_code
    service_type = "dataaccess"
}
