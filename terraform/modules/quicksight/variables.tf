variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "database_name" {
  description = "Glue Catalog database name (without _consume suffix)"
  type        = string
  default     = "syntheticgeneraldata"
}

variable "athena_workgroup" {
  description = "Athena workgroup to use for queries"
  type        = string
  default     = "primary"
}

variable "quicksight_username" {
  description = "QuickSight username (usually the IAM user or role session name)"
  type        = string
}
