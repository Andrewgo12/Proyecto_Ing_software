#!/bin/bash

# Deployment script for Sistema Inventario PYMES
set -e

echo "🚀 Deploying Sistema Inventario PYMES..."

# Build applications
echo "🔨 Building applications..."
npm run build

# Run tests
echo "🧪 Running tests..."
npm test

# Build Docker images
echo "🐳 Building Docker images..."
docker-compose -f docker-compose.prod.yml build

# Deploy with Docker Compose
echo "📦 Deploying with Docker Compose..."
docker-compose -f docker-compose.prod.yml up -d

# Run database migrations
echo "🗄️ Running database migrations..."
docker-compose -f docker-compose.prod.yml exec backend npm run migrate

# Health check
echo "🏥 Performing health check..."
sleep 30
curl -f http://localhost/api/health || { echo "❌ Health check failed"; exit 1; }

echo "✅ Deployment completed successfully!"
echo "🌐 Application is available at: http://localhost"