terraform {
  required_version = "0.13.5"
  backend "s3" {
    bucket         = "terraform-state-hmu82fm8xqv2-us-east-1"
    dynamodb_table = "TerraformStatelock"
    key            = "omfterraform/edatasvcs/terraform/aws/omfedsdev/us-east-1/account-layer-preparation/edatasvc.tfstate"
    #    key            = "omfterraform/omf-cc-infrastructure/terraform/aws/omfedsdev/us-east-1/acc/cc-prep-oedsd-acc-ue1.tfstate"
    region         = "us-east-1"
  }
}
