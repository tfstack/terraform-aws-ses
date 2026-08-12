resource "aws_cloudwatch_metric_alarm" "dlq_visible" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-mail-dlq-not-empty"
  alarm_description   = "Mail dead-letter queue has messages waiting for review."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-mail-worker-errors"
  alarm_description   = "Mail worker Lambda is returning errors."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.worker.function_name
  }

  tags = var.tags
}
