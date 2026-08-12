variable "name_prefix" {
  description = "Prefix for queue, Lambda, and IAM resources."
  type        = string
}

variable "aws_region" {
  description = "AWS Region where SES sends mail."
  type        = string
}

variable "configuration_set_name" {
  description = "SES configuration set attached to each send."
  type        = string
}

variable "default_from_address" {
  description = "Default From address when a message omits from."
  type        = string
}

variable "default_to_address" {
  description = "Default To address when a message omits to."
  type        = string
}

variable "message_retention_seconds" {
  description = "How long undelivered mail jobs remain on the main queue."
  type        = number
  default     = 345600
}

variable "dlq_message_retention_seconds" {
  description = "How long failed mail jobs remain on the dead-letter queue."
  type        = number
  default     = 1209600
}

variable "visibility_timeout_seconds" {
  description = "SQS visibility timeout. Should exceed the worker Lambda timeout."
  type        = number
  default     = 180
}

variable "max_receive_count" {
  description = "Receive attempts before a message moves to the dead-letter queue."
  type        = number
  default     = 5
}

variable "worker_timeout_seconds" {
  description = "Worker Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "worker_batch_size" {
  description = "Maximum SQS messages processed per worker invocation."
  type        = number
  default     = 10
}

variable "worker_max_concurrency" {
  description = "Maximum concurrent worker invocations from the mail queue."
  type        = number
  default     = 5
}

variable "worker_reserved_concurrency" {
  description = "Reserved concurrency for the worker Lambda. Leave null to use the account pool."
  type        = number
  default     = null
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention for producer and worker Lambdas."
  type        = number
  default     = 30
}

variable "enable_alarms" {
  description = "Create CloudWatch alarms for DLQ depth and worker errors."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for supporting resources."
  type        = map(string)
  default     = {}
}
