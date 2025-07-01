variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "prefix" {
  description = "Prefix for the refiner pipeline (e.g., /RefinerInput/)"
  type        = string
  default     = "/RefinerInput/"
}

variable "ecr_image_uri" {
  description = "ECR image URI for the Lambda function"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/dibbs-ecr-refiner/lambda:latest"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for data repository"
  type        = string
  default     = "data-repository"
}

variable "event_bus_name" {
  description = "Name of the custom EventBridge bus"
  type        = string
  default     = "data-repository-bus"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "dibbs-ecr-refiner-lambda"
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 900
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to DLQ"
  type        = number
  default     = 5
} 

variable "ecr_image_tag" {
  description = "Tag for the ECR image"
  type        = string
  default     = "latest"
}