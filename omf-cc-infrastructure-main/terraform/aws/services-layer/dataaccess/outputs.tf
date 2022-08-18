output "sns_bnf_glue2offload" {
  value = aws_sns_topic.bnf-glue2offload.arn
}

output "sns_onus_glue2offload" {
  value = aws_sns_topic.onus-glue2offload.arn
}
