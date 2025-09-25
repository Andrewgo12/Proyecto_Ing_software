#!/bin/bash

# Rollback Script for Sistema de Inventario PYMES
# Automated rollback with safety checks and validation

set -euo pipefail

# ==================== CONFIGURATION ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default configuration
ENVIRONMENT="${ENVIRONMENT:-production}"
NAMESPACE="${NAMESPACE:-inventario-pymes}"
ROLLBACK_REVISION="${ROLLBACK_REVISION:-}"
DRY_RUN="${DRY_RUN:-false}"
FORCE_ROLLBACK="${FORCE_ROLLBACK:-false}"

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

Rollback Sistema de Inventario PYMES deployment

OPTIONS:
    -e, --environment ENV    Target environment (dev|staging|production) [default: production]
    -n, --namespace NS       Kubernetes namespace [default: inventario-pymes]
    -r, --revision REV       Specific revision to rollback to (optional)
    --dry-run               Show what would be rolled back without executing
    --force                 Force rollback without confirmation
    -h, --help              Show this help message

EXAMPLES:
    $0                                    # Rollback to previous version
    $0 -r 5                              # Rollback to specific revision
    $0 -e staging --dry-run              # Preview rollback in staging
    $0 --force                           # Force rollback without confirmation

EOF
}

check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log ERROR "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check Kubernetes connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log ERROR "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log ERROR "Namespace $NAMESPACE does not exist"
        exit 1
    fi
    
    log SUCCESS "Prerequisites check passed"
}

get_deployment_history() {
    local deployment=$1
    
    log INFO "Getting rollout history for $deployment..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would show rollout history for $deployment"
        return 0
    fi
    
    echo "Rollout history for $deployment:"
    kubectl rollout history deployment/"$deployment" -n "$NAMESPACE" || {
        log ERROR "Failed to get rollout history for $deployment"
        return 1
    }
    echo ""
}

validate_revision() {
    local deployment=$1
    local revision=$2
    
    if [ -z "$revision" ]; then
        return 0  # No specific revision, rollback to previous
    fi
    
    log INFO "Validating revision $revision for $deployment..."
    
    # Check if revision exists
    if ! kubectl rollout history deployment/"$deployment" -n "$NAMESPACE" --revision="$revision" >/dev/null 2>&1; then
        log ERROR "Revision $revision does not exist for deployment $deployment"
        return 1
    fi
    
    log SUCCESS "Revision $revision is valid for $deployment"
    return 0
}

get_current_status() {
    log INFO "Getting current deployment status..."
    
    local deployments=("frontend" "backend")
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            echo "Current status of $deployment:"
            kubectl get deployment "$deployment" -n "$NAMESPACE" -o wide
            echo ""
            
            # Show current revision
            local current_revision=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
            echo "Current revision: $current_revision"
            echo ""
        else
            log WARN "Deployment $deployment not found in namespace $NAMESPACE"
        fi
    done
}

confirm_rollback() {
    if [ "$FORCE_ROLLBACK" = "true" ]; then
        log INFO "Force rollback enabled, skipping confirmation"
        return 0
    fi
    
    echo ""
    log WARN "WARNING: This will rollback the application to a previous version"
    log WARN "This operation will cause a brief service interruption"
    echo ""
    
    if [ -n "$ROLLBACK_REVISION" ]; then
        log INFO "Target revision: $ROLLBACK_REVISION"
    else
        log INFO "Target: Previous revision"
    fi
    
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    case $confirmation in
        yes|YES|y|Y)
            log INFO "Rollback confirmed"
            return 0
            ;;
        *)
            log INFO "Rollback cancelled"
            exit 0
            ;;
    esac
}

rollback_deployment() {
    local deployment=$1
    
    log INFO "Rolling back deployment: $deployment"
    
    if [ "$DRY_RUN" = "true" ]; then
        if [ -n "$ROLLBACK_REVISION" ]; then
            log INFO "[DRY RUN] Would rollback $deployment to revision $ROLLBACK_REVISION"
        else
            log INFO "[DRY RUN] Would rollback $deployment to previous revision"
        fi
        return 0
    fi
    
    # Perform rollback
    if [ -n "$ROLLBACK_REVISION" ]; then
        kubectl rollout undo deployment/"$deployment" -n "$NAMESPACE" --to-revision="$ROLLBACK_REVISION" || {
            log ERROR "Failed to rollback $deployment to revision $ROLLBACK_REVISION"
            return 1
        }
        log SUCCESS "Initiated rollback of $deployment to revision $ROLLBACK_REVISION"
    else
        kubectl rollout undo deployment/"$deployment" -n "$NAMESPACE" || {
            log ERROR "Failed to rollback $deployment"
            return 1
        }
        log SUCCESS "Initiated rollback of $deployment to previous revision"
    fi
    
    return 0
}

wait_for_rollback() {
    local deployment=$1
    local timeout=${2:-300}
    
    log INFO "Waiting for rollback of $deployment to complete..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would wait for rollback of $deployment"
        return 0
    fi
    
    if kubectl rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout="${timeout}s"; then
        log SUCCESS "Rollback of $deployment completed successfully"
        return 0
    else
        log ERROR "Rollback of $deployment failed or timed out"
        return 1
    fi
}

verify_rollback() {
    log INFO "Verifying rollback success..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would verify rollback success"
        return 0
    fi
    
    local deployments=("frontend" "backend")
    local failed_deployments=()
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            # Check if deployment is ready
            local ready_replicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
            local desired_replicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
            
            if [ "$ready_replicas" = "$desired_replicas" ] && [ "$ready_replicas" -gt 0 ]; then
                log SUCCESS "$deployment rollback verified successfully"
            else
                log ERROR "$deployment rollback verification failed"
                failed_deployments+=("$deployment")
            fi
        fi
    done
    
    if [ ${#failed_deployments[@]} -gt 0 ]; then
        log ERROR "Rollback verification failed for: ${failed_deployments[*]}"
        return 1
    else
        log SUCCESS "All rollbacks verified successfully"
        return 0
    fi
}

health_check() {
    log INFO "Performing post-rollback health checks..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log INFO "[DRY RUN] Would perform health checks"
        return 0
    fi
    
    # Check if services are responding
    local services=("frontend-service" "backend-service")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if kubectl get service "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            # Get service endpoint
            local service_ip=$(kubectl get service "$service" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
            local service_port=$(kubectl get service "$service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
            
            # Test connectivity (this is a basic check)
            if kubectl run health-check-$(date +%s) --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" -- curl -f -s "http://$service_ip:$service_port/health" >/dev/null 2>&1; then
                log SUCCESS "$service health check passed"
            else
                log WARN "$service health check failed or service doesn't have /health endpoint"
                # Don't fail the rollback for health check failures
            fi
        fi
    done
    
    log SUCCESS "Health checks completed"
}

show_rollback_summary() {
    log INFO "Rollback Summary"
    echo "=================="
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $NAMESPACE"
    if [ -n "$ROLLBACK_REVISION" ]; then
        echo "Target Revision: $ROLLBACK_REVISION"
    else
        echo "Target: Previous revision"
    fi
    echo "Timestamp: $(date)"
    echo ""
    
    # Show current deployment status
    get_current_status
}

main() {
    log INFO "Starting rollback of Sistema de Inventario PYMES"
    log INFO "Environment: $ENVIRONMENT"
    log INFO "Namespace: $NAMESPACE"
    
    if [ "$DRY_RUN" = "true" ]; then
        log WARN "DRY RUN MODE - No actual changes will be made"
    fi
    
    check_prerequisites
    
    # Show current status
    get_current_status
    
    # Get deployment history
    local deployments=("frontend" "backend")
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            get_deployment_history "$deployment"
            
            # Validate revision if specified
            if [ -n "$ROLLBACK_REVISION" ]; then
                validate_revision "$deployment" "$ROLLBACK_REVISION" || exit 1
            fi
        fi
    done
    
    # Confirm rollback
    confirm_rollback
    
    # Perform rollback
    local failed_rollbacks=()
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            if ! rollback_deployment "$deployment"; then
                failed_rollbacks+=("$deployment")
            fi
        fi
    done
    
    if [ ${#failed_rollbacks[@]} -gt 0 ]; then
        log ERROR "Failed to initiate rollback for: ${failed_rollbacks[*]}"
        exit 1
    fi
    
    # Wait for rollbacks to complete
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" -n "$NAMESPACE" >/dev/null 2>&1; then
            wait_for_rollback "$deployment" || {
                log ERROR "Rollback failed for $deployment"
                exit 1
            }
        fi
    done
    
    # Verify rollback
    verify_rollback || {
        log ERROR "Rollback verification failed"
        exit 1
    }
    
    # Health checks
    health_check
    
    # Show summary
    show_rollback_summary
    
    log SUCCESS "Rollback completed successfully!"
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
        -r|--revision)
            ROLLBACK_REVISION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --force)
            FORCE_ROLLBACK="true"
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