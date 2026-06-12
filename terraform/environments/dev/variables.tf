variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-2"
}
