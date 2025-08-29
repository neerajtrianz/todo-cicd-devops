#!/bin/bash

# To-Do App Deployment Script
# This script deploys the application to AWS

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
ENVIRONMENT=${ENVIRONMENT:-"production"}
APP_NAME="todo-app"

echo "🚀 Starting deployment process..."

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure'."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t $APP_NAME:latest -f docker/Dockerfile .

# Get ECR repository URL
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names $APP_NAME --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPO_URL" ]; then
    echo "❌ ECR repository '$APP_NAME' not found. Please create it first or run Terraform."
    exit 1
fi

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

# Tag and push image
echo "📤 Pushing image to ECR..."
docker tag $APP_NAME:latest $ECR_REPO_URL:latest
docker tag $APP_NAME:latest $ECR_REPO_URL:$(git rev-parse --short HEAD)
docker push $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:$(git rev-parse --short HEAD)

echo "✅ Image pushed successfully"

# Deploy infrastructure (if needed)
if [ "$DEPLOY_INFRASTRUCTURE" = "true" ]; then
    echo "🏗️ Deploying infrastructure..."
    cd infrastructure
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION"
    
    # Apply changes
    terraform apply -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -auto-approve
    
    cd ..
    echo "✅ Infrastructure deployed"
fi

# Update ECS service
echo "🔄 Updating ECS service..."
aws ecs update-service \
    --cluster ${ENVIRONMENT}-todo-app-cluster \
    --service ${ENVIRONMENT}-todo-app-service \
    --force-new-deployment \
    --region $AWS_REGION

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
    --cluster ${ENVIRONMENT}-todo-app-cluster \
    --services ${ENVIRONMENT}-todo-app-service \
    --region $AWS_REGION

echo "✅ Deployment completed successfully!"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names ${ENVIRONMENT}-todo-app-alb \
    --region $AWS_REGION \
    --query 'LoadBalancers[0].DNSName' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$ALB_DNS" ]; then
    echo ""
    echo "🌐 Application URL: http://$ALB_DNS"
    echo "🔍 Health check: http://$ALB_DNS/api/health"
fi

echo ""
echo "📊 Monitor deployment:"
echo "   - ECS Console: https://console.aws.amazon.com/ecs/home?region=$AWS_REGION"
echo "   - CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION"
echo "   - Application Load Balancer: https://console.aws.amazon.com/ec2/v2/home?region=$AWS_REGION#LoadBalancer:sort=loadBalancerName"
