#!/bin/bash
set -e

echo "Testing Docker setup for URL Shortener..."

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "Docker and Docker Compose are installed"

# Build and start services
echo "Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    echo "Services are running"
else
    echo "Services failed to start"
    docker-compose logs
    exit 1
fi

# Test health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:4000/api/health > /dev/null 2>&1; then
    echo "Health endpoint is responding"
else
    echo "Health endpoint is not responding"
    echo "Logs from web service:"
    docker-compose logs web
    exit 1
fi

# Test main application
echo "Testing main application..."
if curl -f http://localhost:4000 > /dev/null 2>&1; then
    echo "Main application is responding"
else
    echo "Main application is not responding"
    docker-compose logs web
    exit 1
fi

echo ""
echo "All tests passed! Your Docker setup is working correctly."
echo ""
echo "Application is running at: http://localhost:4000"
echo "Health check at: http://localhost:4000/api/health"
echo "Database is running on port 5432"
echo ""
echo "To stop the services, run: docker-compose down"
echo "To view logs, run: docker-compose logs -f"
