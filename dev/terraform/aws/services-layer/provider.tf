provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::560030824191:role/Atlantis-AdministratorExecutionRole"
    session_name = "terraform-omfatlantisdev-omfedsdev"
  }
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
  default_tags {
    tags = {
      Environment = var.env
      Project     = "Credit Card"
      created_by  = "terraform"
    }
  }
}
