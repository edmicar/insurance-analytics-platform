output "collect_bucket_name" {
  description = "Name of the Collect (raw data) bucket"
  value       = aws_s3_bucket.collect.id
}

output "collect_bucket_arn" {
  description = "ARN of the Collect bucket"
  value       = aws_s3_bucket.collect.arn
}

output "cleanse_bucket_name" {
  description = "Name of the Cleanse (curated data) bucket"
  value       = aws_s3_bucket.cleanse.id
}

output "cleanse_bucket_arn" {
  description = "ARN of the Cleanse bucket"
  value       = aws_s3_bucket.cleanse.arn
}

output "consume_bucket_name" {
  description = "Name of the Consume (analytics-ready data) bucket"
  value       = aws_s3_bucket.consume.id
}

output "consume_bucket_arn" {
  description = "ARN of the Consume bucket"
  value       = aws_s3_bucket.consume.arn
}

output "etl_scripts_bucket_name" {
  description = "Name of the ETL scripts configuration bucket"
  value       = aws_s3_bucket.etl_scripts.id
}

output "etl_scripts_bucket_arn" {
  description = "ARN of the ETL scripts bucket"
  value       = aws_s3_bucket.etl_scripts.arn
}

output "glue_temp_bucket_name" {
  description = "Name of the Glue temporary bucket"
  value       = aws_s3_bucket.glue_temp.id
}

output "glue_temp_bucket_arn" {
  description = "ARN of the Glue temp bucket"
  value       = aws_s3_bucket.glue_temp.arn
}
