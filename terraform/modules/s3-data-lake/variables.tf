variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  type        = string
}

variable "trigger_lambda_arn" {
  description = "ARN of the Lambda function triggered by S3 events"
  type        = string
  default     = ""
}

variable "trigger_lambda_permission" {
  description = "Lambda permission resource dependency"
  type        = any
  default     = null
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
