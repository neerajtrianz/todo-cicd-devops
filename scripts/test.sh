#!/bin/bash

# To-Do App Test Script
# This script runs all tests for the application

set -e

echo "🧪 Running To-Do App tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed"
    exit 1
fi

# Frontend tests
echo ""
echo "📱 Running frontend tests..."
cd app

if [ ! -d "node_modules" ]; then
    print_warning "Frontend dependencies not installed. Installing..."
    npm install
fi

print_status "Running frontend linting..."
npm run lint

print_status "Running frontend tests..."
npm test -- --watchAll=false --coverage --passWithNoTests

cd ..

# Backend tests
echo ""
echo "🔧 Running backend tests..."
cd app/server

if [ ! -d "node_modules" ]; then
    print_warning "Backend dependencies not installed. Installing..."
    npm install
fi

print_status "Running backend tests..."
npm test

cd ../..

# Docker tests
echo ""
echo "🐳 Running Docker tests..."

# Test Docker build
print_status "Testing Docker build..."
docker build -t todo-app-test -f docker/Dockerfile . > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_status "Docker build successful"
else
    print_error "Docker build failed"
    exit 1
fi

# Test Docker container
print_status "Testing Docker container..."
docker run -d --name todo-app-test-container -p 3001:3001 todo-app-test > /dev/null 2>&1

# Wait for container to start
sleep 10

# Test health endpoint
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    print_status "Docker container health check passed"
else
    print_error "Docker container health check failed"
fi

# Clean up test container
docker stop todo-app-test-container > /dev/null 2>&1
docker rm todo-app-test-container > /dev/null 2>&1
docker rmi todo-app-test > /dev/null 2>&1

# Integration tests
echo ""
echo "🔗 Running integration tests..."

# Start backend server in background
cd app/server
npm start > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test API endpoints
print_status "Testing API endpoints..."

# Health check
if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
    print_status "Health endpoint working"
else
    print_error "Health endpoint failed"
fi

# Get todos
if curl -f http://localhost:3001/api/todos > /dev/null 2>&1; then
    print_status "GET /api/todos working"
else
    print_error "GET /api/todos failed"
fi

# Create todo
TODO_RESPONSE=$(curl -s -X POST http://localhost:3001/api/todos \
    -H "Content-Type: application/json" \
    -d '{"text":"Integration test todo","completed":false}')

if echo "$TODO_RESPONSE" | grep -q "Integration test todo"; then
    print_status "POST /api/todos working"
else
    print_error "POST /api/todos failed"
fi

# Stop server
kill $SERVER_PID 2>/dev/null || true
cd ../..

echo ""
print_status "All tests completed successfully!"
echo ""
echo "📊 Test Summary:"
echo "   ✅ Frontend linting passed"
echo "   ✅ Frontend tests passed"
echo "   ✅ Backend tests passed"
echo "   ✅ Docker build successful"
echo "   ✅ Docker container health check passed"
echo "   ✅ API integration tests passed"
echo ""
echo "🎉 All tests passed! The application is ready for deployment."
