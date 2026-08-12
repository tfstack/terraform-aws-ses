resource "aws_s3_bucket" "gds_spool" {
  bucket        = local.spool_name
  force_destroy = true
  tags          = merge(var.tags, { Name = local.spool_name, Role = "gds-spool-stand-in" })
}

resource "aws_s3_bucket_public_access_block" "gds_spool" {
  bucket = aws_s3_bucket.gds_spool.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gds_spool" {
  bucket = aws_s3_bucket.gds_spool.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
