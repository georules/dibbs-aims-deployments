output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data_repository.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.data_repository.arn
}

output "event_bus_arn" {
  description = "ARN of the custom EventBridge bus"
  value       = aws_cloudwatch_event_bus.data_repository.arn
}

output "event_bus_name" {
  description = "Name of the custom EventBridge bus"
  value       = aws_cloudwatch_event_bus.data_repository.name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.refiner.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.refiner.function_name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "sqs_queue_urls" {
  description = "URLs of the SQS queues"
  value = {
    refiner_input    = aws_sqs_queue.refiner_input.url
    refiner_complete = aws_sqs_queue.refiner_complete.url
    refiner_input_dlq    = aws_sqs_queue.refiner_input_dlq.url
    refiner_complete_dlq = aws_sqs_queue.refiner_complete_dlq.url
  }
}

output "sqs_queue_arns" {
  description = "ARNs of the SQS queues"
  value = {
    refiner_input    = aws_sqs_queue.refiner_input.arn
    refiner_complete = aws_sqs_queue.refiner_complete.arn
    refiner_input_dlq    = aws_sqs_queue.refiner_input_dlq.arn
    refiner_complete_dlq = aws_sqs_queue.refiner_complete_dlq.arn
  }
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.lambda.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.lambda.arn
} 