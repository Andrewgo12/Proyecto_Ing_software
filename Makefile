# Makefile for Sistema Inventario PYMES

.PHONY: help install dev build test clean docker

# Default target
help:
	@echo "Available commands:"
	@echo "  install    - Install all dependencies"
	@echo "  dev        - Start development servers"
	@echo "  build      - Build all applications"
	@echo "  test       - Run all tests"
	@echo "  lint       - Run linting"
	@echo "  clean      - Clean all build artifacts"
	@echo "  docker     - Build and run with Docker"
	@echo "  migrate    - Run database migrations"
	@echo "  seed       - Seed database with test data"

# Install dependencies
install:
	npm install
	cd src/backend && npm install
	cd src/frontend && npm install
	cd src/mobile && npm install

# Development
dev:
	npm run dev

dev-backend:
	cd src/backend && npm run dev

dev-frontend:
	cd src/frontend && npm run dev

dev-mobile:
	cd src/mobile && npx expo start

# Build
build:
	npm run build

build-frontend:
	cd src/frontend && npm run build

build-backend:
	cd src/backend && npm run build

# Testing
test:
	npm run test

test-unit:
	npm run test:backend
	npm run test:frontend

test-integration:
	npm run test:integration

test-e2e:
	npm run test:e2e

test-coverage:
	npm run test:coverage

# Linting
lint:
	npm run lint

lint-fix:
	npm run lint:fix

# Database
migrate:
	cd src/backend && npm run migrate

seed:
	cd src/backend && npm run seed

db-reset:
	cd src/backend && npm run migrate:rollback && npm run migrate && npm run seed

# Docker
docker:
	docker-compose up -d

docker-build:
	docker-compose build

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

# Kubernetes
k8s-deploy:
	kubectl apply -f deployment/kubernetes/

k8s-delete:
	kubectl delete -f deployment/kubernetes/

# Terraform
terraform-init:
	cd deployment/terraform && terraform init

terraform-plan:
	cd deployment/terraform && terraform plan

terraform-apply:
	cd deployment/terraform && terraform apply

# Clean
clean:
	rm -rf node_modules
	rm -rf src/backend/node_modules
	rm -rf src/frontend/node_modules
	rm -rf src/mobile/node_modules
	rm -rf src/frontend/dist
	rm -rf src/backend/dist

# Setup for new developers
setup: install migrate seed
	@echo "Setup complete! Run 'make dev' to start development servers."