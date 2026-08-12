output "configuration_set_name" {
  description = "Name of the SES configuration set."
  value       = try(aws_sesv2_configuration_set.this[0].configuration_set_name, null)
}

output "configuration_set_arn" {
  description = "ARN of the SES configuration set."
  value       = try(aws_sesv2_configuration_set.this[0].arn, null)
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic receiving SES events."
  value       = local.sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the created SNS topic."
  value       = try(aws_sns_topic.events[0].name, null)
}

output "domain_identity_arn" {
  description = "ARN of the domain identity when domain_identity is set."
  value       = try(aws_sesv2_email_identity.domain[0].arn, null)
}

output "domain_identity_verification_status" {
  description = "Verification status of the domain identity."
  value       = try(aws_sesv2_email_identity.domain[0].verification_status, null)
}

output "email_identity_arns" {
  description = "Map of email address to identity ARN."
  value       = { for email, identity in aws_sesv2_email_identity.email : email => identity.arn }
}

output "email_identity_verification_status" {
  description = "Map of email address to verification status."
  value       = { for email, identity in aws_sesv2_email_identity.email : email => identity.verification_status }
}

output "dkim_tokens" {
  description = "Easy DKIM tokens for the domain identity. Create CNAME records unless Route 53 is managing them."
  value       = local.dkim_tokens
}

output "mail_from_domain" {
  description = "Custom MAIL FROM domain when configured."
  value       = local.mail_from_domain
}

output "sender_policy_arn" {
  description = "ARN of the IAM sender policy when created."
  value       = try(aws_iam_policy.sender[0].arn, null)
}

output "identity_arns" {
  description = "All created identity ARNs."
  value       = local.identity_arns
}
