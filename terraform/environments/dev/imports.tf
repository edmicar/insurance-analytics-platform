###############################################################################
# Import existing resources from the workshop pre-provisioned environment
# These resources were created by the AWS Workshop setup before Terraform.
# After first successful apply, this file can be removed.
###############################################################################

# S3 Buckets
import {
  to = module.s3_data_lake.aws_s3_bucket.collect
  id = "dev-insurancelake-169459655914-us-east-1-collect"
}

import {
  to = module.s3_data_lake.aws_s3_bucket.cleanse
  id = "dev-insurancelake-169459655914-us-east-1-cleanse"
}

import {
  to = module.s3_data_lake.aws_s3_bucket.consume
  id = "dev-insurancelake-169459655914-us-east-1-consume"
}

import {
  to = module.s3_data_lake.aws_s3_bucket.etl_scripts
  id = "dev-insurancelake-etl-scripts"
}

import {
  to = module.s3_data_lake.aws_s3_bucket.glue_temp
  id = "dev-insurancelake-169459655914-us-east-1-glue-temp"
}

import {
  to = module.s3_data_lake.aws_s3_bucket.access_logs
  id = "dev-insurancelake-169459655914-us-east-1-access-logs"
}

# IAM Roles
import {
  to = module.glue_etl.aws_iam_role.glue_job_role
  id = "dev-insurancelake-glue-role"
}

import {
  to = module.step_functions.aws_iam_role.step_functions_role
  id = "dev-insurancelake-sfn-role"
}

# DynamoDB Tables
import {
  to = module.dynamodb.aws_dynamodb_table.value_lookup
  id = "dev-insurancelake-etl-value-lookup"
}

import {
  to = module.dynamodb.aws_dynamodb_table.multi_lookup
  id = "dev-insurancelake-etl-multi-lookup"
}

import {
  to = module.dynamodb.aws_dynamodb_table.hash_values
  id = "dev-insurancelake-etl-hash-values"
}

import {
  to = module.dynamodb.aws_dynamodb_table.job_audit
  id = "dev-insurancelake-etl-job-audit"
}

# Glue Jobs
import {
  to = module.glue_etl.aws_glue_job.collect_to_cleanse
  id = "dev-insurancelake-collect-to-cleanse-job"
}

import {
  to = module.glue_etl.aws_glue_job.cleanse_to_consume
  id = "dev-insurancelake-cleanse-to-consume-job"
}
