# dibbs-ecr-refiner Deployment Guide

This guide walks you through deploying the complete dibbs-ecr-refiner infrastructure and application.

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Docker** - [Installation Guide](https://docs.docker.com/get-docker/)
- **Terraform** - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)
- **Node.js 18+** - [Installation Guide](https://nodejs.org/en/download/)

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Run the setup script
./scripts/setup_environment.sh

# Source the environment variables
source .env

# Configure AWS credentials
aws configure
```

### 2. Update Configuration

Edit the `.env` file with your actual values:

```bash
# AWS Configuration
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=123456789012

# S3 Configuration
export S3_BUCKET_NAME=data-repository

# GitHub Configuration (for CI/CD)
export GITHUB_ORG=your-github-org
export GITHUB_USERNAME=your-github-username
export GITHUB_TOKEN=your-github-token

# GitLab Configuration (for CI/CD)
export GITLAB_PROJECT_ID=your-gitlab-project-id

# ECR Configuration
export ECR_REPO=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/dibbs-ecr-refiner/lambda
```

### 3. Build and Push Docker Image

This helloworld image is made to demonstrate a data pipeline, so that we can integrate other real dibbs services in the future.

```bash
# Build the Docker image
cd lambda
docker build --platform linux/arm64 --provenance=false -t dibbs-aims-helloworld:latest .

# Tag for GitHub Container Registry
docker tag dibbs-aims-helloworld:latest ghcr.io/${GITHUB_ORG}/dibbs-aims-helloworld:latest

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Push to GitHub Container Registry
docker push ghcr.io/${GITHUB_ORG}/dibbs-aims-helloworld:latest

```

### 4. Deploy Infrastructure

This will push a temporary alpine image to ECR, 

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="terraform.tfvars"

# Apply the deployment
terraform apply -var-file="terraform.tfvars" -auto-approve
```

### 5. Sync Image to ECR

This simulates what would happen in a CI/CD step in gitlab later to pull from github and push to ECR.
```bash
# Login to ECR
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

# Pull from GitHub and push to ECR
docker pull ghcr.io/${GITHUB_ORG}/dibbs-aims-helloworld:latest
docker tag ghcr.io/${GITHUB_ORG}/dibbs-aims-helloworld:latest ${ECR_REPO}:latest

docker push ${ECR_REPO}:latest
```

For development using the helloworld image, we can also just build and push directly:

```bash
cd lambda
docker build --platform linux/arm64 --provenance=false -t dibbs-aims-helloworld:latest .

# Login to ECR
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

docker tag dibbs-aims-helloworld:latest ${ECR_REPO}:latest

docker push ${ECR_REPO}:latest
```

For development on `latest` tag (not using versions or shasums), lambda needs to be notified to update.

```bash
aws lambda update-function-code --function-name (function_name from terraform output) --image-uri ${ECR_REPO}
```

### 6. Test the Deployment

```bash
# Upload a test file
./scripts/push_test_file.sh

# Poll for completion files
node scripts/poll_completion.js

# Or run the full test
node scripts/test_deployment.js

# Or use npm scripts
cd scripts && npm run test
```

## 🔄 CI/CD Pipeline Deployment

### GitLab CI/CD Setup

1. **Configure GitLab Variables**:
   - Go to your GitLab project → Settings → CI/CD → Variables
   - Add the following protected variables:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `GITHUB_TOKEN`
     - `GITHUB_USERNAME`
     - `GITHUB_ORG`
     - `AWS_ACCOUNT_ID`

2. **Create a Release Tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Monitor the Pipeline**:
   - Go to your GitLab project → CI/CD → Pipelines
   - The pipeline will automatically:
     - Build the Docker image
     - Push to GitHub Container Registry
     - Sync to Amazon ECR
     - Deploy with Terraform

### Manual Pipeline Execution

```bash
# Trigger a manual deployment
git tag v1.0.1
git push origin v1.0.1
```

## 🧪 Testing

### Manual Testing

1. **Upload Test File**:
   ```bash
   ./scripts/push_test_file.sh
   ```

2. **Monitor Processing**:
   ```bash
   # Poll for completion files
   node scripts/poll_completion.js
   
   # Or run full test
   node scripts/test_deployment.js
   
   # Or use npm scripts
   cd scripts && npm run test
   ```

3. **Check AWS Console**:
   - **S3**: Verify files in `RefinerInput/`, `RefinerOutput/`, and `RefinerComplete/`
   - **Lambda**: Check function logs in CloudWatch
   - **SQS**: Monitor queue metrics
   - **EventBridge**: Verify event rules

### Automated Testing

The CI/CD pipeline includes automated testing:

```yaml
test-deployment:
  stage: deploy
  image: node:18-alpine
  before_script:
    - cd scripts
    - npm install
  script:
    - node test_deployment.js
  only:
    - tags
  dependencies:
    - deploy
  when: manual
```

## 🔧 Troubleshooting

### Common Issues

1. **S3 Bucket Already Exists**:
   ```bash
   # Update the bucket name in terraform/variables.tf
   s3_bucket_name = "your-unique-bucket-name"
   ```

2. **ECR Repository Not Found**:
   ```bash
   # Create ECR repository manually
   aws ecr create-repository --repository-name dibbs-aims-helloworld/lambda
   ```

3. **Lambda Function Errors**:
   ```bash
   # Check CloudWatch logs
   aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/dibbs-ecr-refiner"
   ```

4. **SQS Message Processing Issues**:
   ```bash
   # Check dead letter queue
   aws sqs get-queue-attributes --queue-url <DLQ_URL> --attribute-names All
   ```

5. **Node.js Dependencies Issues**:
   ```bash
   # Install dependencies
   cd scripts && npm install
   
   # Check Node.js version
   node --version
   ```

### Logs and Monitoring

- **Lambda Logs**: CloudWatch → Log Groups → `/aws/lambda/dibbs-ecr-refiner-lambda`
- **SQS Metrics**: SQS → Queues → Monitor metrics
- **EventBridge**: CloudWatch → Events → Monitor event delivery

## 🧹 Cleanup

To destroy the infrastructure:

```bash
cd terraform
terraform destroy -auto-approve
```

**Warning**: This will delete all resources including S3 bucket and its contents.

## 📚 Additional Resources

- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/)
- [Amazon SQS](https://docs.aws.amazon.com/sqs/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/) 