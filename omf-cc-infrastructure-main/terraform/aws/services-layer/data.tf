data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

//data "aws_route53_zone" "omf" {
//  name         = "${var.domainname}."
//  private_zone = false
//}
