output "collect_to_cleanse_job_name" {
  value = aws_glue_job.collect_to_cleanse.name
}

output "cleanse_to_consume_job_name" {
  value = aws_glue_job.cleanse_to_consume.name
}

output "glue_role_arn" {
  value = aws_iam_role.glue_job_role.arn
}

output "database_name" {
  value = var.database_name
}

output "consume_database_name" {
  value = "${var.database_name}_consume"
}
