variable "aws_region" {
  description = "AWS Region for SES (one SES account per Region)."
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix for mail pipeline and related resources."
  type        = string
  default     = "app-mail-dev"
}

variable "configuration_set_name" {
  description = "Configuration set name for dev app mail."
  type        = string
}

variable "email_identities" {
  description = "Verified email addresses used as From in sandbox."
  type        = list(string)
}

variable "test_from_address" {
  description = "Default From address for mail pipeline e2e tests."
  type        = string
}

variable "test_to_address" {
  description = "Default To address for mail pipeline e2e tests. Must be verified in sandbox."
  type        = string
}

variable "allowed_from_addresses" {
  description = "Restrict sending to these From addresses."
  type        = list(string)
  default     = []
}

variable "sns_email_subscriptions" {
  description = "Demo only: inbox that receives SNS JSON for Send/Delivery/Bounce/Complaint."
  type        = list(string)
  default     = []
}

variable "enable_alarms" {
  description = "Create CloudWatch alarms for DLQ depth and worker errors."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
