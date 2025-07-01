output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.helloworld.s3_bucket_name
}

output "event_bus_arn" {
  description = "ARN of the custom EventBridge bus"
  value       = module.helloworld.event_bus_arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.helloworld.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.helloworld.lambda_function_name
}

output "sqs_queue_urls" {
  description = "URLs of the SQS queues"
  value       = module.helloworld.sqs_queue_urls
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.helloworld.ecr_repository_url
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.helloworld.lambda_execution_role_arn
} 