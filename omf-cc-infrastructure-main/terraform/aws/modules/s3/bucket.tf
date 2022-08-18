resource "aws_s3_bucket" "bucket-storage" {
  bucket = "${var.account_code}-${var.env}-s3-${var.domain}-${var.category}-${var.security_classification}-${var.region}"

  tags = merge(
    var.tags_var,
    map(
      "ApplicationComponent", "${var.account_code}-${var.env}-s3-${var.domain}-${var.category}-${var.security_classification}-${var.region}"
    )
  )

}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-encryption" {
  bucket = aws_s3_bucket.bucket-storage.bucket

  rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
  }
}

resource "aws_s3_bucket_public_access_block" "bucket-storage" {
  bucket = aws_s3_bucket.bucket-storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [aws_s3_bucket.bucket-storage]
}

resource "aws_ssm_parameter" "bucket-name" {
  type = "String"
  value = "${aws_s3_bucket.bucket-storage.id}"
  name = "/${var.account_code}/${var.env}/s3/${var.domain}/${var.category}/${var.security_classification}"
  depends_on = [aws_s3_bucket.bucket-storage]
  overwrite = true
}
