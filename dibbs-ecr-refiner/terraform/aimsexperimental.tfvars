# AWS Configuration
aws_region = "us-east-1"
environment = "dev"

# S3 Configuration
s3_bucket_name = "data-repository-aims-experimental-dev"

# EventBridge Configuration
event_bus_name = "data-repository-aims-experimental-dev-bus"

# Lambda Configuration
lambda_function_name = "dibbs-aims-helloworld-lambda"
lambda_memory_size  = 1024
lambda_timeout      = 900

# SQS Configuration
max_receive_count = 5

# ECR Configuration
# Update this with your actual ECR image URI after building and pushing
ecr_image_uri = "568730490820.dkr.ecr.us-east-1.amazonaws.com/dibbs-aims-helloworld/lambda"
ecr_image_tag = "latest"

# Prefix Configuration
prefix = "/RefinerInput/" 