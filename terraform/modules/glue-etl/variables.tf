variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "kms_key_arn" {
  type = string
}

variable "collect_bucket_name" { type = string }
variable "collect_bucket_arn" { type = string }
variable "cleanse_bucket_name" { type = string }
variable "cleanse_bucket_arn" { type = string }
variable "consume_bucket_name" { type = string }
variable "consume_bucket_arn" { type = string }
variable "etl_scripts_bucket_name" { type = string }
variable "etl_scripts_bucket_arn" { type = string }
variable "glue_temp_bucket_name" { type = string }
variable "glue_temp_bucket_arn" { type = string }

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs the Glue jobs need access to"
  type        = list(string)
}

variable "value_lookup_table_name" { type = string }
variable "multi_lookup_table_name" { type = string }
variable "hash_values_table_name" { type = string }

variable "database_name" {
  description = "Glue Catalog database name"
  type        = string
  default     = "syntheticgeneraldata"
}

variable "glue_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}

variable "glue_worker_type" {
  description = "Glue worker type (G.1X, G.2X)"
  type        = string
  default     = "G.1X"
}

variable "glue_timeout" {
  description = "Glue job timeout in minutes"
  type        = number
  default     = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}
