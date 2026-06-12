###############################################################################
# InsuranceLake - DynamoDB Tables
# Lookup, Audit, Hash (PII tokenization), Multi-lookup
###############################################################################

# ------------------------------------------------------------------------------
# Value Lookup Table - Single key lookups for transforms
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "value_lookup" {
  name         = "${var.environment}-insurancelake-etl-value-lookup"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "source_system"
  range_key    = "column_name"

  attribute {
    name = "source_system"
    type = "S"
  }

  attribute {
    name = "column_name"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Purpose = "ETL value lookups for data transformations"
  })
}

# ------------------------------------------------------------------------------
# Multi Lookup Table - Multiple condition lookups
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "multi_lookup" {
  name         = "${var.environment}-insurancelake-etl-multi-lookup"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lookup_group"
  range_key    = "lookup_item"

  attribute {
    name = "lookup_group"
    type = "S"
  }

  attribute {
    name = "lookup_item"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Purpose = "ETL multi-condition lookups"
  })
}

# ------------------------------------------------------------------------------
# Hash Values Table - PII tokenization vault
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "hash_values" {
  name         = "${var.environment}-insurancelake-etl-hash-values"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash_key"

  attribute {
    name = "hash_key"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Purpose = "PII tokenization vault - stores original values for detokenization"
  })
}

# ------------------------------------------------------------------------------
# Job Audit Table - Pipeline execution tracking
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "job_audit" {
  name         = "${var.environment}-insurancelake-etl-job-audit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "execution_id"

  attribute {
    name = "execution_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    attribute_name = "expiry_time"
    enabled        = true
  }

  tags = merge(var.tags, {
    Purpose = "ETL job execution audit trail"
  })
}
