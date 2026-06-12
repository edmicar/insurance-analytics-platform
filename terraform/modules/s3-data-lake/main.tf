###############################################################################
# InsuranceLake - S3 Data Lake Buckets
# Camadas: Collect (raw) → Cleanse (curated) → Consume (analytics-ready)
###############################################################################

locals {
  bucket_prefix = "${var.environment}-insurancelake-${var.account_id}-${var.region}"
}

# ------------------------------------------------------------------------------
# Collect Bucket - Dados brutos no formato original
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "collect" {
  bucket = "${local.bucket_prefix}-collect"

  tags = merge(var.tags, {
    Layer = "Collect"
    Purpose = "Raw source data in original format"
  })
}

resource "aws_s3_bucket_versioning" "collect" {
  bucket = aws_s3_bucket.collect.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "collect" {
  bucket = aws_s3_bucket.collect.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "collect" {
  bucket = aws_s3_bucket.collect.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "collect_notification" {
  bucket = aws_s3_bucket.collect.id

  lambda_function {
    lambda_function_arn = var.trigger_lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [var.trigger_lambda_permission]
}

# ------------------------------------------------------------------------------
# Cleanse Bucket - Dados curados em Parquet, particionados
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "cleanse" {
  bucket = "${local.bucket_prefix}-cleanse"

  tags = merge(var.tags, {
    Layer = "Cleanse"
    Purpose = "Curated data in Parquet format with schema mapping and transforms applied"
  })
}

resource "aws_s3_bucket_versioning" "cleanse" {
  bucket = aws_s3_bucket.cleanse.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cleanse" {
  bucket = aws_s3_bucket.cleanse.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cleanse" {
  bucket = aws_s3_bucket.cleanse.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Consume Bucket - Dados prontos para analytics (QuickSight, Athena)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "consume" {
  bucket = "${local.bucket_prefix}-consume"

  tags = merge(var.tags, {
    Layer = "Consume"
    Purpose = "Analytics-ready data for BI tools and SQL queries"
  })
}

resource "aws_s3_bucket_versioning" "consume" {
  bucket = aws_s3_bucket.consume.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "consume" {
  bucket = aws_s3_bucket.consume.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "consume" {
  bucket = aws_s3_bucket.consume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# ETL Scripts Bucket - Configs de transformação, SQL, DQ rules
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "etl_scripts" {
  bucket = "${var.environment}-insurancelake-etl-scripts"

  tags = merge(var.tags, {
    Layer = "Configuration"
    Purpose = "ETL transformation specs, SQL files, data quality rules"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etl_scripts" {
  bucket = aws_s3_bucket.etl_scripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "etl_scripts" {
  bucket = aws_s3_bucket.etl_scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Glue Temp Bucket - Arquivos temporários e recomendações geradas
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "glue_temp" {
  bucket = "${local.bucket_prefix}-glue-temp"

  tags = merge(var.tags, {
    Layer = "Temporary"
    Purpose = "Glue job temp files and auto-generated recommendations"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id

  rule {
    id     = "cleanup-temp-files"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# Access Logs Bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "access_logs" {
  bucket = "${local.bucket_prefix}-access-logs"

  tags = merge(var.tags, {
    Layer = "Logging"
    Purpose = "S3 server access logs for auditing"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
