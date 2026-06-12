variable "environment" {
  type = string
}

variable "collect_to_cleanse_job_name" {
  type = string
}

variable "cleanse_to_consume_job_name" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
