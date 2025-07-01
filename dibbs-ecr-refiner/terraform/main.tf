terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "dibbs-aims-helloworld"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}


# Call the refiner module
module "helloworld" {
  source = "./modules/lambda-poller"
  
  # Module variables
  prefix                    = var.prefix
  ecr_image_uri            = var.ecr_image_uri
  environment              = var.environment
  s3_bucket_name           = var.s3_bucket_name
  event_bus_name           = var.event_bus_name
  lambda_function_name     = var.lambda_function_name
  lambda_memory_size      = var.lambda_memory_size
  lambda_timeout          = var.lambda_timeout
  max_receive_count       = var.max_receive_count
  ecr_image_tag           = var.ecr_image_tag
} 