###############################################################################
# InsuranceLake - Dev Environment
# Composição de todos os módulos para o ambiente de desenvolvimento
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Para produção, descomente e configure o backend S3:
  # backend "s3" {
  #   bucket         = "terraform-state-insurancelake"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# KMS Key for encryption at rest
# Nota: Em contas de workshop com SCP restritiva, usamos SSE-S3 (AES256)
# Em produção real, use KMS customizado para controle granular de acesso
# ------------------------------------------------------------------------------
# resource "aws_kms_key" "insurancelake" { ... }
# Desabilitado para compatibilidade com contas de lab/sandbox

locals {
  # Em produção, use: aws_kms_key.insurancelake.arn
  # Em lab/sandbox, usamos encryption default do S3 (SSE-S3)
  kms_key_arn = null
  tags = {
    Project     = "InsuranceLake"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# SNS Topic for notifications
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.environment}-insurancelake-notifications"
}

# ------------------------------------------------------------------------------
# Module: S3 Data Lake Buckets
# ------------------------------------------------------------------------------
module "s3_data_lake" {
  source = "../../modules/s3-data-lake"

  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  region      = var.region
  kms_key_arn = local.kms_key_arn
}

# ------------------------------------------------------------------------------
# Module: DynamoDB Tables
# ------------------------------------------------------------------------------
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment = var.environment
  kms_key_arn = local.kms_key_arn
  tags        = local.tags
}

# ------------------------------------------------------------------------------
# Module: Glue ETL Jobs
# ------------------------------------------------------------------------------
module "glue_etl" {
  source = "../../modules/glue-etl"

  environment             = var.environment
  kms_key_arn             = local.kms_key_arn
  collect_bucket_name     = module.s3_data_lake.collect_bucket_name
  collect_bucket_arn      = module.s3_data_lake.collect_bucket_arn
  cleanse_bucket_name     = module.s3_data_lake.cleanse_bucket_name
  cleanse_bucket_arn      = module.s3_data_lake.cleanse_bucket_arn
  consume_bucket_name     = module.s3_data_lake.consume_bucket_name
  consume_bucket_arn      = module.s3_data_lake.consume_bucket_arn
  etl_scripts_bucket_name = module.s3_data_lake.etl_scripts_bucket_name
  etl_scripts_bucket_arn  = module.s3_data_lake.etl_scripts_bucket_arn
  glue_temp_bucket_name   = module.s3_data_lake.glue_temp_bucket_name
  glue_temp_bucket_arn    = module.s3_data_lake.glue_temp_bucket_arn
  dynamodb_table_arns     = module.dynamodb.all_table_arns
  value_lookup_table_name = module.dynamodb.value_lookup_table_name
  multi_lookup_table_name = module.dynamodb.multi_lookup_table_name
  hash_values_table_name  = module.dynamodb.hash_values_table_name
  tags                    = local.tags
}

# ------------------------------------------------------------------------------
# Locals (movido para cima com KMS)
# ------------------------------------------------------------------------------
module "step_functions" {
  source = "../../modules/step-functions"

  environment                 = var.environment
  collect_to_cleanse_job_name = module.glue_etl.collect_to_cleanse_job_name
  cleanse_to_consume_job_name = module.glue_etl.cleanse_to_consume_job_name
  collect_bucket_name         = module.s3_data_lake.collect_bucket_name
  cleanse_bucket_name         = module.s3_data_lake.cleanse_bucket_name
  consume_bucket_name         = module.s3_data_lake.consume_bucket_name
  sns_topic_arn               = aws_sns_topic.pipeline_notifications.arn
}

# (locals já definido acima junto com KMS)
