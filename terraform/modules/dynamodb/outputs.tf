output "value_lookup_table_name" {
  value = aws_dynamodb_table.value_lookup.name
}

output "value_lookup_table_arn" {
  value = aws_dynamodb_table.value_lookup.arn
}

output "multi_lookup_table_name" {
  value = aws_dynamodb_table.multi_lookup.name
}

output "multi_lookup_table_arn" {
  value = aws_dynamodb_table.multi_lookup.arn
}

output "hash_values_table_name" {
  value = aws_dynamodb_table.hash_values.name
}

output "hash_values_table_arn" {
  value = aws_dynamodb_table.hash_values.arn
}

output "job_audit_table_name" {
  value = aws_dynamodb_table.job_audit.name
}

output "job_audit_table_arn" {
  value = aws_dynamodb_table.job_audit.arn
}

output "all_table_arns" {
  value = [
    aws_dynamodb_table.value_lookup.arn,
    aws_dynamodb_table.multi_lookup.arn,
    aws_dynamodb_table.hash_values.arn,
    aws_dynamodb_table.job_audit.arn
  ]
}
