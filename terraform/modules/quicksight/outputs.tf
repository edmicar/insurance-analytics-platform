output "data_source_arn" {
  value = aws_quicksight_data_source.athena.arn
}

output "policy_dataset_arn" {
  value = aws_quicksight_data_set.policy_data.arn
}

output "claims_dataset_arn" {
  value = aws_quicksight_data_set.claim_data.arn
}
