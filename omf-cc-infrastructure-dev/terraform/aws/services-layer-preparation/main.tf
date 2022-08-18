module "edatasvcs-preparation-ingestion"{
    source= "./ingestion"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "ingestion"
}

module "edatasvcs-preparation-dataaccess"{
    source= "./dataaccess"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataaccess"
}

module "edatasvcs-preparation-dataexchange"{
    source= "./dataexchange"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataexchange"
}

module "edatasvcs-preparation-dataproducts"{
    source= "./dataproducts"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataproducts"
}

module "edatasvcs-preparation-dataload"{
    source= "./dataload"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataload"
}

module "edatasvcs-preparation-infra"{
    source= "./infra"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "infra"
}
