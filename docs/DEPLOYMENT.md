# Deployment Guide

This guide covers the complete deployment process for the To-Do App CI/CD pipeline.

## Overview

The deployment process involves:
1. **Infrastructure Setup** - AWS resources using Terraform
2. **Application Deployment** - Docker containers on ECS
3. **CI/CD Pipeline** - Automated deployment via GitHub Actions

## Prerequisites

### AWS Account Setup
1. Create an AWS account
2. Create an IAM user with appropriate permissions
3. Configure AWS CLI credentials

### Required AWS Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "ecs:*",
                "ec2:*",
                "iam:*",
                "logs:*",
                "elasticloadbalancing:*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### GitHub Repository Setup
1. Create a GitHub repository
2. Configure GitHub Secrets
3. Set up branch protection rules

## Infrastructure Deployment

### 1. S3 Backend Setup

Create an S3 bucket for Terraform state:

```bash
# Create S3 bucket
aws s3 mb s3://todo-app-terraform-state

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket todo-app-terraform-state \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket todo-app-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
```

### 2. Deploy Infrastructure

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="environment=production" -var="aws_region=us-east-1"

# Apply the configuration
terraform apply -var="environment=production" -var="aws_region=us-east-1"
```

### 3. Verify Infrastructure

After deployment, verify the following resources are created:

- **VPC** with public and private subnets
- **ECS Cluster** for running containers
- **ECR Repository** for storing Docker images
- **Application Load Balancer** for traffic distribution
- **IAM Roles** for ECS tasks
- **CloudWatch Log Groups** for logging

## GitHub Actions Configuration

### 1. Repository Secrets

Add the following secrets to your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `APP_URL` | Application URL | `http://your-alb-dns-name.us-east-1.elb.amazonaws.com` |

### 2. Branch Protection

Configure branch protection for the `main` branch:

1. Go to repository Settings > Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

### 3. Workflow Configuration

The CI/CD pipeline is defined in `.github/workflows/ci-cd.yml` and includes:

- **Testing**: Frontend and backend tests
- **Building**: Docker image creation
- **Security**: Vulnerability scanning
- **Deployment**: ECS service update

## Application Deployment

### 1. Manual Deployment

For manual deployment, use the deployment script:

```bash
# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=production

# Run deployment
./scripts/deploy.sh
```

### 2. Automated Deployment

The GitHub Actions workflow automatically deploys when code is pushed to the `main` branch:

1. **Trigger**: Push to `main` branch
2. **Test**: Run all tests
3. **Build**: Create Docker image
4. **Push**: Upload to ECR
5. **Deploy**: Update ECS service

### 3. Deployment Verification

After deployment, verify:

```bash
# Check ECS service status
aws ecs describe-services \
    --cluster production-todo-app-cluster \
    --services production-todo-app-service \
    --region us-east-1

# Check application health
curl http://your-alb-dns-name.us-east-1.elb.amazonaws.com/api/health

# Check logs
aws logs describe-log-streams \
    --log-group-name /aws/ecs/todo-app \
    --region us-east-1
```

## Monitoring and Logging

### 1. CloudWatch Monitoring

The infrastructure includes CloudWatch alarms for:

- **CPU Utilization** > 80%
- **Memory Utilization** > 80%
- **Application Errors** (custom metrics)

### 2. Logging

Application logs are sent to CloudWatch Logs:

- **Log Group**: `/aws/ecs/todo-app`
- **Retention**: 30 days
- **Format**: JSON structured logging

### 3. Health Checks

The application includes health checks:

- **Path**: `/api/health`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2
- **Unhealthy Threshold**: 2

## Scaling Configuration

### 1. Auto Scaling

ECS service is configured with auto scaling:

```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

### 2. Load Balancer

Application Load Balancer configuration:

- **Type**: Application Load Balancer
- **Protocol**: HTTP (port 80)
- **Health Check**: `/api/health`
- **Target Group**: ECS service

## Security Configuration

### 1. Network Security

- **VPC**: Isolated network environment
- **Security Groups**: Restrict traffic to necessary ports
- **Private Subnets**: ECS tasks run in private subnets
- **NAT Gateway**: Outbound internet access for private resources

### 2. Container Security

- **Non-root User**: Containers run as non-root user
- **Image Scanning**: ECR automatically scans for vulnerabilities
- **Secrets Management**: Use AWS Secrets Manager for sensitive data

### 3. IAM Security

- **Least Privilege**: IAM roles have minimal required permissions
- **Task Roles**: ECS tasks use specific task roles
- **Execution Roles**: ECS tasks use execution roles for ECR access

## Rollback Strategy

### 1. ECS Rollback

If deployment fails, ECS automatically rolls back:

```bash
# Manual rollback to previous version
aws ecs update-service \
    --cluster production-todo-app-cluster \
    --service production-todo-app-service \
    --task-definition production-todo-app-task:1 \
    --region us-east-1
```

### 2. Infrastructure Rollback

For infrastructure issues:

```bash
# Rollback Terraform changes
terraform plan -var="environment=production" -var="aws_region=us-east-1"
terraform apply -var="environment=production" -var="aws_region=us-east-1"
```

## Cost Optimization

### 1. Resource Sizing

- **Instance Type**: t3.micro for development, t3.small for production
- **Auto Scaling**: Scale down during low traffic
- **Spot Instances**: Use spot instances for non-critical workloads

### 2. Storage Optimization

- **ECR Lifecycle**: Automatically delete old images
- **CloudWatch Logs**: Set appropriate retention periods
- **S3 Lifecycle**: Archive old logs to cheaper storage

### 3. Monitoring Costs

- **CloudWatch Metrics**: Monitor resource utilization
- **Cost Explorer**: Track AWS spending
- **Billing Alerts**: Set up cost alerts

## Troubleshooting

### Common Deployment Issues

#### 1. ECS Service Not Starting
```bash
# Check service events
aws ecs describe-services \
    --cluster production-todo-app-cluster \
    --services production-todo-app-service

# Check task definition
aws ecs describe-task-definition \
    --task-definition production-todo-app-task
```

#### 2. Health Check Failures
```bash
# Check target group health
aws elbv2 describe-target-health \
    --target-group-arn <target-group-arn>

# Check application logs
aws logs get-log-events \
    --log-group-name /aws/ecs/todo-app \
    --log-stream-name <log-stream-name>
```

#### 3. Docker Build Failures
```bash
# Test Docker build locally
docker build -t todo-app -f docker/Dockerfile .

# Check Dockerfile syntax
docker build --no-cache -t todo-app -f docker/Dockerfile .
```

### Debugging Commands

```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters production-todo-app-cluster

# Check ECR repository
aws ecr describe-repositories --repository-names todo-app

# Check ALB status
aws elbv2 describe-load-balancers --names production-todo-app-alb

# Check security groups
aws ec2 describe-security-groups --group-names production-ecs-sg
```

## Best Practices

### 1. Deployment
- Always test in staging environment first
- Use blue-green deployments for zero downtime
- Monitor deployment metrics
- Set up rollback procedures

### 2. Security
- Regularly update dependencies
- Scan for vulnerabilities
- Use least privilege access
- Encrypt data in transit and at rest

### 3. Monitoring
- Set up comprehensive logging
- Monitor application metrics
- Set up alerting for critical issues
- Regular performance reviews

### 4. Maintenance
- Regular security updates
- Performance optimization
- Cost monitoring and optimization
- Documentation updates
