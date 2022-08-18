locals {
  infra_common_tags = {
    Application = "CC-Infra"
    ApplicationSubject = "CC-Infra"
  }
}

resource "aws_kms_key" "kmskey-infra-key" {
  description             = "KMS for account layer"
  deletion_window_in_days = 30
  
  tags = merge(
    local.infra_common_tags,
    map(
      "ApplicationComponent", "KMS for account layer"
    )
  )

}

resource "aws_kms_alias" "kmskey-infra-alias" {
  name          = "alias/${var.env}"
  target_key_id = aws_kms_key.kmskey-infra-key.key_id
  depends_on = [aws_kms_key.kmskey-infra-key]
}
