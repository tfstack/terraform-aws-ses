############################################
# IDENTITIES
############################################

resource "aws_sesv2_email_identity" "domain" {
  count = local.use_domain_identity ? 1 : 0

  email_identity = var.domain_identity.domain

  configuration_set_name = local.assign_configuration_set

  dynamic "dkim_signing_attributes" {
    for_each = try(var.domain_identity.enable_easy_dkim, true) ? [1] : []

    content {
      next_signing_key_length = try(var.domain_identity.dkim_signing_key_length, "RSA_2048_BIT")
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.email_identities) == 0
      error_message = "Use either domain_identity or email_identities, not both."
    }
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  count = local.use_domain_identity && local.mail_from_domain != null ? 1 : 0

  email_identity         = aws_sesv2_email_identity.domain[0].email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = try(var.domain_identity.mail_from_behavior_on_mx_failure, "USE_DEFAULT_VALUE")
}

resource "aws_sesv2_email_identity" "email" {
  for_each = toset(var.email_identities)

  email_identity = each.value

  configuration_set_name = local.assign_configuration_set

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.domain_identity == null
      error_message = "Use either domain_identity or email_identities, not both."
    }
  }
}

############################################
# CONFIGURATION SET
############################################

resource "aws_sesv2_configuration_set" "this" {
  count = var.create_configuration_set ? 1 : 0

  configuration_set_name = var.configuration_set_name

  delivery_options {
    tls_policy = var.tls_policy
  }

  reputation_options {
    reputation_metrics_enabled = var.reputation_metrics_enabled
  }

  sending_options {
    sending_enabled = var.sending_enabled
  }

  tags = var.tags
}

resource "aws_sesv2_configuration_set_event_destination" "this" {
  count = local.event_destination_enabled ? 1 : 0

  configuration_set_name = aws_sesv2_configuration_set.this[0].configuration_set_name
  event_destination_name = var.event_destination_name

  event_destination {
    enabled              = true
    matching_event_types = var.event_types

    sns_destination {
      topic_arn = local.sns_topic_arn
    }
  }

  depends_on = [
    aws_sns_topic_policy.ses_publish,
  ]
}

############################################
# SNS EVENTS
############################################

resource "aws_sns_topic" "events" {
  count = var.create_sns_topic ? 1 : 0

  name = local.sns_topic_name
  tags = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "sns_ses_publish" {
  count = local.event_destination_enabled ? 1 : 0

  statement {
    sid    = "AllowSESPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = ["SNS:Publish"]

    resources = var.create_sns_topic ? [aws_sns_topic.events[0].arn] : [var.sns_topic_arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_sesv2_configuration_set.this[0].arn]
    }
  }
}

resource "aws_sns_topic_policy" "ses_publish" {
  count = length(data.aws_iam_policy_document.sns_ses_publish) > 0 ? 1 : 0

  arn    = local.sns_topic_arn
  policy = data.aws_iam_policy_document.sns_ses_publish[0].json
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.create_sns_topic && length(var.sns_email_subscriptions) > 0 ? toset(var.sns_email_subscriptions) : toset([])

  topic_arn = local.sns_topic_arn
  protocol  = "email"
  endpoint  = each.value
}

############################################
# IAM SENDERS
############################################

data "aws_iam_policy_document" "sender" {
  count = var.create_sender_policy && length(var.sender_role_names) > 0 ? 1 : 0

  statement {
    sid    = "AllowSendFromVerifiedIdentities"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = concat(
      local.identity_arns,
      [for arn in local.identity_arns : "${arn}/*"],
    )

    dynamic "condition" {
      for_each = length(var.allowed_from_addresses) > 0 ? [1] : []

      content {
        test     = "ForAllValues:StringLike"
        variable = "ses:FromAddress"
        values   = var.allowed_from_addresses
      }
    }
  }

  dynamic "statement" {
    for_each = var.create_configuration_set ? [1] : []

    content {
      sid    = "AllowConfigurationSetUsage"
      effect = "Allow"

      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail",
      ]

      resources = [
        aws_sesv2_configuration_set.this[0].arn,
      ]
    }
  }
}

resource "aws_iam_policy" "sender" {
  count = length(data.aws_iam_policy_document.sender) > 0 ? 1 : 0

  name        = coalesce(var.sender_policy_name, "${var.configuration_set_name}-send")
  description = "Send mail through SES identities managed by terraform-aws-ses"
  policy      = data.aws_iam_policy_document.sender[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "sender" {
  for_each = length(data.aws_iam_policy_document.sender) > 0 ? toset(var.sender_role_names) : toset([])

  role       = each.value
  policy_arn = aws_iam_policy.sender[0].arn
}

############################################
# ROUTE 53 (optional DNS for domain identity)
############################################

resource "aws_route53_record" "dkim" {
  count = local.create_dns_records && try(var.domain_identity.enable_easy_dkim, true) ? 3 : 0

  zone_id = var.route53_zone_id
  name    = "${element(local.dkim_tokens, count.index)}._domainkey.${local.domain_name}"
  type    = "CNAME"
  ttl     = var.route53_record_ttl
  records = ["${element(local.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "mail_from_mx" {
  count = local.create_dns_records && local.mail_from_domain != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = local.mail_from_domain
  type    = "MX"
  ttl     = var.route53_record_ttl
  records = ["10 feedback-smtp.${data.aws_region.current.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  count = local.create_dns_records && local.mail_from_domain != null && var.create_mail_from_spf_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = var.route53_record_ttl
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "domain_spf" {
  count = local.create_dns_records && var.create_domain_spf_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = local.domain_name
  type    = "TXT"
  ttl     = var.route53_record_ttl
  records = ["v=spf1 include:amazonses.com -all"]
}
