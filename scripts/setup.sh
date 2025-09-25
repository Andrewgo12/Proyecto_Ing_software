#!/bin/bash

# Setup script for Sistema Inventario PYMES
set -e

echo "🚀 Setting up Sistema Inventario PYMES..."

# Check prerequisites
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm is required"; exit 1; }

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Setup backend
echo "🔧 Setting up backend..."
cd src/backend
npm install
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Configure .env file in src/backend/"
fi
cd ../..

# Setup frontend
echo "🎨 Setting up frontend..."
cd src/frontend
npm install
cd ../..

# Setup mobile
echo "📱 Setting up mobile app..."
cd src/mobile
npm install
cd ../..

echo "✅ Setup completed!"
echo "Next steps:"
echo "1. Configure .env files"
echo "2. Run 'make migrate'"
echo "3. Run 'make dev'"