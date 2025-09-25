#!/bin/bash

# Deploy Script for Sistema de Inventario PYMES
# Automated deployment with health checks and rollback capability

set -euo pipefail

# ==================== CONFIGURATION ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployment"

# Default configuration
ENVIRONMENT="${ENVIRONMENT:-production}"
NAMESPACE="${NAMESPACE:-inventario-pymes}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io/inventario-pymes}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
TIMEOUT="${TIMEOUT:-600}"
DRY_RUN="${DRY_RUN:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"
SKIP_TESTS="${SKIP_TESTS:-false}"
FORCE_DEPLOY="${FORCE_DEPLOY:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== FUNCTIONS ====================

log() {
    local level=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $level in
        INFO)  echo -e "${BLUE}[INFO]${NC}  [$timestamp] $*" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC}  [$timestamp] $*" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} [$timestamp] $*" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} [$timestamp] $*" ;;
    esac
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Sistema de Inventario PYMES to Kubernetes

OPTIONS:
    -e, --environment ENV    Target environment (dev|staging|production) [default: production]
    -n, --namespace NS       Kubernetes namespace [default: inventario-pymes]
    -r, --registry REG       Docker registry [default: ghcr.io/inventario-pymes]
    -t, --tag TAG           Image tag [default: latest]
    -T, --timeout SECONDS   Deployment timeout [default: 600]
    --dry-run               Show what would be deployed without executing
    --skip-build            Skip Docker image build
    --skip-tests            Skip running tests
    --force                 Force deployment even if health checks fail
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Deploy to production
    $0 -e staging -t v1.2.3                   # Deploy specific version to staging
    $0 --dry-run                               # Preview deployment
    $0 --skip-build -t existing-tag            # Deploy existing image

ENVIRONMENT VARIABLES:
    KUBECONFIG              Path to kubeconfig file
    DOCKER_REGISTRY         Docker registry URL
    IMAGE_TAG               Docker image tag
    DB_PASSWORD             Database password
    JWT_SECRET              JWT secret key
    REDIS_PASSWORD          Redis password

EOF
}

check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log ERROR "Missing required tools: ${missing_tools[*]}"
        log ERROR "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check Kubernetes connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log ERROR "Cannot connect to Kubernetes cluster"
        log ERROR "Please check your kubeconfig and cluster connectivity"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        log ERROR "Docker daemon is not running"
        exit 1
    fi
    
    log SUCCESS "Prerequisites check passed"
}

validate_environment() {
    log INFO "Validating environment configuration..."
    
    case $ENVIRONMENT in
        dev|development)
            ENVIRONMENT="development"
            NAMESPACE="${NAMESPACE:-inventario-pymes-dev}"
            ;;
        staging|stage)
            ENVIRONMENT="staging"
            NAMESPACE="${NAMESPACE:-inventario-pymes-staging}"
            ;;
        prod|production)
            ENVIRONMENT="production"
            NAMESPACE="${NAMESPACE:-inventario-pymes}"
            ;;
        *)
            log ERROR "Invalid environment: $ENVIRONMENT"
            log ERROR "Valid environments: dev, staging, production"
            exit 1
            ;;
    esac
    
    # Check required secrets for production
    if [ "$ENVIRONMENT" = "production" ]; then
        local required_vars=("DB_PASSWORD" "JWT_SECRET" "REDIS_PASSWORD")
        for var in "${required_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log ERROR "Required environment variable $var is not set"
                exit 1
            fi
        done
    fi
    
    log SUCCESS "Environment validation passed: $ENVIRONMENT"
}

build_images() {
    if [ "$SKIP_BUILD" = "true" ]; then
        log INFO "Skipping image build"
        return 0
    fi
    
    log INFO "Building Docker images..."
    
    local images=("frontend" "backend" "database")
    
    for image in "${images[@]}"; do
        log INFO "Building $image image..."
        
        docker build \
            -f "$DEPLOYMENT_DIR/docker/Dockerfile.$image" \
            -t "$DOCKER_REGISTRY/$image:$IMAGE_TAG" \
            "$PROJECT_ROOT" || {
            log ERROR "Failed to build $image image"
            exit 1
        }
        
        if [ "$DRY_RUN" = "false" ]; then
            log INFO "Pushing $image image to registry..."
            docker push "$DOCKER_REGISTRY/$image:$IMAGE_TAG" || {
                log ERROR "Failed to push $image image"
                exit 1
            }
        fi
    done
    
    log SUCCESS "Docker images built and pushed successfully"
}

run_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        log INFO "Skipping tests"
        return 0
    fi
    
    log INFO "Running tests..."
    
    # Run backend tests
    if [ -f "$PROJECT_ROOT/src/backend/package.json" ]; then
        log INFO "Running backend tests..."
        cd "$PROJECT_ROOT/src/backend"
        npm test || {
            log ERROR "Backend tests failed"
            exit 1
        }
    fi
    
    # Run frontend tests
    if [ -f "$PROJECT_ROOT/src/frontend/package.json" ]; then
        log INFO "Running frontend tests..."
        cd "$PROJECT_ROOT/src/frontend"
        npm test -- --coverage --watchAll=false || {
            log ERROR "Frontend tests failed"
            exit 1
        }
    fi
    
    log SUCCESS "All tests passed"
}

create_namespace() {
    log INFO "Creating namespace if it doesn't exist..."
    
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log INFO "Namespace $NAMESPACE already exists"
    else
        if [ "$DRY_RUN" = "false" ]; then
            kubectl apply -f "$DEPLOYMENT_DIR/kubernetes/namespace.yaml"
            log SUCCESS "Namespace $NAMESPACE created"
        else
            log INFO "[DRY RUN] Would create namespace $NAMESPACE"
        fi
    fi
}

deploy_secrets() {
    log INFO "Deploying secrets..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would deploy secrets to $NAMESPACE"
        return 0
    fi
    
    # Create database password secret
    kubectl create secret generic postgres-secret \
        --from-literal=password="$DB_PASSWORD" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create JWT secret
    kubectl create secret generic jwt-secret \
        --from-literal=secret="$JWT_SECRET" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Redis password secret
    kubectl create secret generic redis-secret \
        --from-literal=password="$REDIS_PASSWORD" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log SUCCESS "Secrets deployed successfully"
}

deploy_configmaps() {
    log INFO "Deploying ConfigMaps..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would deploy ConfigMaps to $NAMESPACE"
        return 0
    fi
    
    kubectl apply -f "$DEPLOYMENT_DIR/kubernetes/configmap.yaml" -n "$NAMESPACE"
    log SUCCESS "ConfigMaps deployed successfully"
}

deploy_applications() {
    log INFO "Deploying applications..."
    
    local manifests=(
        "deployments/database-deployment.yaml"
        "services/database-service.yaml"
        "deployments/backend-deployment.yaml"
        "services/backend-service.yaml"
        "deployments/frontend-deployment.yaml"
        "services/frontend-service.yaml"
        "ingress.yaml"
    )
    
    for manifest in "${manifests[@]}"; do
        local file="$DEPLOYMENT_DIR/kubernetes/$manifest"
        if [ -f "$file" ]; then
            log INFO "Applying $manifest..."
            if [ "$DRY_RUN" = "true" ]; then
                log INFO "[DRY RUN] Would apply $manifest"
            else
                # Replace image tags in deployment files
                sed "s|{{IMAGE_TAG}}|$IMAGE_TAG|g; s|{{DOCKER_REGISTRY}}|$DOCKER_REGISTRY|g" "$file" | \
                kubectl apply -f - -n "$NAMESPACE"
            fi
        else
            log WARN "Manifest file not found: $file"
        fi
    done
    
    log SUCCESS "Applications deployed successfully"
}

wait_for_deployment() {
    local deployment=$1
    local timeout=${2:-$TIMEOUT}
    
    log INFO "Waiting for deployment $deployment to be ready..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would wait for deployment $deployment"
        return 0
    fi
    
    if kubectl rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout="${timeout}s"; then
        log SUCCESS "Deployment $deployment is ready"
        return 0
    else
        log ERROR "Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

health_check() {
    log INFO "Performing health checks..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would perform health checks"
        return 0
    fi
    
    local deployments=("postgres" "redis" "backend" "frontend")
    local failed_checks=()
    
    for deployment in "${deployments[@]}"; do
        if ! wait_for_deployment "$deployment" 300; then
            failed_checks+=("$deployment")
        fi
    done
    
    if [ ${#failed_checks[@]} -gt 0 ]; then
        log ERROR "Health checks failed for: ${failed_checks[*]}"
        if [ "$FORCE_DEPLOY" = "false" ]; then
            log ERROR "Deployment failed. Use --force to override health checks"
            exit 1
        else
            log WARN "Continuing deployment despite failed health checks (--force enabled)"
        fi
    else
        log SUCCESS "All health checks passed"
    fi
}

rollback_deployment() {
    log WARN "Rolling back deployment..."
    
    local deployments=("frontend" "backend")
    
    for deployment in "${deployments[@]}"; do
        log INFO "Rolling back $deployment..."
        kubectl rollout undo deployment/"$deployment" -n "$NAMESPACE" || {
            log ERROR "Failed to rollback $deployment"
        }
    done
    
    log INFO "Rollback completed"
}

cleanup_old_resources() {
    log INFO "Cleaning up old resources..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would cleanup old resources"
        return 0
    fi
    
    # Remove old replica sets
    kubectl delete rs -l app.kubernetes.io/name=inventario-pymes -n "$NAMESPACE" \
        --field-selector='status.replicas=0' 2>/dev/null || true
    
    # Remove completed jobs older than 7 days
    kubectl delete jobs -l app.kubernetes.io/name=inventario-pymes -n "$NAMESPACE" \
        --field-selector='status.conditions[0].type=Complete' \
        --field-selector='metadata.creationTimestamp<'$(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%SZ) 2>/dev/null || true
    
    log SUCCESS "Cleanup completed"
}

main() {
    log INFO "Starting deployment of Sistema de Inventario PYMES"
    log INFO "Environment: $ENVIRONMENT"
    log INFO "Namespace: $NAMESPACE"
    log INFO "Image Tag: $IMAGE_TAG"
    log INFO "Registry: $DOCKER_REGISTRY"
    
    if [ "$DRY_RUN" = "true" ]; then
        log WARN "DRY RUN MODE - No actual changes will be made"
    fi
    
    # Trap to handle rollback on failure
    trap 'log ERROR "Deployment failed. Consider running rollback."; exit 1' ERR
    
    check_prerequisites
    validate_environment
    build_images
    run_tests
    create_namespace
    deploy_secrets
    deploy_configmaps
    deploy_applications
    health_check
    cleanup_old_resources
    
    log SUCCESS "Deployment completed successfully!"
    log INFO "Application should be available at: https://inventario-pymes.com"
    log INFO "Monitor deployment with: kubectl get pods -n $NAMESPACE"
}

# ==================== ARGUMENT PARSING ====================

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -T|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --skip-build)
            SKIP_BUILD="true"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        --force)
            FORCE_DEPLOY="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log ERROR "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ==================== MAIN EXECUTION ====================

main "$@"