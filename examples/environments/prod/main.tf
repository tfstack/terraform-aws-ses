# Prod example — same SeisComP mechanism stand-ins as dev; domain identity for SES.
#
# After apply:
#   1. Publish DNS if Route 53 is not managing records.
#   2. Wait for domain / DKIM verification.
#   3. terraform output -raw e2e_all_command | bash

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = merge(
    var.tags,
    {
      Environment = "prod"
      ManagedBy   = "terraform"
    },
  )
}

module "mail_pipeline" {
  source = "../modules/mail-pipeline"

  name_prefix            = var.name_prefix
  aws_region             = var.aws_region
  configuration_set_name = var.configuration_set_name
  default_from_address   = var.test_from_address
  default_to_address     = var.test_to_address
  enable_alarms          = var.enable_alarms

  tags = local.tags
}

module "ses" {
  source = "../../.."

  configuration_set_name = var.configuration_set_name

  domain_identity = {
    domain                           = var.domain
    mail_from_domain                 = var.mail_from_domain
    mail_from_behavior_on_mx_failure = var.mail_from_behavior_on_mx_failure
    enable_easy_dkim                 = var.enable_easy_dkim
  }

  route53_zone_id          = var.route53_zone_id
  create_route53_records   = var.create_route53_records
  create_domain_spf_record = var.create_domain_spf_record

  sender_role_names      = [module.mail_pipeline.worker_role_name]
  allowed_from_addresses = var.allowed_from_addresses

  sns_email_subscriptions = var.sns_email_subscriptions

  tags = local.tags

  depends_on = [module.mail_pipeline]
}

output "ses" {
  description = "SES module outputs."
  value       = module.ses
}

output "mail_pipeline" {
  description = "Queue, SeisComP mechanism Lambdas, GDS spool bucket, worker."
  value       = module.mail_pipeline
}

output "e2e_all_command" {
  description = "Trigger mailx + scalert + TOAST/GDS → SQS → SES."
  value       = module.mail_pipeline.e2e_all_command
}
