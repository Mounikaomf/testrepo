module "s3-powercurve" {
  source = "../../modules/s3"

  account_code = var.account_code
  env = var.env
  domain = "cc"
  category = "powercurve"
  security_classification = "con"
  region = var.region_code
  tags_var = local.powercurve_common_tags
}

resource "aws_ssm_parameter" "powercurve-postgress-hostname" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/hostname"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-user" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/username"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-password" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/password"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-cidrblocks" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/cidr_blocks"
  type = "String"
  value = "0"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-database" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/database"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-schema1" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/schema1"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-schema-schema2" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/schema/schema2"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

# ------- PCO tables -------
resource "aws_ssm_parameter" "powercurve-postgress-table-applicant" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/applicant"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-bureaudata" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/bureaudata"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-premiers1" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/premiers1"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-premiers2" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/premiers2"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-errors" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/errors"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-luminate" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/luminate"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-application" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/application"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-finaldecresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/finaldecresults"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-finaldecsystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/finaldecsystem"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-postbureauomsystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauomsystem"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-postbureauxsresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauxsresults"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-postbureauxssystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauxssystem"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


resource "aws_ssm_parameter" "powercurve-postgress-table-prebureauresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/prebureauresults"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-prebureausystem" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/prebureausystem"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "powercurve-postgress-table-postbureauomresults" {
  name = "/${var.account_code}/${var.env}/dataload/postgress/powercurve/table/postbureauomresults"
  type = "String"
  value = "default"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}