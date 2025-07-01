# Get current AWS account ID
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Bucket
resource "aws_s3_bucket" "data_repository" {
  bucket = var.s3_bucket_name
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data_repository" {
  bucket = aws_s3_bucket.data_repository.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket EventBridge Configuration
resource "aws_s3_bucket_notification" "data_repository" {
  bucket = aws_s3_bucket.data_repository.id
  
  eventbridge = true
}

# EventBridge Custom Bus
resource "aws_cloudwatch_event_bus" "data_repository" {
  name = var.event_bus_name
}

# EventBridge Rule 1: Forward S3 Create Events to Custom Bus
resource "aws_cloudwatch_event_rule" "s3_create_events" {
  name           = "s3-create-events-to-custom-bus"
  description    = "Forward S3 ObjectCreated events to custom bus"
  event_bus_name = "default"
  
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_create_events" {
  rule           = aws_cloudwatch_event_rule.s3_create_events.name
  event_bus_name = "default"
  target_id      = "ForwardToCustomBus"
  arn            = aws_cloudwatch_event_bus.data_repository.arn
  role_arn       = aws_iam_role.eventbridge_role.arn
}

# EventBridge Rule 2: RefinerInput Prefix Events
resource "aws_cloudwatch_event_rule" "refiner_input_events" {
  name           = "refiner-input-events"
  description    = "Capture events for RefinerInput prefix"
  event_bus_name = aws_cloudwatch_event_bus.data_repository.name
  
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket_name]
      }
      object = {
        key = [{
          prefix = "RefinerInput/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "refiner_input_events" {
  rule           = aws_cloudwatch_event_rule.refiner_input_events.name
  event_bus_name = aws_cloudwatch_event_bus.data_repository.name
  target_id      = "RefinerInputQueue"
  arn            = aws_sqs_queue.refiner_input.arn
}

# EventBridge Rule 3: RefinerComplete Prefix Events
resource "aws_cloudwatch_event_rule" "refiner_complete_events" {
  name           = "refiner-complete-events"
  description    = "Capture events for RefinerComplete prefix"
  event_bus_name = aws_cloudwatch_event_bus.data_repository.name
  
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket_name]
      }
      object = {
        key = [{
          prefix = "RefinerComplete/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "refiner_complete_events" {
  rule           = aws_cloudwatch_event_rule.refiner_complete_events.name
  event_bus_name = aws_cloudwatch_event_bus.data_repository.name
  target_id      = "RefinerCompleteQueue"
  arn            = aws_sqs_queue.refiner_complete.arn
}

# SQS Dead Letter Queues
resource "aws_sqs_queue" "refiner_input_dlq" {
  name = "dibbs-ecr-RefinerInput-dlq"
}

resource "aws_sqs_queue" "refiner_complete_dlq" {
  name = "dibbs-ecr-RefinerComplete-dlq"
}

# SQS Main Queues
resource "aws_sqs_queue" "refiner_input" {
  name = "dibbs-ecr-RefinerInput"
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.refiner_input_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  
  delay_seconds = 20
  visibility_timeout_seconds = 910

}

resource "aws_sqs_queue_policy" "refiner_input_policy" {
  queue_url = aws_sqs_queue.refiner_input.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.refiner_input.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn": aws_cloudwatch_event_rule.refiner_input_events.arn
          }
        }
      }
    ]
  })
} 

resource "aws_sqs_queue" "refiner_complete" {
  name = "dibbs-ecr-RefinerComplete"
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.refiner_complete_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  
  delay_seconds = 20
  visibility_timeout_seconds = 910
}

# ECR Repository
resource "aws_ecr_repository" "lambda" {
  name                 = "dibbs-aims-helloworld/lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Repository Policy to allow Lambda to pull images
resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.lambda.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPull"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

# Push scratch image to ECR to allow initial Lambda creation
resource "null_resource" "push_scratch_image" {
  triggers = {
    ecr_repository = aws_ecr_repository.lambda.repository_url
  }

  provisioner "local-exec" {
    command = <<EOF
      docker pull alpine
      docker tag alpine ${aws_ecr_repository.lambda.repository_url}:latest
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda.repository_url}
      docker push ${aws_ecr_repository.lambda.repository_url}:latest
    EOF
  }

  depends_on = [
    aws_ecr_repository.lambda,
    aws_ecr_repository_policy.policy
  ]
}



# Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.lambda_function_name}-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom inline policy for S3, SQS, and ECR access
resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.lambda_function_name}-custom-policy"
  role = aws_iam_role.lambda_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.data_repository.arn,
          "${aws_s3_bucket.data_repository.arn}/RefinerInput/*",
          "${aws_s3_bucket.data_repository.arn}/RefinerOutput/*",
          "${aws_s3_bucket.data_repository.arn}/RefinerComplete/*"
        ]
      },
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect = "Allow"
        Resource = aws_sqs_queue.refiner_input.arn
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Effect = "Allow"
        Resource = aws_ecr_repository.lambda.arn
      },
      {
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# EventBridge Role for forwarding events
resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge-s3-forwarding-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "eventbridge-s3-forwarding-policy"
  role = aws_iam_role.eventbridge_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "events:PutEvents"
        Effect = "Allow"
        Resource = aws_cloudwatch_event_bus.data_repository.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "refiner" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_image_uri}:${var.ecr_image_tag}"
  architectures = ["arm64"]
  
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout
  
  environment {
    variables = {
      REFINER_OUTPUT_PREFIX   = "RefinerOutput/"
      REFINER_COMPLETE_PREFIX = "RefinerComplete/"
    }
  }

  depends_on = [
    null_resource.push_scratch_image
  ]
}

# Lambda Event Source Mapping
resource "aws_lambda_event_source_mapping" "refiner_input" {
  event_source_arn = aws_sqs_queue.refiner_input.arn
  function_name    = aws_lambda_function.refiner.function_name
  batch_size       = 1
} 