module "edatasvcs-infra" {
    source = "./infra"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "infra"
    version_lambda = "1"
}

module "edatasvcs-dataload"{
    source= "./dataload"
    depends_on = [module.edatasvcs-infra, module.edatasvcs-ingestion]
    version_glue = "1"
    version_lambda = "1"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataload"
}

module "edatasvcs-dataexchange"{
    source= "./dataexchange"
    version_glue = "1"
    version_lambda = "1"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataexchange"
}

module "edatasvcs-datastorage"{
    source= "./datastorage"
    version_glue = "1"
    version_lambda = "1"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "datastorage"
}

module "edatasvcs-dataproducts"{
    source= "./dataproducts"
    version_glue = "1"
    version_lambda = "1"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataproducts"
}

module "edatasvcs-ingestion"{
    source= "./ingestion"
    depends_on = [module.edatasvcs-infra]

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "ingestion"
    version_lambda = "1"
}

module "edatasvcs-dataaccess"{
    source= "./dataaccess"
    depends_on = [module.edatasvcs-infra]
    version_lambda = "1"
    version_glue = "1"

    project_name = "edatasvcs"
    account_code = var.account_code
    env = var.env
    region_code = var.region_code
    service_type = "dataaccess"
}
