output "collect_bucket" {
  value = module.s3_data_lake.collect_bucket_name
}

output "cleanse_bucket" {
  value = module.s3_data_lake.cleanse_bucket_name
}

output "consume_bucket" {
  value = module.s3_data_lake.consume_bucket_name
}

output "state_machine_arn" {
  value = module.step_functions.state_machine_arn
}

output "glue_collect_to_cleanse_job" {
  value = module.glue_etl.collect_to_cleanse_job_name
}

output "glue_cleanse_to_consume_job" {
  value = module.glue_etl.cleanse_to_consume_job_name
}
