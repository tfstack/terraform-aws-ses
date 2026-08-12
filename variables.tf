############################################
# GENERAL
############################################

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.tags : length(k) > 0 && length(v) > 0])
    error_message = "All tag keys and values must be non-empty strings."
  }
}

############################################
# IDENTITY
############################################

variable "domain_identity" {
  description = <<-EOT
    Production pattern: one verified domain. Mutually exclusive with email_identities.
    Email addresses on the domain (noreply@mail.example.com) do not need separate identities.
  EOT
  type = object({
    domain                           = string
    enable_easy_dkim                 = optional(bool, true)
    dkim_signing_key_length          = optional(string, "RSA_2048_BIT")
    mail_from_domain                 = optional(string)
    mail_from_behavior_on_mx_failure = optional(string, "USE_DEFAULT_VALUE")
  })
  default = null

  validation {
    condition     = var.domain_identity == null || can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.domain_identity.domain))
    error_message = "domain must be lowercase and DNS-compatible."
  }
}

variable "email_identities" {
  description = "Sandbox / dev pattern: verified email addresses. Mutually exclusive with domain_identity."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.email_identities :
      can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))
    ])
    error_message = "Each email identity must look like a valid email address."
  }

  validation {
    condition     = var.domain_identity != null || length(var.email_identities) > 0
    error_message = "Set domain_identity for production or email_identities for sandbox/dev."
  }
}

############################################
# CONFIGURATION SET
############################################

variable "configuration_set_name" {
  description = "Name of the SES configuration set."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]+$", var.configuration_set_name))
    error_message = "configuration_set_name may contain only letters, numbers, underscores, and hyphens."
  }
}

variable "create_configuration_set" {
  description = "Whether to create a configuration set."
  type        = bool
  default     = true
}

variable "assign_configuration_set" {
  description = "Attach the configuration set as the default on created identities."
  type        = bool
  default     = true
}

variable "tls_policy" {
  description = "TLS policy for the configuration set. Valid values: REQUIRE, OPTIONAL."
  type        = string
  default     = "REQUIRE"

  validation {
    condition     = contains(["REQUIRE", "OPTIONAL"], var.tls_policy)
    error_message = "tls_policy must be REQUIRE or OPTIONAL."
  }
}

variable "reputation_metrics_enabled" {
  description = "Enable reputation metrics on the configuration set."
  type        = bool
  default     = true
}

variable "sending_enabled" {
  description = "Whether sending is enabled on the configuration set."
  type        = bool
  default     = true
}

variable "create_event_destination" {
  description = "Whether to create an SNS event destination on the configuration set."
  type        = bool
  default     = true
}

variable "event_destination_name" {
  description = "Name of the configuration set event destination."
  type        = string
  default     = "sns"

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]+$", var.event_destination_name))
    error_message = "event_destination_name may contain only letters, numbers, underscores, and hyphens."
  }
}

variable "event_types" {
  description = "SES event types published to SNS."
  type        = list(string)
  default     = ["SEND", "DELIVERY", "BOUNCE", "COMPLAINT"]

  validation {
    condition = alltrue([
      for event_type in var.event_types :
      contains([
        "SEND",
        "REJECT",
        "BOUNCE",
        "COMPLAINT",
        "DELIVERY",
        "OPEN",
        "CLICK",
        "RENDERING_FAILURE",
        "DELIVERY_DELAY",
        "SUBSCRIPTION",
      ], event_type)
    ])
    error_message = "event_types contains an unsupported SES event type."
  }
}

############################################
# SNS
############################################

variable "create_sns_topic" {
  description = "Whether to create an SNS topic for SES events."
  type        = bool
  default     = true
}

variable "sns_topic_name" {
  description = "Name of the SNS topic when create_sns_topic is true. Defaults to \"{configuration_set_name}-events\"."
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "Existing SNS topic ARN when create_sns_topic is false."
  type        = string
  default     = null
}

variable "sns_email_subscriptions" {
  description = "Optional email endpoints subscribed to the events topic. Demo only; each inbox must confirm the SNS subscription."
  type        = list(string)
  default     = []
}

############################################
# IAM SENDERS
############################################

variable "create_sender_policy" {
  description = "Whether to create and attach an IAM policy that allows SendEmail / SendRawEmail."
  type        = bool
  default     = true
}

variable "sender_policy_name" {
  description = "Optional override for the sender IAM policy name."
  type        = string
  default     = null
}

variable "sender_role_names" {
  description = "IAM role names (not ARNs) that may send through the created identities."
  type        = list(string)
  default     = []
}

variable "allowed_from_addresses" {
  description = "Optional From addresses enforced by IAM condition. Empty allows any From on the verified identities."
  type        = list(string)
  default     = []
}

############################################
# ROUTE 53 (optional DNS for domain identity)
############################################

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for automatic DKIM / MAIL FROM records. Leave null to manage DNS elsewhere."
  type        = string
  default     = null
}

variable "create_route53_records" {
  description = "Create Route 53 records when route53_zone_id is set."
  type        = bool
  default     = false
}

variable "route53_record_ttl" {
  description = "TTL for created Route 53 records."
  type        = number
  default     = 600

  validation {
    condition     = var.route53_record_ttl > 0
    error_message = "route53_record_ttl must be greater than 0."
  }
}

variable "create_mail_from_spf_record" {
  description = "Create an SPF TXT record on the custom MAIL FROM subdomain."
  type        = bool
  default     = true
}

variable "create_domain_spf_record" {
  description = "Create an SPF TXT record on the sending domain."
  type        = bool
  default     = false
}
