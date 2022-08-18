output "bucket-storage-ssm" {
  value = aws_ssm_parameter.bucket-name.id
}
