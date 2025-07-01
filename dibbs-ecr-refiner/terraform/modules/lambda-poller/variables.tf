variable "prefix" {
  description = "Prefix for the refiner pipeline (e.g., /RefinerInput/)"
  type        = string
}

variable "ecr_image_uri" {
  description = "ECR image URI for the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for data repository"
  type        = string
}

variable "event_bus_name" {
  description = "Name of the custom EventBridge bus"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to DLQ"
  type        = number
} 

variable "ecr_image_tag" {
  description = "Tag for the ECR image"
  type        = string
}