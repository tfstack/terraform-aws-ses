mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "ap-southeast-2"
    }
  }

  mock_resource "aws_sesv2_email_identity" {
    defaults = {
      arn                 = "arn:aws:ses:ap-southeast-2:123456789012:identity/example.com"
      verification_status = "PENDING"
      identity_type       = "DOMAIN"
    }
  }

  mock_resource "aws_sesv2_configuration_set" {
    defaults = {
      arn = "arn:aws:ses:ap-southeast-2:123456789012:configuration-set/example"
    }
  }
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "sandbox_email_identities" {
  command = plan

  variables {
    configuration_set_name = "app-mail-${run.setup.suffix}"
    email_identities = [
      "sandbox-${run.setup.suffix}@example.com",
      "alerts-${run.setup.suffix}@example.com",
    ]

    sender_role_names = ["demo-app-${run.setup.suffix}"]
    allowed_from_addresses = [
      "sandbox-${run.setup.suffix}@example.com",
      "alerts-${run.setup.suffix}@example.com",
    ]

    sns_email_subscriptions = [
      "events-${run.setup.suffix}@example.com",
    ]

    tags = {
      Environment = "dev"
      Example     = "sandbox"
    }
  }

  assert {
    condition     = length(aws_sesv2_email_identity.email) == 2
    error_message = "Expected two email identities in sandbox mode."
  }

  assert {
    condition     = length(aws_sesv2_email_identity.domain) == 0
    error_message = "Domain identity should not be created in sandbox mode."
  }

  assert {
    condition     = aws_sesv2_configuration_set.this[0].configuration_set_name == "app-mail-${run.setup.suffix}"
    error_message = "Configuration set name does not match."
  }

  assert {
    condition     = aws_sesv2_configuration_set.this[0].delivery_options[0].tls_policy == "REQUIRE"
    error_message = "TLS policy should default to REQUIRE."
  }

  assert {
    condition     = contains(aws_sesv2_configuration_set_event_destination.this[0].event_destination[0].matching_event_types, "DELIVERY")
    error_message = "Event destination should include DELIVERY."
  }

  assert {
    condition     = aws_sns_topic.events[0].name == "app-mail-${run.setup.suffix}-events"
    error_message = "SNS topic name should derive from the configuration set."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.sender) == 1
    error_message = "Sender policy should attach to one role."
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 1
    error_message = "Demo email subscription should be created when configured."
  }
}

run "production_domain_identity" {
  command = plan

  variables {
    configuration_set_name = "app-mail-prod-${run.setup.suffix}"

    domain_identity = {
      domain           = "mail-${run.setup.suffix}.example.com"
      mail_from_domain = "bounce.mail-${run.setup.suffix}.example.com"
    }

    route53_zone_id        = "Z0123456789ABCDEFGHIJ"
    create_route53_records = true

    sender_role_names = [
      "app-mail-${run.setup.suffix}",
      "worker-mail-${run.setup.suffix}",
    ]

    allowed_from_addresses = [
      "noreply@mail-${run.setup.suffix}.example.com",
      "alerts@mail-${run.setup.suffix}.example.com",
    ]

    sns_email_subscriptions = []

    tags = {
      Environment = "prod"
      Example     = "production"
    }
  }

  override_resource {
    target = aws_sesv2_email_identity.domain[0]

    values = {
      dkim_signing_attributes = {
        tokens = ["token1", "token2", "token3"]
      }
    }
  }

  assert {
    condition     = length(aws_sesv2_email_identity.domain) == 1
    error_message = "Expected one domain identity in production mode."
  }

  assert {
    condition     = length(aws_sesv2_email_identity.email) == 0
    error_message = "Email identities should not be created in production mode."
  }

  assert {
    condition     = aws_sesv2_email_identity.domain[0].email_identity == "mail-${run.setup.suffix}.example.com"
    error_message = "Domain identity name does not match."
  }

  assert {
    condition     = aws_sesv2_email_identity_mail_from_attributes.domain[0].mail_from_domain == "bounce.mail-${run.setup.suffix}.example.com"
    error_message = "Custom MAIL FROM domain does not match."
  }

  assert {
    condition     = length(aws_route53_record.dkim) == 3
    error_message = "Three DKIM CNAME records should be planned when Route 53 is enabled."
  }

  assert {
    condition     = length(aws_route53_record.mail_from_mx) == 1
    error_message = "MAIL FROM MX record should be planned."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.sender) == 2
    error_message = "Sender policy should attach to both production roles."
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 0
    error_message = "Production example should not create email SNS subscriptions by default."
  }
}
