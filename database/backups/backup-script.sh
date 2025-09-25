#!/bin/bash

# Backup Script for Sistema de Inventario PYMES
# Author: Sistema de Inventario PYMES Team
# Date: 2024-01-15
# Description: Automated database backup script with rotation and compression

# ==================== CONFIGURATION ====================

# Database configuration
DB_NAME="${DB_NAME:-inventario_pymes}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Backup configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/inventario_pymes}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
COMPRESS_BACKUPS="${COMPRESS_BACKUPS:-true}"
ENCRYPT_BACKUPS="${ENCRYPT_BACKUPS:-false}"
ENCRYPTION_KEY_FILE="${ENCRYPTION_KEY_FILE:-/etc/inventario_pymes/backup.key}"

# Notification configuration
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-true}"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-admin@inventario-pymes.com}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# S3 configuration (optional)
S3_BACKUP_ENABLED="${S3_BACKUP_ENABLED:-false}"
S3_BUCKET="${S3_BUCKET:-inventario-pymes-backups}"
S3_REGION="${S3_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# ==================== FUNCTIONS ====================

# Logging function
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# Error handling
handle_error() {
    local exit_code=$1
    local error_message=$2
    log "ERROR" "$error_message"
    send_notification "FAILED" "$error_message"
    cleanup_temp_files
    exit $exit_code
}

# Send notification
send_notification() {
    local status=$1
    local message=$2
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        # Email notification
        if command -v mail >/dev/null 2>&1 && [ -n "$NOTIFICATION_EMAIL" ]; then
            echo "Backup Status: $status - $message" | mail -s "Database Backup $status" "$NOTIFICATION_EMAIL"
        fi
        
        # Slack notification
        if [ -n "$SLACK_WEBHOOK_URL" ]; then
            local color="good"
            [ "$status" = "FAILED" ] && color="danger"
            
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"attachments\":[{\"color\":\"$color\",\"title\":\"Database Backup $status\",\"text\":\"$message\"}]}" \
                "$SLACK_WEBHOOK_URL" >/dev/null 2>&1
        fi
    fi
}

# Cleanup temporary files
cleanup_temp_files() {
    if [ -n "$TEMP_BACKUP_FILE" ] && [ -f "$TEMP_BACKUP_FILE" ]; then
        rm -f "$TEMP_BACKUP_FILE"
        log "INFO" "Cleaned up temporary file: $TEMP_BACKUP_FILE"
    fi
}

# Create backup directory
create_backup_directory() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR" || handle_error 1 "Failed to create backup directory: $BACKUP_DIR"
        log "INFO" "Created backup directory: $BACKUP_DIR"
    fi
}

# Generate backup filename
generate_backup_filename() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local hostname=$(hostname -s)
    echo "${DB_NAME}_${hostname}_${timestamp}.sql"
}

# Perform database backup
perform_backup() {
    local backup_file=$1
    local temp_file="${backup_file}.tmp"
    
    log "INFO" "Starting database backup: $backup_file"
    
    # Set PGPASSWORD if provided
    export PGPASSWORD="$DB_PASSWORD"
    
    # Perform backup with pg_dump
    pg_dump \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --username="$DB_USER" \
        --dbname="$DB_NAME" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --encoding=UTF8 \
        --no-password \
        > "$temp_file" 2>>"$LOG_FILE"
    
    local exit_code=$?
    unset PGPASSWORD
    
    if [ $exit_code -ne 0 ]; then
        rm -f "$temp_file"
        handle_error $exit_code "pg_dump failed with exit code $exit_code"
    fi
    
    # Move temp file to final location
    mv "$temp_file" "$backup_file" || handle_error 1 "Failed to move backup file"
    
    log "INFO" "Database backup completed: $backup_file"
    return 0
}

# Compress backup
compress_backup() {
    local backup_file=$1
    
    if [ "$COMPRESS_BACKUPS" = "true" ]; then
        log "INFO" "Compressing backup: $backup_file"
        
        gzip "$backup_file" || handle_error 1 "Failed to compress backup"
        
        local compressed_file="${backup_file}.gz"
        log "INFO" "Backup compressed: $compressed_file"
        echo "$compressed_file"
    else
        echo "$backup_file"
    fi
}

# Encrypt backup
encrypt_backup() {
    local backup_file=$1
    
    if [ "$ENCRYPT_BACKUPS" = "true" ]; then
        if [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
            handle_error 1 "Encryption key file not found: $ENCRYPTION_KEY_FILE"
        fi
        
        log "INFO" "Encrypting backup: $backup_file"
        
        local encrypted_file="${backup_file}.enc"
        openssl enc -aes-256-cbc -salt -in "$backup_file" -out "$encrypted_file" -pass file:"$ENCRYPTION_KEY_FILE" \
            || handle_error 1 "Failed to encrypt backup"
        
        # Remove unencrypted file
        rm -f "$backup_file"
        
        log "INFO" "Backup encrypted: $encrypted_file"
        echo "$encrypted_file"
    else
        echo "$backup_file"
    fi
}

# Upload to S3
upload_to_s3() {
    local backup_file=$1
    
    if [ "$S3_BACKUP_ENABLED" = "true" ]; then
        if ! command -v aws >/dev/null 2>&1; then
            log "WARNING" "AWS CLI not found, skipping S3 upload"
            return 0
        fi
        
        log "INFO" "Uploading backup to S3: s3://$S3_BUCKET/"
        
        local s3_key="backups/$(basename "$backup_file")"
        aws s3 cp "$backup_file" "s3://$S3_BUCKET/$s3_key" \
            --region "$S3_REGION" \
            --profile "$AWS_PROFILE" \
            --storage-class STANDARD_IA \
            || log "WARNING" "Failed to upload backup to S3"
        
        log "INFO" "Backup uploaded to S3: s3://$S3_BUCKET/$s3_key"
    fi
}

# Rotate old backups
rotate_backups() {
    log "INFO" "Rotating old backups (retention: $BACKUP_RETENTION_DAYS days)"
    
    # Find and delete old backups
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
    
    local deleted_count=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$BACKUP_RETENTION_DAYS | wc -l)
    
    if [ $deleted_count -gt 0 ]; then
        log "INFO" "Deleted $deleted_count old backup files"
    else
        log "INFO" "No old backup files to delete"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file=$1
    
    log "INFO" "Verifying backup integrity: $backup_file"
    
    # Check if file exists and is not empty
    if [ ! -f "$backup_file" ] || [ ! -s "$backup_file" ]; then
        handle_error 1 "Backup file is missing or empty: $backup_file"
    fi
    
    # For compressed files, test compression integrity
    if [[ "$backup_file" == *.gz ]]; then
        gzip -t "$backup_file" || handle_error 1 "Backup file is corrupted (gzip test failed)"
    fi
    
    # For encrypted files, we can't easily verify without decrypting
    # but we can check if it's a valid encrypted file
    if [[ "$backup_file" == *.enc ]]; then
        # Basic check - encrypted files should have some minimum size
        local file_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null)
        if [ "$file_size" -lt 1000 ]; then
            handle_error 1 "Encrypted backup file seems too small: $backup_file"
        fi
    fi
    
    log "INFO" "Backup integrity verification passed"
}

# Get backup statistics
get_backup_stats() {
    local backup_file=$1
    local file_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null)
    local file_size_mb=$((file_size / 1024 / 1024))
    
    echo "Backup Statistics:"
    echo "  File: $(basename "$backup_file")"
    echo "  Size: ${file_size_mb} MB"
    echo "  Location: $backup_file"
    echo "  Created: $(date)"
}

# ==================== MAIN EXECUTION ====================

main() {
    # Initialize logging
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    LOG_FILE="$BACKUP_DIR/backup_${timestamp}.log"
    
    # Create backup directory
    create_backup_directory
    
    # Start logging
    log "INFO" "Starting database backup process"
    log "INFO" "Database: $DB_NAME@$DB_HOST:$DB_PORT"
    log "INFO" "Backup directory: $BACKUP_DIR"
    
    # Generate backup filename
    local backup_filename=$(generate_backup_filename)
    local backup_file="$BACKUP_DIR/$backup_filename"
    TEMP_BACKUP_FILE="$backup_file"
    
    # Perform backup
    perform_backup "$backup_file"
    
    # Compress if enabled
    backup_file=$(compress_backup "$backup_file")
    
    # Encrypt if enabled
    backup_file=$(encrypt_backup "$backup_file")
    
    # Verify backup integrity
    verify_backup "$backup_file"
    
    # Upload to S3 if enabled
    upload_to_s3 "$backup_file"
    
    # Rotate old backups
    rotate_backups
    
    # Get backup statistics
    local stats=$(get_backup_stats "$backup_file")
    log "INFO" "Backup completed successfully"
    log "INFO" "$stats"
    
    # Send success notification
    send_notification "SUCCESS" "Database backup completed successfully. $stats"
    
    # Cleanup
    cleanup_temp_files
    
    log "INFO" "Backup process finished"
}

# ==================== SCRIPT EXECUTION ====================

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    command -v pg_dump >/dev/null 2>&1 || missing_deps+=("pg_dump")
    
    if [ "$COMPRESS_BACKUPS" = "true" ]; then
        command -v gzip >/dev/null 2>&1 || missing_deps+=("gzip")
    fi
    
    if [ "$ENCRYPT_BACKUPS" = "true" ]; then
        command -v openssl >/dev/null 2>&1 || missing_deps+=("openssl")
    fi
    
    if [ "$S3_BACKUP_ENABLED" = "true" ]; then
        command -v aws >/dev/null 2>&1 || missing_deps+=("aws-cli")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Database backup script for Sistema de Inventario PYMES

OPTIONS:
    -h, --help          Show this help message
    -c, --config FILE   Use custom configuration file
    -d, --dry-run       Show what would be done without executing
    -v, --verbose       Enable verbose output

ENVIRONMENT VARIABLES:
    DB_NAME             Database name (default: inventario_pymes)
    DB_USER             Database user (default: postgres)
    DB_HOST             Database host (default: localhost)
    DB_PORT             Database port (default: 5432)
    DB_PASSWORD         Database password
    BACKUP_DIR          Backup directory (default: /var/backups/inventario_pymes)
    BACKUP_RETENTION_DAYS  Backup retention in days (default: 30)

EXAMPLES:
    $0                  Run backup with default settings
    $0 -v               Run backup with verbose output
    $0 -c /etc/backup.conf  Run backup with custom config

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Load configuration file if specified
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check dependencies
check_dependencies

# Run main function
if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN MODE - No actual backup will be performed"
    echo "Would backup database: $DB_NAME"
    echo "Would save to: $BACKUP_DIR"
    echo "Compression enabled: $COMPRESS_BACKUPS"
    echo "Encryption enabled: $ENCRYPT_BACKUPS"
    echo "S3 upload enabled: $S3_BACKUP_ENABLED"
else
    main
fi