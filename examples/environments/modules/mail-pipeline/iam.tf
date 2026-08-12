data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "producer" {
  name               = "${var.name_prefix}-mail-producer"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "worker" {
  name               = "${var.name_prefix}-mail-worker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "producer_basic" {
  role       = aws_iam_role.producer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "worker_basic" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "producer" {
  statement {
    sid    = "EnqueueMail"
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [aws_sqs_queue.mail.arn]
  }

  statement {
    sid    = "GdsSpoolReadWrite"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.gds_spool.arn,
      "${aws_s3_bucket.gds_spool.arn}/*",
    ]
  }

  statement {
    sid    = "InvokeSiblingProducers"
    effect = "Allow"

    actions = ["lambda:InvokeFunction"]

    resources = [
      "arn:aws:lambda:${var.aws_region}:*:function:${var.name_prefix}-*",
    ]
  }
}

resource "aws_iam_role_policy" "producer" {
  name   = "${var.name_prefix}-mail-producer"
  role   = aws_iam_role.producer.id
  policy = data.aws_iam_policy_document.producer.json
}

data "aws_iam_policy_document" "worker_queue" {
  statement {
    sid    = "ConsumeMailQueue"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]

    resources = [aws_sqs_queue.mail.arn]
  }
}

resource "aws_iam_role_policy" "worker_queue" {
  name   = "${var.name_prefix}-mail-worker-queue"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.worker_queue.json
}
