###############################################################################
# InsuranceLake - AWS Glue ETL Jobs
# Dois jobs: Collect→Cleanse e Cleanse→Consume
###############################################################################

# ------------------------------------------------------------------------------
# IAM Role for Glue Jobs
# ------------------------------------------------------------------------------
resource "aws_iam_role" "glue_job_role" {
  name = "${var.environment}-insurancelake-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${var.environment}-insurancelake-glue-s3-policy"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.collect_bucket_arn,
          "${var.collect_bucket_arn}/*",
          var.cleanse_bucket_arn,
          "${var.cleanse_bucket_arn}/*",
          var.consume_bucket_arn,
          "${var.consume_bucket_arn}/*",
          var.etl_scripts_bucket_arn,
          "${var.etl_scripts_bucket_arn}/*",
          var.glue_temp_bucket_arn,
          "${var.glue_temp_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_table_arns
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:CreateDatabase",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# ------------------------------------------------------------------------------
# Glue Job: Collect to Cleanse
# Schema mapping + Transforms + Data Quality (before/after transform)
# ------------------------------------------------------------------------------
resource "aws_glue_job" "collect_to_cleanse" {
  name     = "${var.environment}-insurancelake-collect-to-cleanse-job"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/collect_to_cleanse.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${var.glue_temp_bucket_name}/spark-logs/"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--TempDir"                          = "s3://${var.glue_temp_bucket_name}/temp/"
    "--additional-python-modules"        = "rapidfuzz"
    "--extra-py-files"                   = "s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/glue_catalog_helpers.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/custom_mapping.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_lookup.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_dataprotection.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_premium.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_misc.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_stringmanipulation.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_typeconversion.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_structureddata.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/dataquality_check.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datalineage.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/dataquery.py"
    "--environment"                      = var.environment
    "--txn_bucket"                       = var.etl_scripts_bucket_name
    "--txn_spec_prefix_path"             = "/etl/transformation-spec/"
    "--txn_sql_prefix_path"              = "/etl/transformation-sql/"
    "--txn_dq_prefix_path"               = "/etl/dq-rules/"
    "--source_bucket"                    = "s3://${var.collect_bucket_name}"
    "--target_bucket"                    = "s3://${var.cleanse_bucket_name}"
    "--hash_value_table"                 = var.hash_values_table_name
    "--value_lookup_table"               = var.value_lookup_table_name
    "--multi_lookup_table"               = var.multi_lookup_table_name
    "--dq_results_table"                 = "${var.environment}-insurancelake-etl-dq-results"
    "--state_machine_name"               = "${var.environment}-insurancelake-etl-state-machine"
    "--execution_id"                     = "default"
    "--source_key"                       = "placeholder"
    "--source_path"                      = "placeholder"
    "--target_database_name"             = "placeholder"
    "--table_name"                       = "placeholder"
    "--base_file_name"                   = "placeholder"
    "--p_year"                           = "2024"
    "--p_month"                          = "01"
    "--p_day"                            = "01"
  }

  glue_version      = "4.0"
  number_of_workers = var.glue_workers
  worker_type       = var.glue_worker_type
  timeout           = var.glue_timeout
}

# ------------------------------------------------------------------------------
# Glue Job: Cleanse to Consume
# Spark SQL (joins/unions) + Data Quality (after_sparksql) + Athena SQL (views)
# ------------------------------------------------------------------------------
resource "aws_glue_job" "cleanse_to_consume" {
  name     = "${var.environment}-insurancelake-cleanse-to-consume-job"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/cleanse_to_consume.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${var.glue_temp_bucket_name}/spark-logs/"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--TempDir"                          = "s3://${var.glue_temp_bucket_name}/temp/"
    "--extra-py-files"                   = "s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/glue_catalog_helpers.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/custom_mapping.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_lookup.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_dataprotection.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_premium.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_misc.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_stringmanipulation.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_typeconversion.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datatransform_structureddata.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/dataquality_check.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/datalineage.py,s3://${var.etl_scripts_bucket_name}/etl/glue-scripts/lib/dataquery.py"
    "--environment"                      = var.environment
    "--txn_bucket"                       = var.etl_scripts_bucket_name
    "--txn_spec_prefix_path"             = "/etl/transformation-spec/"
    "--txn_sql_prefix_path"              = "/etl/transformation-sql/"
    "--txn_dq_prefix_path"               = "/etl/dq-rules/"
    "--source_bucket"                    = "s3://${var.cleanse_bucket_name}"
    "--target_bucket"                    = "s3://${var.consume_bucket_name}"
    "--hash_value_table"                 = var.hash_values_table_name
    "--value_lookup_table"               = var.value_lookup_table_name
    "--multi_lookup_table"               = var.multi_lookup_table_name
    "--dq_results_table"                 = "${var.environment}-insurancelake-etl-dq-results"
    "--state_machine_name"               = "${var.environment}-insurancelake-etl-state-machine"
    "--execution_id"                     = "default"
    "--source_key"                       = "placeholder"
    "--source_path"                      = "placeholder"
    "--target_database_name"             = "placeholder"
    "--table_name"                       = "placeholder"
    "--base_file_name"                   = "placeholder"
    "--p_year"                           = "2024"
    "--p_month"                          = "01"
    "--p_day"                            = "01"
  }

  glue_version      = "4.0"
  number_of_workers = var.glue_workers
  worker_type       = var.glue_worker_type
  timeout           = var.glue_timeout
}

# ------------------------------------------------------------------------------
# Glue Catalog Database
# NOTA: Em contas de workshop, a SCP bloqueia glue:CreateDatabase.
# Os databases são criados automaticamente pelo Glue Job na primeira execução.
# Em produção, descomente os blocos abaixo:
# ------------------------------------------------------------------------------
# resource "aws_glue_catalog_database" "insurancelake" {
#   name        = var.database_name
#   description = "InsuranceLake Cleanse layer - curated insurance data"
# }
#
# resource "aws_glue_catalog_database" "insurancelake_consume" {
#   name        = "${var.database_name}_consume"
#   description = "InsuranceLake Consume layer - analytics-ready insurance data"
# }
