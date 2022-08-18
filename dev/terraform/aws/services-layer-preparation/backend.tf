terraform {
  required_version = "0.13.5"
  backend "s3" {
    bucket         = "terraform-state-hmu82fm8xqv2-us-east-1"
    dynamodb_table = "TerraformStatelock"
    key            = "omfterraform/omf-cc-infrastructure/terraform/aws/omfedsdev/us-east-1/qa1/svc/cc-svcprep-oedsd-qa1-ue1.tfstate"
    region         = "us-east-1"
  }
}
