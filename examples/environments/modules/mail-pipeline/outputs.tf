output "queue_url" {
  description = "Shared mail queue URL (all mechanisms enqueue here)."
  value       = aws_sqs_queue.mail.url
}

output "spool_bucket" {
  description = "S3 bucket standing in for the GDS spool directory."
  value       = aws_s3_bucket.gds_spool.id
}

output "worker_role_name" {
  description = "IAM role name passed to the SES module sender_role_names."
  value       = aws_iam_role.worker.name
}

output "worker_role_arn" {
  description = "IAM role ARN for the mail worker."
  value       = aws_iam_role.worker.arn
}

output "functions" {
  description = "SeisComP mechanism stand-in Lambdas."
  value = {
    mailx       = aws_lambda_function.mailx.function_name
    scalert     = aws_lambda_function.scalert.function_name
    toast       = aws_lambda_function.toast.function_name
    gds_spooler = aws_lambda_function.gds_spooler.function_name
    e2e_all     = aws_lambda_function.e2e_all.function_name
    worker      = aws_lambda_function.worker.function_name
  }
}

output "e2e_all_command" {
  description = "Trigger mailx + scalert + TOAST/GDS stand-ins in one invoke."
  value       = "aws lambda invoke --function-name ${aws_lambda_function.e2e_all.function_name} --cli-binary-format raw-in-base64-out --payload '{}' /tmp/ses-e2e-all.json && cat /tmp/ses-e2e-all.json"
}

output "e2e_mailx_command" {
  description = "scm / mailx stand-in only."
  value       = "aws lambda invoke --function-name ${aws_lambda_function.mailx.function_name} --cli-binary-format raw-in-base64-out --payload '{\"subject\":\"mailx / scm health\",\"body\":\"hello from mailx\"}' /tmp/ses-mailx.json && cat /tmp/ses-mailx.json"
}

output "e2e_scalert_command" {
  description = "scalert script stand-in only."
  value       = "aws lambda invoke --function-name ${aws_lambda_function.scalert.function_name} --cli-binary-format raw-in-base64-out --payload '{\"type\":\"event\",\"publicID\":\"demo-origin-1\",\"message\":\"hello from scalert\"}' /tmp/ses-scalert.json && cat /tmp/ses-scalert.json"
}

output "e2e_toast_gds_command" {
  description = "TOAST writes GDS spool; gds_spooler enqueues on S3 create."
  value       = "aws lambda invoke --function-name ${aws_lambda_function.toast.function_name} --cli-binary-format raw-in-base64-out --payload '{\"subject\":\"TOAST bulletin\",\"body\":\"hello from toast/gds\"}' /tmp/ses-toast.json && cat /tmp/ses-toast.json"
}
