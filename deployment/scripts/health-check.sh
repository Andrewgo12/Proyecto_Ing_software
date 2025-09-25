#!/bin/bash

# Health Check Script for Sistema de Inventario PYMES
# Comprehensive health monitoring and validation

set -euo pipefail

# ==================== CONFIGURATION ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
ENVIRONMENT="${ENVIRONMENT:-production}"
NAMESPACE="${NAMESPACE:-inventario-pymes}"
TIMEOUT="${TIMEOUT:-30}"
VERBOSE="${VERBOSE:-false}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
CONTINUOUS="${CONTINUOUS:-false}"
INTERVAL="${INTERVAL:-60}"

# Health check endpoints
FRONTEND_HEALTH_PATH="/health"
BACKEND_HEALTH_PATH="/health"
BACKEND_READY_PATH="/ready"

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

Health check for Sistema de Inventario PYMES

OPTIONS:
    -e, --environment ENV    Target environment (dev|staging|production) [default: production]
    -n, --namespace NS       Kubernetes namespace [default: inventario-pymes]
    -t, --timeout SECONDS   Request timeout [default: 30]
    -f, --format FORMAT     Output format (text|json|prometheus) [default: text]
    -c, --continuous        Run continuous health checks
    -i, --interval SECONDS  Interval for continuous checks [default: 60]
    -v, --verbose           Verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                                    # Single health check
    $0 -c -i 30                          # Continuous checks every 30 seconds
    $0 -f json                           # JSON output format
    $0 -v                                # Verbose output

EOF
}

check_prerequisites() {
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking prerequisites..."
    fi
    
    local missing_tools=()
    
    # Check required tools
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    
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
    
    if [ "$VERBOSE" = "true" ]; then
        log SUCCESS "Prerequisites check passed"
    fi
}

get_service_endpoint() {
    local service_name=$1
    local port_name=${2:-http}
    
    # Try to get service cluster IP and port
    local cluster_ip=$(kubectl get service "$service_name" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
    local port=$(kubectl get service "$service_name" -n "$NAMESPACE" -o jsonpath="{.spec.ports[?(@.name=='$port_name')].port}" 2>/dev/null || echo "")
    
    if [ -n "$cluster_ip" ] && [ -n "$port" ] && [ "$cluster_ip" != "None" ]; then
        echo "http://$cluster_ip:$port"
        return 0
    fi
    
    # Fallback: try to get from ingress
    local ingress_host=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")
    if [ -n "$ingress_host" ]; then
        echo "https://$ingress_host"
        return 0
    fi
    
    return 1
}

check_pod_health() {
    local component=$1
    local result=0
    
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking $component pods..."
    fi
    
    # Get pod status
    local pods=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=$component" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pods" ]; then
        log ERROR "No $component pods found"
        return 1
    fi
    
    local total_pods=0
    local ready_pods=0
    local running_pods=0
    
    for pod in $pods; do
        total_pods=$((total_pods + 1))
        
        # Check pod phase
        local phase=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        
        # Check ready status
        local ready=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
        
        if [ "$phase" = "Running" ]; then
            running_pods=$((running_pods + 1))
        fi
        
        if [ "$ready" = "True" ]; then
            ready_pods=$((ready_pods + 1))
        fi
        
        if [ "$VERBOSE" = "true" ]; then
            log INFO "$component pod $pod: Phase=$phase, Ready=$ready"
        fi
        
        # Check for recent restarts
        local restart_count=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
        if [ "$restart_count" -gt 5 ]; then
            log WARN "$component pod $pod has $restart_count restarts"
        fi
    done
    
    if [ "$ready_pods" -eq "$total_pods" ] && [ "$running_pods" -eq "$total_pods" ]; then
        if [ "$VERBOSE" = "true" ]; then
            log SUCCESS "$component pods: $ready_pods/$total_pods ready and running"
        fi
    else
        log ERROR "$component pods: $ready_pods/$total_pods ready, $running_pods/$total_pods running"
        result=1
    fi
    
    return $result
}

check_http_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    local component=${3:-"service"}
    
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking $component endpoint: $url"
    fi
    
    # Use kubectl run to create a temporary pod for the health check
    local pod_name="health-check-$(date +%s)-$$"
    local result=0
    
    # Create a temporary pod with curl
    kubectl run "$pod_name" --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" --timeout="${TIMEOUT}s" -- \
        curl -f -s -w "%{http_code}" -o /dev/null --max-time "$TIMEOUT" "$url" >/tmp/health_check_result 2>/dev/null || result=1
    
    if [ $result -eq 0 ]; then
        local status_code=$(cat /tmp/health_check_result 2>/dev/null || echo "000")
        if [ "$status_code" = "$expected_status" ]; then
            if [ "$VERBOSE" = "true" ]; then
                log SUCCESS "$component endpoint healthy (HTTP $status_code)"
            fi
            return 0
        else
            log ERROR "$component endpoint returned HTTP $status_code (expected $expected_status)"
            return 1
        fi
    else
        log ERROR "$component endpoint unreachable or timed out"
        return 1
    fi
}

check_database_connectivity() {
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking database connectivity..."
    fi
    
    # Check if postgres service exists
    if ! kubectl get service postgres-service -n "$NAMESPACE" >/dev/null 2>&1; then
        log ERROR "PostgreSQL service not found"
        return 1
    fi
    
    # Test database connection using a temporary pod
    local pod_name="db-health-check-$(date +%s)"
    local result=0
    
    kubectl run "$pod_name" --rm -i --restart=Never --image=postgres:15-alpine -n "$NAMESPACE" --timeout="30s" -- \
        sh -c 'pg_isready -h postgres-service -p 5432 -U postgres' >/dev/null 2>&1 || result=1
    
    if [ $result -eq 0 ]; then
        if [ "$VERBOSE" = "true" ]; then
            log SUCCESS "Database connectivity check passed"
        fi
        return 0
    else
        log ERROR "Database connectivity check failed"
        return 1
    fi
}

check_redis_connectivity() {
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking Redis connectivity..."
    fi
    
    # Check if redis service exists
    if ! kubectl get service redis-service -n "$NAMESPACE" >/dev/null 2>&1; then
        log ERROR "Redis service not found"
        return 1
    fi
    
    # Test Redis connection using a temporary pod
    local pod_name="redis-health-check-$(date +%s)"
    local result=0
    
    kubectl run "$pod_name" --rm -i --restart=Never --image=redis:7-alpine -n "$NAMESPACE" --timeout="30s" -- \
        sh -c 'redis-cli -h redis-service -p 6379 ping' >/dev/null 2>&1 || result=1
    
    if [ $result -eq 0 ]; then
        if [ "$VERBOSE" = "true" ]; then
            log SUCCESS "Redis connectivity check passed"
        fi
        return 0
    else
        log ERROR "Redis connectivity check failed"
        return 1
    fi
}

check_resource_usage() {
    if [ "$VERBOSE" = "true" ]; then
        log INFO "Checking resource usage..."
    fi
    
    # Check node resources
    local nodes=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" 2>/dev/null || echo "")
    
    for node in $nodes; do
        # Get node resource usage
        local cpu_usage=$(kubectl top node "$node" --no-headers 2>/dev/null | awk '{print $3}' | sed 's/%//' || echo "0")
        local memory_usage=$(kubectl top node "$node" --no-headers 2>/dev/null | awk '{print $5}' | sed 's/%//' || echo "0")
        
        if [ "$cpu_usage" -gt 80 ]; then
            log WARN "Node $node CPU usage high: ${cpu_usage}%"
        fi
        
        if [ "$memory_usage" -gt 80 ]; then
            log WARN "Node $node memory usage high: ${memory_usage}%"
        fi
        
        if [ "$VERBOSE" = "true" ]; then
            log INFO "Node $node: CPU ${cpu_usage}%, Memory ${memory_usage}%"
        fi
    done
    
    # Check pod resource usage
    local pods=$(kubectl top pods -n "$NAMESPACE" --no-headers 2>/dev/null || echo "")
    
    if [ -n "$pods" ]; then
        while IFS= read -r line; do
            local pod_name=$(echo "$line" | awk '{print $1}')
            local cpu_usage=$(echo "$line" | awk '{print $2}' | sed 's/m$//')
            local memory_usage=$(echo "$line" | awk '{print $3}' | sed 's/Mi$//')
            
            # Check for high resource usage (these are basic thresholds)
            if [ "$cpu_usage" -gt 500 ]; then  # 500m = 0.5 CPU
                log WARN "Pod $pod_name high CPU usage: ${cpu_usage}m"
            fi
            
            if [ "$memory_usage" -gt 512 ]; then  # 512Mi
                log WARN "Pod $pod_name high memory usage: ${memory_usage}Mi"
            fi
            
            if [ "$VERBOSE" = "true" ]; then
                log INFO "Pod $pod_name: CPU ${cpu_usage}m, Memory ${memory_usage}Mi"
            fi
        done <<< "$pods"
    fi
}

perform_health_check() {
    local overall_status=0
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Initialize results
    local results=()
    
    # Check pod health
    local components=("database" "redis" "backend" "frontend")
    
    for component in "${components[@]}"; do
        if check_pod_health "$component"; then
            results+=("$component:pods:healthy")
        else
            results+=("$component:pods:unhealthy")
            overall_status=1
        fi
    done
    
    # Check database connectivity
    if check_database_connectivity; then
        results+=("database:connectivity:healthy")
    else
        results+=("database:connectivity:unhealthy")
        overall_status=1
    fi
    
    # Check Redis connectivity
    if check_redis_connectivity; then
        results+=("redis:connectivity:healthy")
    else
        results+=("redis:connectivity:unhealthy")
        overall_status=1
    fi
    
    # Check HTTP endpoints
    local frontend_endpoint=$(get_service_endpoint "frontend-service" "http" || echo "")
    if [ -n "$frontend_endpoint" ]; then
        if check_http_endpoint "$frontend_endpoint$FRONTEND_HEALTH_PATH" "200" "frontend"; then
            results+=("frontend:http:healthy")
        else
            results+=("frontend:http:unhealthy")
            overall_status=1
        fi
    else
        log WARN "Frontend service endpoint not found"
        results+=("frontend:http:unknown")
    fi
    
    local backend_endpoint=$(get_service_endpoint "backend-service" "http" || echo "")
    if [ -n "$backend_endpoint" ]; then
        if check_http_endpoint "$backend_endpoint$BACKEND_HEALTH_PATH" "200" "backend"; then
            results+=("backend:http:healthy")
        else
            results+=("backend:http:unhealthy")
            overall_status=1
        fi
        
        # Check readiness endpoint
        if check_http_endpoint "$backend_endpoint$BACKEND_READY_PATH" "200" "backend-ready"; then
            results+=("backend:ready:healthy")
        else
            results+=("backend:ready:unhealthy")
            overall_status=1
        fi
    else
        log WARN "Backend service endpoint not found"
        results+=("backend:http:unknown")
        results+=("backend:ready:unknown")
    fi
    
    # Check resource usage
    check_resource_usage
    
    # Output results based on format
    case $OUTPUT_FORMAT in
        json)
            output_json_results "$timestamp" "$overall_status" "${results[@]}"
            ;;
        prometheus)
            output_prometheus_results "$timestamp" "$overall_status" "${results[@]}"
            ;;
        *)
            output_text_results "$timestamp" "$overall_status" "${results[@]}"
            ;;
    esac
    
    return $overall_status
}

output_text_results() {
    local timestamp=$1
    local overall_status=$2
    shift 2
    local results=("$@")
    
    echo "Health Check Results - $timestamp"
    echo "=================================="
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    for result in "${results[@]}"; do
        IFS=':' read -r component check status <<< "$result"
        case $status in
            healthy)
                echo -e "${GREEN}✓${NC} $component $check: $status"
                ;;
            unhealthy)
                echo -e "${RED}✗${NC} $component $check: $status"
                ;;
            unknown)
                echo -e "${YELLOW}?${NC} $component $check: $status"
                ;;
        esac
    done
    
    echo ""
    if [ $overall_status -eq 0 ]; then
        echo -e "Overall Status: ${GREEN}HEALTHY${NC}"
    else
        echo -e "Overall Status: ${RED}UNHEALTHY${NC}"
    fi
}

output_json_results() {
    local timestamp=$1
    local overall_status=$2
    shift 2
    local results=("$@")
    
    echo "{"
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"environment\": \"$ENVIRONMENT\","
    echo "  \"namespace\": \"$NAMESPACE\","
    echo "  \"overall_status\": $([ $overall_status -eq 0 ] && echo '"healthy"' || echo '"unhealthy"'),"
    echo "  \"checks\": ["
    
    local first=true
    for result in "${results[@]}"; do
        IFS=':' read -r component check status <<< "$result"
        
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        
        echo -n "    {\"component\": \"$component\", \"check\": \"$check\", \"status\": \"$status\"}"
    done
    
    echo ""
    echo "  ]"
    echo "}"
}

output_prometheus_results() {
    local timestamp=$1
    local overall_status=$2
    shift 2
    local results=("$@")
    
    local timestamp_ms=$(date +%s)000
    
    echo "# HELP inventario_pymes_health_check Health check status for Sistema de Inventario PYMES"
    echo "# TYPE inventario_pymes_health_check gauge"
    
    for result in "${results[@]}"; do
        IFS=':' read -r component check status <<< "$result"
        local value=0
        
        case $status in
            healthy) value=1 ;;
            unhealthy) value=0 ;;
            unknown) value=-1 ;;
        esac
        
        echo "inventario_pymes_health_check{environment=\"$ENVIRONMENT\",namespace=\"$NAMESPACE\",component=\"$component\",check=\"$check\"} $value $timestamp_ms"
    done
    
    echo "# HELP inventario_pymes_overall_health Overall health status"
    echo "# TYPE inventario_pymes_overall_health gauge"
    echo "inventario_pymes_overall_health{environment=\"$ENVIRONMENT\",namespace=\"$NAMESPACE\"} $([ $overall_status -eq 0 ] && echo 1 || echo 0) $timestamp_ms"
}

main() {
    check_prerequisites
    
    if [ "$CONTINUOUS" = "true" ]; then
        log INFO "Starting continuous health checks (interval: ${INTERVAL}s)"
        log INFO "Press Ctrl+C to stop"
        
        while true; do
            perform_health_check
            echo ""
            sleep "$INTERVAL"
        done
    else
        perform_health_check
    fi
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
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -c|--continuous)
            CONTINUOUS="true"
            shift
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
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