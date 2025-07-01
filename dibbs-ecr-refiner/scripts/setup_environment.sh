#!/bin/bash
# Setup script for dibbs-ecr-refiner environment

set -e

echo "🚀 Setting up dibbs-ecr-refiner environment..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "   Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "   Visit: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install it first."
    echo "   Visit: https://nodejs.org/en/download/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install it first."
    echo "   Visit: https://nodejs.org/en/download/"
    exit 1
fi

echo "✅ Required tools are installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
# AWS Configuration
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# S3 Configuration
export S3_BUCKET_NAME=data-repository

# GitHub Configuration (for CI/CD)
export GITHUB_ORG=your-github-org
export GITHUB_USERNAME=your-github-username
export GITHUB_TOKEN=your-github-token

# GitLab Configuration (for CI/CD)
export GITLAB_PROJECT_ID=your-gitlab-project-id

# ECR Configuration
export ECR_REPO=\${AWS_ACCOUNT_ID}.dkr.ecr.\${AWS_DEFAULT_REGION}.amazonaws.com/dibbs-ecr-refiner/lambda
EOF
    echo "✅ Created .env file"
    echo "⚠️  Please update the .env file with your actual values"
else
    echo "✅ .env file already exists"
fi

# Install Node.js dependencies for scripts
echo "📦 Installing Node.js dependencies for scripts..."
cd scripts
npm install
cd ..

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh
chmod +x scripts/*.js

echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update the .env file with your actual values"
echo "2. Source the .env file: source .env"
echo "3. Configure AWS credentials: aws configure"
echo "4. Initialize Terraform: cd terraform && terraform init"
echo "5. Deploy infrastructure: terraform apply"
echo ""
echo "🔗 Useful commands:"
echo "  - Test file upload: ./scripts/push_test_file.sh"
echo "  - Poll for completion: node scripts/poll_completion.js"
echo "  - Full test: node scripts/test_deployment.js"
echo "  - Or use npm scripts: cd scripts && npm run test" 