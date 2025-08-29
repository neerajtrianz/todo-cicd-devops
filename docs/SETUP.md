# To-Do App CI/CD Setup Guide

This guide will help you set up and run the To-Do App with CI/CD pipeline locally and in production.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
- **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
- **Docker** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Git** - [Download here](https://git-scm.com/)

### For Production Deployment
- **AWS CLI** - [Download here](https://aws.amazon.com/cli/)
- **Terraform** - [Download here](https://www.terraform.io/downloads.html)

### Verify Installation
```bash
node --version
npm --version
docker --version
git --version
```

## Quick Start

### 1. Clone the Repository
```bash
git clone <your-repository-url>
cd todo-app-cicd
```

### 2. Run Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This script will:
- Check prerequisites
- Install dependencies
- Create environment files
- Set up the development environment

### 3. Start Development Servers

#### Option A: Separate Frontend and Backend
```bash
# Terminal 1 - Start Backend
cd app/server
npm run dev

# Terminal 2 - Start Frontend
cd app
npm start
```

#### Option B: Using Docker Compose
```bash
cd docker
docker-compose --profile dev up
```

### 4. Access the Application
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- Health Check: http://localhost:3001/api/health

## Development Workflow

### Running Tests
```bash
# Run all tests
./scripts/test.sh

# Run frontend tests only
cd app
npm test

# Run backend tests only
cd app/server
npm test
```

### Code Quality
```bash
# Frontend linting
cd app
npm run lint
npm run lint:fix

# Backend linting
cd app/server
npm run lint
```

### Building for Production
```bash
# Build frontend
cd app
npm run build

# Build Docker image
docker build -t todo-app -f docker/Dockerfile .
```

## Production Deployment

### 1. AWS Setup

#### Configure AWS Credentials
```bash
aws configure
```

#### Create S3 Bucket for Terraform State
```bash
aws s3 mb s3://todo-app-terraform-state
aws s3api put-bucket-versioning --bucket todo-app-terraform-state --versioning-configuration Status=Enabled
```

### 2. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `APP_URL` - Your application URL (after deployment)

### 3. Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

### 4. Deploy Application

#### Option A: Using GitHub Actions (Recommended)
1. Push your code to the `main` branch
2. GitHub Actions will automatically:
   - Run tests
   - Build Docker image
   - Push to ECR
   - Deploy to ECS

#### Option B: Manual Deployment
```bash
./scripts/deploy.sh
```

### 5. Verify Deployment

After deployment, you can access your application at the ALB DNS name provided by Terraform.

## Project Structure

```
todo-app-cicd/
├── app/                    # Application source code
│   ├── public/            # Static files
│   ├── src/               # React components
│   └── server/            # Express API server
├── docker/                # Docker configuration
│   ├── Dockerfile         # Production Dockerfile
│   ├── Dockerfile.dev     # Development Dockerfile
│   └── docker-compose.yml # Docker Compose configuration
├── infrastructure/        # AWS infrastructure (Terraform)
│   ├── modules/           # Terraform modules
│   ├── main.tf           # Main Terraform configuration
│   ├── variables.tf      # Terraform variables
│   └── outputs.tf        # Terraform outputs
├── .github/              # GitHub Actions workflows
│   └── workflows/        # CI/CD pipeline
├── scripts/              # Utility scripts
├── tests/                # Test files
├── docs/                 # Documentation
└── README.md            # Project overview
```

## Environment Variables

### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:3001/api
```

### Backend (.env)
```
NODE_ENV=development
PORT=3001
```

### Production Environment Variables
Set these in your deployment environment:
- `NODE_ENV=production`
- `PORT=3001`

## API Endpoints

### Health Check
- `GET /api/health` - Application health status

### Todos
- `GET /api/todos` - Get all todos
- `POST /api/todos` - Create a new todo
- `PUT /api/todos/:id` - Update a todo
- `DELETE /api/todos/:id` - Delete a todo

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port 3000 or 3001
lsof -i :3000
lsof -i :3001

# Kill the process
kill -9 <PID>
```

#### Docker Issues
```bash
# Clean up Docker containers and images
docker system prune -a

# Restart Docker Desktop
```

#### Node Modules Issues
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### AWS Issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check AWS region
aws configure get region
```

### Getting Help

1. Check the logs:
   - Frontend: Browser console
   - Backend: Terminal output
   - Docker: `docker logs <container-name>`

2. Verify all services are running:
   - Frontend: http://localhost:3000
   - Backend: http://localhost:3001/api/health

3. Check environment variables are set correctly

## Next Steps

1. **Customize the Application**: Modify the React components and API endpoints
2. **Add Database**: Replace in-memory storage with a real database
3. **Add Authentication**: Implement user authentication
4. **Add Monitoring**: Set up CloudWatch alarms and dashboards
5. **Add SSL**: Configure HTTPS with AWS Certificate Manager
6. **Add CDN**: Set up CloudFront for static assets

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the logs and error messages
3. Create an issue in the repository
4. Contact the development team
