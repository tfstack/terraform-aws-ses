locals {
  producer_env = {
    QUEUE_URL    = aws_sqs_queue.mail.url
    DEFAULT_FROM = var.default_from_address
    DEFAULT_TO   = var.default_to_address
    SPOOL_BUCKET = aws_s3_bucket.gds_spool.id
  }

  lambda_runtime = "python3.14"
}

resource "aws_cloudwatch_log_group" "mailx" {
  name              = "/aws/lambda/${local.mailx_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "scalert" {
  name              = "/aws/lambda/${local.scalert_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "toast" {
  name              = "/aws/lambda/${local.toast_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "gds_spooler" {
  name              = "/aws/lambda/${local.gds_spooler_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "e2e_all" {
  name              = "/aws/lambda/${local.e2e_all_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/aws/lambda/${local.worker_fn_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

data "archive_file" "mailx" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/mailx"
  output_path = "${path.module}/mailx.zip"
}

data "archive_file" "scalert" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/scalert"
  output_path = "${path.module}/scalert.zip"
}

data "archive_file" "toast" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/toast"
  output_path = "${path.module}/toast.zip"
}

data "archive_file" "gds_spooler" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/gds_spooler"
  output_path = "${path.module}/gds_spooler.zip"
}

data "archive_file" "e2e_all" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/e2e_all"
  output_path = "${path.module}/e2e_all.zip"
}

data "archive_file" "worker" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/worker"
  output_path = "${path.module}/worker.zip"
}

resource "aws_lambda_function" "mailx" {
  function_name = local.mailx_fn_name
  role          = aws_iam_role.producer.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 10
  memory_size   = 256

  filename         = data.archive_file.mailx.output_path
  source_code_hash = data.archive_file.mailx.output_base64sha256

  environment {
    variables = local.producer_env
  }

  depends_on = [aws_iam_role_policy.producer, aws_cloudwatch_log_group.mailx]
  tags       = merge(var.tags, { Mechanism = "mailx" })
}

resource "aws_lambda_function" "scalert" {
  function_name = local.scalert_fn_name
  role          = aws_iam_role.producer.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 10
  memory_size   = 256

  filename         = data.archive_file.scalert.output_path
  source_code_hash = data.archive_file.scalert.output_base64sha256

  environment {
    variables = local.producer_env
  }

  depends_on = [aws_iam_role_policy.producer, aws_cloudwatch_log_group.scalert]
  tags       = merge(var.tags, { Mechanism = "scalert" })
}

resource "aws_lambda_function" "toast" {
  function_name = local.toast_fn_name
  role          = aws_iam_role.producer.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 10
  memory_size   = 256

  filename         = data.archive_file.toast.output_path
  source_code_hash = data.archive_file.toast.output_base64sha256

  environment {
    variables = local.producer_env
  }

  depends_on = [aws_iam_role_policy.producer, aws_cloudwatch_log_group.toast]
  tags       = merge(var.tags, { Mechanism = "toast" })
}

resource "aws_lambda_function" "gds_spooler" {
  function_name = local.gds_spooler_fn_name
  role          = aws_iam_role.producer.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.gds_spooler.output_path
  source_code_hash = data.archive_file.gds_spooler.output_base64sha256

  environment {
    variables = local.producer_env
  }

  depends_on = [aws_iam_role_policy.producer, aws_cloudwatch_log_group.gds_spooler]
  tags       = merge(var.tags, { Mechanism = "gds" })
}

resource "aws_lambda_permission" "gds_spooler_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gds_spooler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.gds_spool.arn
}

resource "aws_s3_bucket_notification" "gds_spool" {
  bucket = aws_s3_bucket.gds_spool.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.gds_spooler.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = "bulletin.body"
  }

  depends_on = [aws_lambda_permission.gds_spooler_s3]
}

resource "aws_lambda_function" "e2e_all" {
  function_name = local.e2e_all_fn_name
  role          = aws_iam_role.producer.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.e2e_all.output_path
  source_code_hash = data.archive_file.e2e_all.output_base64sha256

  environment {
    variables = merge(local.producer_env, {
      MAILX_FUNCTION   = aws_lambda_function.mailx.function_name
      SCALERT_FUNCTION = aws_lambda_function.scalert.function_name
      TOAST_FUNCTION   = aws_lambda_function.toast.function_name
    })
  }

  depends_on = [
    aws_iam_role_policy.producer,
    aws_cloudwatch_log_group.e2e_all,
    aws_lambda_function.mailx,
    aws_lambda_function.scalert,
    aws_lambda_function.toast,
  ]
  tags = merge(var.tags, { Mechanism = "e2e-all" })
}

resource "aws_lambda_function" "worker" {
  function_name = local.worker_fn_name
  role          = aws_iam_role.worker.arn
  handler       = "handler.handler"
  runtime       = local.lambda_runtime
  timeout       = var.worker_timeout_seconds
  memory_size   = 256

  filename         = data.archive_file.worker.output_path
  source_code_hash = data.archive_file.worker.output_base64sha256

  reserved_concurrent_executions = var.worker_reserved_concurrency

  environment {
    variables = {
      AWS_REGION_NAME        = var.aws_region
      CONFIGURATION_SET_NAME = var.configuration_set_name
    }
  }

  depends_on = [aws_iam_role_policy.worker_queue, aws_cloudwatch_log_group.worker]
  tags       = var.tags
}

resource "aws_lambda_event_source_mapping" "worker" {
  event_source_arn = aws_sqs_queue.mail.arn
  function_name    = aws_lambda_function.worker.arn

  batch_size                         = var.worker_batch_size
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.worker_max_concurrency
  }
}
