locals {
  use_domain_identity = var.domain_identity != null

  domain_name = local.use_domain_identity ? var.domain_identity.domain : null

  mail_from_domain = local.use_domain_identity && try(var.domain_identity.mail_from_domain, null) != null ? var.domain_identity.mail_from_domain : null

  assign_configuration_set = var.create_configuration_set && var.assign_configuration_set ? aws_sesv2_configuration_set.this[0].configuration_set_name : null

  identity_arns = local.use_domain_identity ? [aws_sesv2_email_identity.domain[0].arn] : [for identity in aws_sesv2_email_identity.email : identity.arn]

  sns_topic_name = coalesce(var.sns_topic_name, "${var.configuration_set_name}-events")

  sns_topic_arn = var.create_sns_topic ? aws_sns_topic.events[0].arn : var.sns_topic_arn

  sns_topic_configured = var.create_sns_topic || var.sns_topic_arn != null

  event_destination_enabled = var.create_configuration_set && var.create_event_destination && local.sns_topic_configured

  dkim_tokens = local.use_domain_identity ? aws_sesv2_email_identity.domain[0].dkim_signing_attributes[0].tokens : []

  create_dns_records = local.use_domain_identity && var.route53_zone_id != null && var.create_route53_records
}
