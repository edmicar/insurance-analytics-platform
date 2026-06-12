###############################################################################
# Import existing resources created by a previous partial apply
# These import blocks tell Terraform to adopt already-existing AWS resources
# into its state, avoiding "AlreadyExists" errors.
#
# After successful first apply, this file can be deleted.
###############################################################################

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

import {
  to = module.glue_etl.aws_iam_role.glue_job_role
  id = "dev-insurancelake-glue-role"
}

import {
  to = module.step_functions.aws_iam_role.step_functions_role
  id = "dev-insurancelake-sfn-role"
}
