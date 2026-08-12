variable "aws_region" {
  description = "AWS Region for SES."
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix for app sender and related supporting resources."
  type        = string
  default     = "app-mail-prod"
}

variable "configuration_set_name" {
  description = "Configuration set name for production app mail."
  type        = string
}

variable "domain" {
  description = "Sending domain, for example mail.example.com."
  type        = string
}

variable "mail_from_domain" {
  description = "Custom MAIL FROM subdomain, for example bounce.mail.example.com."
  type        = string
  default     = null
}

variable "mail_from_behavior_on_mx_failure" {
  description = "Behavior when MAIL FROM MX is unavailable."
  type        = string
  default     = "USE_DEFAULT_VALUE"
}

variable "enable_easy_dkim" {
  description = "Enable Easy DKIM for the domain identity."
  type        = bool
  default     = true
}

variable "route53_zone_id" {
  description = "Optional hosted zone for automatic DKIM and MAIL FROM records."
  type        = string
  default     = null
}

variable "create_route53_records" {
  description = "Create Route 53 records when route53_zone_id is set."
  type        = bool
  default     = false
}

variable "create_domain_spf_record" {
  description = "Create SPF TXT on the sending domain."
  type        = bool
  default     = true
}

variable "test_from_address" {
  description = "Default From address for the sender Lambda e2e test."
  type        = string
}

variable "test_to_address" {
  description = "Default To address for the sender Lambda e2e test."
  type        = string
}

variable "allowed_from_addresses" {
  description = "From addresses allowed by IAM condition."
  type        = list(string)
  default     = []
}

variable "sns_email_subscriptions" {
  description = "Leave empty in production. Use SQS, Lambda, or HTTPS instead."
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
