# Complete Workflow Guide

This guide provides a step-by-step workflow to run, test, and deploy the To-Do App with CI/CD pipeline.

## 🚀 Quick Start Workflow

### Step 1: Initial Setup

1. **Clone and Setup**
   ```bash
   git clone <your-repository-url>
   cd todo-app-cicd
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Verify Installation**
   ```bash
   node --version  # Should be 18+
   npm --version
   docker --version
   ```

### Step 2: Local Development

#### Option A: Separate Frontend and Backend (Recommended for Development)

1. **Start Backend Server**
   ```bash
   cd app/server
   npm run dev
   ```
   - Backend will run on http://localhost:3001
   - Health check: http://localhost:3001/api/health

2. **Start Frontend (New Terminal)**
   ```bash
   cd app
   npm start
   ```
   - Frontend will run on http://localhost:3000
   - Will automatically open in browser

#### Option B: Docker Compose (Recommended for Testing)

1. **Start Everything with Docker**
   ```bash
   cd docker
   docker-compose --profile dev up
   ```
   - Frontend: http://localhost:3000
   - Backend: http://localhost:3001

### Step 3: Testing the Application

1. **Manual Testing**
   - Open http://localhost:3000 in browser
   - Add a new todo: "Learn React"
   - Mark it as completed
   - Delete the todo
   - Verify statistics update

2. **API Testing**
   ```bash
   # Health check
   curl http://localhost:3001/api/health
   
   # Get all todos
   curl http://localhost:3001/api/todos
   
   # Create a todo
   curl -X POST http://localhost:3001/api/todos \
     -H "Content-Type: application/json" \
     -d '{"text":"Test todo","completed":false}'
   
   # Update a todo (replace <id> with actual todo id)
   curl -X PUT http://localhost:3001/api/todos/<id> \
     -H "Content-Type: application/json" \
     -d '{"completed":true}'
   
   # Delete a todo (replace <id> with actual todo id)
   curl -X DELETE http://localhost:3001/api/todos/<id>
   ```

### Step 4: Running Tests

1. **Run All Tests**
   ```bash
   ./scripts/test.sh
   ```

2. **Run Frontend Tests Only**
   ```bash
   cd app
   npm test
   ```

3. **Run Backend Tests Only**
   ```bash
   cd app/server
   npm test
   ```

4. **Run Linting**
   ```bash
   # Frontend linting
   cd app
   npm run lint
   npm run lint:fix
   
   # Backend linting
   cd app/server
   npm run lint
   ```

### Step 5: Building for Production

1. **Build Frontend**
   ```bash
   cd app
   npm run build
   ```

2. **Build Docker Image**
   ```bash
   docker build -t todo-app -f docker/Dockerfile .
   ```

3. **Test Production Build**
   ```bash
   docker run -p 3001:3001 todo-app
   # Test at http://localhost:3001
   ```

## 🔄 Development Workflow

### Daily Development Process

1. **Start Development**
   ```bash
   # Terminal 1: Backend
   cd app/server && npm run dev
   
   # Terminal 2: Frontend
   cd app && npm start
   ```

2. **Make Changes**
   - Edit React components in `app/src/`
   - Edit API endpoints in `app/server/server.js`
   - Add tests in `tests/` directory

3. **Test Changes**
   ```bash
   # Quick test
   ./scripts/test.sh
   
   # Manual testing in browser
   # API testing with curl
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "Add new feature: description"
   git push origin develop
   ```

### Code Quality Workflow

1. **Before Committing**
   ```bash
   # Run linting
   cd app && npm run lint:fix
   cd ../server && npm run lint
   
   # Run tests
   ./scripts/test.sh
   
   # Build to ensure no build errors
   cd app && npm run build
   ```

2. **Code Review Process**
   - Create pull request from `develop` to `main`
   - Ensure all tests pass
   - Review code changes
   - Merge to `main` branch

## 🚀 Production Deployment Workflow

### Prerequisites Setup

1. **AWS Account Setup**
   ```bash
   # Install AWS CLI
   aws configure
   
   # Create S3 bucket for Terraform state
   aws s3 mb s3://todo-app-terraform-state
   aws s3api put-bucket-versioning \
     --bucket todo-app-terraform-state \
     --versioning-configuration Status=Enabled
   ```

2. **GitHub Repository Setup**
   - Create GitHub repository
   - Add secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `APP_URL`

### Infrastructure Deployment

1. **Deploy AWS Infrastructure**
   ```bash
   cd infrastructure
   terraform init
   terraform plan -var="environment=production"
   terraform apply -var="environment=production"
   ```

2. **Verify Infrastructure**
   ```bash
   # Check ECS cluster
   aws ecs describe-clusters --clusters production-todo-app-cluster
   
   # Check ECR repository
   aws ecr describe-repositories --repository-names todo-app
   
   # Check ALB
   aws elbv2 describe-load-balancers --names production-todo-app-alb
   ```

### Application Deployment

#### Option A: Automated Deployment (Recommended)

1. **Push to Main Branch**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. **Monitor GitHub Actions**
   - Go to GitHub repository → Actions
   - Watch the CI/CD pipeline execute
   - Verify all steps pass

3. **Verify Deployment**
   ```bash
   # Get ALB DNS name from Terraform output
   terraform output alb_dns_name
   
   # Test application
   curl http://<alb-dns-name>/api/health
   ```

#### Option B: Manual Deployment

1. **Build and Push**
   ```bash
   # Set environment variables
   export AWS_REGION=us-east-1
   export ENVIRONMENT=production
   
   # Run deployment script
   ./scripts/deploy.sh
   ```

2. **Verify Deployment**
   ```bash
   # Check ECS service status
   aws ecs describe-services \
     --cluster production-todo-app-cluster \
     --services production-todo-app-service
   
   # Test application
   curl http://<alb-dns-name>/api/health
   ```

## 🧪 Testing Workflow

### Unit Testing

1. **Frontend Tests**
   ```bash
   cd app
   npm test
   # Tests run in watch mode by default
   # Press 'a' to run all tests
   # Press 'q' to quit
   ```

2. **Backend Tests**
   ```bash
   cd app/server
   npm test
   ```

### Integration Testing

1. **API Integration Tests**
   ```bash
   # Start backend server
   cd app/server && npm start &
   
   # Run integration tests
   cd tests/backend
   npm test
   
   # Stop server
   kill %1
   ```

2. **End-to-End Testing**
   ```bash
   # Start full application
   cd docker && docker-compose up -d
   
   # Run E2E tests (if configured)
   # Test complete user workflows
   
   # Stop application
   docker-compose down
   ```

### Performance Testing

1. **Load Testing**
   ```bash
   # Install Apache Bench
   # Test API endpoints
   ab -n 1000 -c 10 http://localhost:3001/api/todos
   ```

2. **Docker Performance**
   ```bash
   # Monitor container resources
   docker stats todo-app-container
   ```

## 🔍 Monitoring and Debugging

### Local Debugging

1. **Frontend Debugging**
   - Use browser developer tools
   - Check console for errors
   - Use React Developer Tools extension

2. **Backend Debugging**
   ```bash
   # Add debug logging
   console.log('Debug:', data);
   
   # Use nodemon for auto-restart
   npm run dev
   ```

3. **Docker Debugging**
   ```bash
   # Check container logs
   docker logs todo-app-container
   
   # Enter container
   docker exec -it todo-app-container sh
   
   # Check container status
   docker ps
   ```

### Production Monitoring

1. **CloudWatch Logs**
   ```bash
   # View application logs
   aws logs get-log-events \
     --log-group-name /aws/ecs/todo-app \
     --log-stream-name <stream-name>
   ```

2. **ECS Monitoring**
   ```bash
   # Check service status
   aws ecs describe-services \
     --cluster production-todo-app-cluster \
     --services production-todo-app-service
   
   # Check task status
   aws ecs list-tasks --cluster production-todo-app-cluster
   ```

3. **ALB Monitoring**
   ```bash
   # Check target health
   aws elbv2 describe-target-health \
     --target-group-arn <target-group-arn>
   ```

## 🛠️ Troubleshooting Workflow

### Common Issues and Solutions

1. **Port Already in Use**
   ```bash
   # Find process using port
   lsof -i :3000
   lsof -i :3001
   
   # Kill process
   kill -9 <PID>
   ```

2. **Docker Issues**
   ```bash
   # Clean up Docker
   docker system prune -a
   docker volume prune
   
   # Restart Docker Desktop
   ```

3. **Node Modules Issues**
   ```bash
   # Clear cache and reinstall
   rm -rf node_modules package-lock.json
   npm cache clean --force
   npm install
   ```

4. **AWS Issues**
   ```bash
   # Verify credentials
   aws sts get-caller-identity
   
   # Check region
   aws configure get region
   ```

### Debugging Commands

```bash
# Check all services
docker ps
docker-compose ps

# Check logs
docker logs <container-name>
docker-compose logs

# Check network
docker network ls
docker network inspect <network-name>

# Check volumes
docker volume ls
docker volume inspect <volume-name>
```

## 📊 Performance Optimization

### Development Performance

1. **Frontend Optimization**
   ```bash
   # Analyze bundle size
   npm run build
   # Check build folder size
   
   # Use React DevTools Profiler
   # Monitor component re-renders
   ```

2. **Backend Optimization**
   ```bash
   # Monitor memory usage
   node --inspect server.js
   
   # Use PM2 for process management
   npm install -g pm2
   pm2 start server.js
   ```

### Production Optimization

1. **Docker Optimization**
   ```bash
   # Multi-stage builds (already implemented)
   # Use .dockerignore
   # Optimize layer caching
   ```

2. **AWS Optimization**
   ```bash
   # Monitor CloudWatch metrics
   # Set up auto-scaling
   # Use appropriate instance types
   ```

## 🔄 Continuous Improvement

### Regular Maintenance

1. **Weekly Tasks**
   - Update dependencies
   - Review security advisories
   - Check performance metrics
   - Update documentation

2. **Monthly Tasks**
   - Review and optimize costs
   - Update infrastructure
   - Security audits
   - Performance reviews

3. **Quarterly Tasks**
   - Major dependency updates
   - Architecture reviews
   - Disaster recovery testing
   - Compliance audits

### Learning and Improvement

1. **Monitor Metrics**
   - Application performance
   - User experience
   - Infrastructure costs
   - Security incidents

2. **Gather Feedback**
   - User feedback
   - Developer experience
   - Operations feedback
   - Business requirements

3. **Implement Improvements**
   - Performance optimizations
   - Security enhancements
   - Feature additions
   - Process improvements

This workflow guide provides a comprehensive approach to developing, testing, and deploying the To-Do App with CI/CD pipeline. Follow these steps to ensure a smooth development and deployment experience.
