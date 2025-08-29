#!/bin/bash

# To-Do App CI/CD Setup Script
# This script sets up the development environment

set -e

echo "🚀 Setting up To-Do App CI/CD Project..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18 or higher."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd app
npm install
cd ..

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd app/server
npm install
cd ../..

# Create environment files
echo "🔧 Creating environment files..."

# Frontend environment
cat > app/.env << EOF
REACT_APP_API_URL=http://localhost:3001/api
EOF

# Backend environment
cat > app/server/.env << EOF
NODE_ENV=development
PORT=3001
EOF

echo "✅ Environment files created"

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Production builds
app/build/
app/dist/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Docker
.dockerignore

# AWS
.aws/
EOF
fi

echo "✅ .gitignore created"

# Make scripts executable
chmod +x scripts/*.sh

echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Run 'npm start' in the app directory to start the frontend"
echo "2. Run 'npm run dev' in the app/server directory to start the backend"
echo "3. Or use 'docker-compose up' in the docker directory for containerized development"
echo "4. Run 'npm test' in both app and app/server directories to run tests"
echo ""
echo "For production deployment:"
echo "1. Set up AWS credentials"
echo "2. Configure GitHub Secrets"
echo "3. Deploy infrastructure with Terraform"
echo "4. Push to main branch to trigger CI/CD pipeline"
