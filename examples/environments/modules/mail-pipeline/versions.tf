terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  queue_name = "${var.name_prefix}-mail"
  dlq_name   = "${var.name_prefix}-mail-dlq"
  spool_name = "${var.name_prefix}-gds-spool-${data.aws_caller_identity.current.account_id}"

  mailx_fn_name       = "${var.name_prefix}-mailx"
  scalert_fn_name     = "${var.name_prefix}-scalert"
  toast_fn_name       = "${var.name_prefix}-toast"
  gds_spooler_fn_name = "${var.name_prefix}-gds-spooler"
  e2e_all_fn_name     = "${var.name_prefix}-e2e-all"
  worker_fn_name      = "${var.name_prefix}-mail-worker"
}
