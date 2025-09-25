#!/bin/bash

# Restore Script for Sistema de Inventario PYMES
# Author: Sistema de Inventario PYMES Team
# Date: 2024-01-15
# Description: Database restore script with safety checks and validation

# ==================== CONFIGURATION ====================

# Database configuration
DB_NAME="${DB_NAME:-inventario_pymes}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

# Restore configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/inventario_pymes}"
FORCE_RESTORE="${FORCE_RESTORE:-false}"
CREATE_BACKUP_BEFORE_RESTORE="${CREATE_BACKUP_BEFORE_RESTORE:-true}"
VALIDATE_RESTORE="${VALIDATE_RESTORE:-true}"

# Safety configuration
REQUIRE_CONFIRMATION="${REQUIRE_CONFIRMATION:-true}"
ENCRYPTION_KEY_FILE="${ENCRYPTION_KEY_FILE:-/etc/inventario_pymes/backup.key}"

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
    cleanup_temp_files
    exit $exit_code
}

# Cleanup temporary files
cleanup_temp_files() {
    if [ -n "$TEMP_RESTORE_FILE" ] && [ -f "$TEMP_RESTORE_FILE" ]; then
        rm -f "$TEMP_RESTORE_FILE"
        log "INFO" "Cleaned up temporary file: $TEMP_RESTORE_FILE"
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] BACKUP_FILE

Database restore script for Sistema de Inventario PYMES

ARGUMENTS:
    BACKUP_FILE         Path to backup file to restore

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Force restore without confirmation
    -n, --no-backup     Skip creating backup before restore
    -v, --validate      Validate restore after completion (default)
    --no-validate       Skip restore validation
    -d, --dry-run       Show what would be done without executing
    -l, --list          List available backup files

ENVIRONMENT VARIABLES:
    DB_NAME             Database name (default: inventario_pymes)
    DB_USER             Database user (default: postgres)
    DB_HOST             Database host (default: localhost)
    DB_PORT             Database port (default: 5432)
    DB_PASSWORD         Database password
    BACKUP_DIR          Backup directory (default: /var/backups/inventario_pymes)

EXAMPLES:
    $0 backup_20240115_120000.sql.gz    Restore from compressed backup
    $0 -f backup.sql                     Force restore without confirmation
    $0 -l                                List available backup files
    $0 --dry-run backup.sql              Show what would be done

SAFETY FEATURES:
    - Creates backup before restore (unless --no-backup)
    - Requires confirmation (unless --force)
    - Validates restore integrity (unless --no-validate)
    - Supports encrypted and compressed backups

EOF
}

# List available backup files
list_backup_files() {
    echo "Available backup files in $BACKUP_DIR:"
    echo "========================================"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Backup directory not found: $BACKUP_DIR"
        return 1
    fi
    
    local files_found=false
    
    # List SQL files with details
    for file in "$BACKUP_DIR"/${DB_NAME}_*.sql*; do
        if [ -f "$file" ]; then
            files_found=true
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            local size_mb=$((size / 1024 / 1024))
            local date=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d. -f1)
            
            printf "%-40s %8s MB  %s\n" "$(basename "$file")" "$size_mb" "$date"
        fi
    done
    
    if [ "$files_found" = false ]; then
        echo "No backup files found matching pattern: ${DB_NAME}_*.sql*"
        return 1
    fi
    
    echo ""
    echo "Use the filename with this script to restore:"
    echo "  $0 <filename>"
}

# Validate backup file
validate_backup_file() {
    local backup_file=$1
    
    log "INFO" "Validating backup file: $backup_file"
    
    # Check if file exists
    if [ ! -f "$backup_file" ]; then
        handle_error 1 "Backup file not found: $backup_file"
    fi
    
    # Check if file is readable
    if [ ! -r "$backup_file" ]; then
        handle_error 1 "Backup file is not readable: $backup_file"
    fi
    
    # Check file size
    local file_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null)
    if [ "$file_size" -lt 100 ]; then
        handle_error 1 "Backup file seems too small (${file_size} bytes): $backup_file"
    fi
    
    # Validate compressed files
    if [[ "$backup_file" == *.gz ]]; then
        log "INFO" "Validating gzip compression"
        gzip -t "$backup_file" || handle_error 1 "Backup file is corrupted (gzip test failed)"
    fi
    
    log "INFO" "Backup file validation passed"
}

# Decrypt backup file
decrypt_backup() {
    local backup_file=$1
    
    if [[ "$backup_file" == *.enc ]]; then
        log "INFO" "Decrypting backup file"
        
        if [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
            handle_error 1 "Encryption key file not found: $ENCRYPTION_KEY_FILE"
        fi
        
        local decrypted_file="${backup_file%.enc}"
        TEMP_RESTORE_FILE="$decrypted_file"
        
        openssl enc -aes-256-cbc -d -in "$backup_file" -out "$decrypted_file" -pass file:"$ENCRYPTION_KEY_FILE" \
            || handle_error 1 "Failed to decrypt backup file"
        
        log "INFO" "Backup file decrypted: $decrypted_file"
        echo "$decrypted_file"
    else
        echo "$backup_file"
    fi
}

# Decompress backup file
decompress_backup() {
    local backup_file=$1
    
    if [[ "$backup_file" == *.gz ]]; then
        log "INFO" "Decompressing backup file"
        
        local decompressed_file="${backup_file%.gz}"
        
        # If we already have a temp file, decompress to a new temp file
        if [ -n "$TEMP_RESTORE_FILE" ]; then
            decompressed_file="${TEMP_RESTORE_FILE%.gz}_decompressed.sql"
            TEMP_RESTORE_FILE="$decompressed_file"
        fi
        
        gunzip -c "$backup_file" > "$decompressed_file" \
            || handle_error 1 "Failed to decompress backup file"
        
        log "INFO" "Backup file decompressed: $decompressed_file"
        echo "$decompressed_file"
    else
        echo "$backup_file"
    fi
}

# Check database connection
check_database_connection() {
    log "INFO" "Checking database connection"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1
    local exit_code=$?
    
    unset PGPASSWORD
    
    if [ $exit_code -ne 0 ]; then
        handle_error $exit_code "Cannot connect to database server"
    fi
    
    log "INFO" "Database connection successful"
}

# Create pre-restore backup
create_pre_restore_backup() {
    if [ "$CREATE_BACKUP_BEFORE_RESTORE" = "true" ]; then
        log "INFO" "Creating backup before restore"
        
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local hostname=$(hostname -s)
        local pre_restore_backup="$BACKUP_DIR/${DB_NAME}_${hostname}_pre_restore_${timestamp}.sql"
        
        export PGPASSWORD="$DB_PASSWORD"
        
        pg_dump \
            --host="$DB_HOST" \
            --port="$DB_PORT" \
            --username="$DB_USER" \
            --dbname="$DB_NAME" \
            --clean \
            --if-exists \
            --create \
            --format=plain \
            --encoding=UTF8 \
            --no-password \
            > "$pre_restore_backup" 2>>"$LOG_FILE"
        
        local exit_code=$?
        unset PGPASSWORD
        
        if [ $exit_code -eq 0 ]; then
            log "INFO" "Pre-restore backup created: $pre_restore_backup"
            
            # Compress the backup
            gzip "$pre_restore_backup"
            log "INFO" "Pre-restore backup compressed: ${pre_restore_backup}.gz"
        else
            log "WARNING" "Failed to create pre-restore backup (exit code: $exit_code)"
        fi
    fi
}

# Perform database restore
perform_restore() {
    local backup_file=$1
    
    log "INFO" "Starting database restore from: $backup_file"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    # Restore database
    psql \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --username="$DB_USER" \
        --dbname=postgres \
        --file="$backup_file" \
        --single-transaction \
        --set ON_ERROR_STOP=on \
        --quiet \
        2>>"$LOG_FILE"
    
    local exit_code=$?
    unset PGPASSWORD
    
    if [ $exit_code -ne 0 ]; then
        handle_error $exit_code "Database restore failed with exit code $exit_code"
    fi
    
    log "INFO" "Database restore completed successfully"
}

# Validate restore
validate_restore() {
    if [ "$VALIDATE_RESTORE" = "true" ]; then
        log "INFO" "Validating database restore"
        
        export PGPASSWORD="$DB_PASSWORD"
        
        # Check if database exists and is accessible
        local db_exists=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT 1;" 2>/dev/null | xargs)
        
        if [ "$db_exists" != "1" ]; then
            unset PGPASSWORD
            handle_error 1 "Database validation failed - database not accessible"
        fi
        
        # Check table count
        local table_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)
        
        if [ -z "$table_count" ] || [ "$table_count" -lt 5 ]; then
            unset PGPASSWORD
            handle_error 1 "Database validation failed - insufficient tables found ($table_count)"
        fi
        
        # Check for key tables
        local key_tables=("users" "products" "locations" "stock_levels" "inventory_movements")
        for table in "${key_tables[@]}"; do
            local exists=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table');" 2>/dev/null | xargs)
            
            if [ "$exists" != "t" ]; then
                unset PGPASSWORD
                handle_error 1 "Database validation failed - key table missing: $table"
            fi
        done
        
        unset PGPASSWORD
        
        log "INFO" "Database validation passed - found $table_count tables"
    fi
}

# Get user confirmation
get_confirmation() {
    if [ "$REQUIRE_CONFIRMATION" = "true" ] && [ "$FORCE_RESTORE" != "true" ]; then
        echo ""
        echo "WARNING: This will restore the database '$DB_NAME' on $DB_HOST:$DB_PORT"
        echo "This operation will OVERWRITE the current database content!"
        echo ""
        
        if [ "$CREATE_BACKUP_BEFORE_RESTORE" = "true" ]; then
            echo "A backup will be created before restore."
        else
            echo "NO backup will be created before restore."
        fi
        
        echo ""
        read -p "Are you sure you want to continue? (yes/no): " confirmation
        
        case $confirmation in
            yes|YES|y|Y)
                log "INFO" "User confirmed restore operation"
                ;;
            *)
                log "INFO" "Restore operation cancelled by user"
                exit 0
                ;;
        esac
    fi
}

# ==================== MAIN EXECUTION ====================

main() {
    local backup_file="$1"
    
    # Initialize logging
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    LOG_FILE="$BACKUP_DIR/restore_${timestamp}.log"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    log "INFO" "Starting database restore process"
    log "INFO" "Database: $DB_NAME@$DB_HOST:$DB_PORT"
    log "INFO" "Backup file: $backup_file"
    
    # Validate backup file
    validate_backup_file "$backup_file"
    
    # Check database connection
    check_database_connection
    
    # Get user confirmation
    get_confirmation
    
    # Decrypt if needed
    backup_file=$(decrypt_backup "$backup_file")
    
    # Decompress if needed
    backup_file=$(decompress_backup "$backup_file")
    
    # Create pre-restore backup
    create_pre_restore_backup
    
    # Perform restore
    perform_restore "$backup_file"
    
    # Validate restore
    validate_restore
    
    # Cleanup
    cleanup_temp_files
    
    log "INFO" "Database restore completed successfully"
    echo ""
    echo "Database restore completed successfully!"
    echo "Database: $DB_NAME"
    echo "Restored from: $(basename "$1")"
    echo "Log file: $LOG_FILE"
}

# ==================== SCRIPT EXECUTION ====================

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    command -v psql >/dev/null 2>&1 || missing_deps+=("psql")
    command -v pg_dump >/dev/null 2>&1 || missing_deps+=("pg_dump")
    command -v gunzip >/dev/null 2>&1 || missing_deps+=("gunzip")
    command -v openssl >/dev/null 2>&1 || missing_deps+=("openssl")
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Parse command line arguments
BACKUP_FILE=""
LIST_FILES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE_RESTORE=true
            REQUIRE_CONFIRMATION=false
            shift
            ;;
        -n|--no-backup)
            CREATE_BACKUP_BEFORE_RESTORE=false
            shift
            ;;
        -v|--validate)
            VALIDATE_RESTORE=true
            shift
            ;;
        --no-validate)
            VALIDATE_RESTORE=false
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -l|--list)
            LIST_FILES=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$BACKUP_FILE" ]; then
                BACKUP_FILE="$1"
            else
                echo "Multiple backup files specified. Please specify only one."
                exit 1
            fi
            shift
            ;;
    esac
done

# Check dependencies
check_dependencies

# Handle list files option
if [ "$LIST_FILES" = "true" ]; then
    list_backup_files
    exit 0
fi

# Validate arguments
if [ -z "$BACKUP_FILE" ]; then
    echo "Error: No backup file specified"
    echo ""
    show_usage
    exit 1
fi

# Convert relative path to absolute if needed
if [[ "$BACKUP_FILE" != /* ]]; then
    # If it's just a filename, look in backup directory
    if [[ "$BACKUP_FILE" != */* ]]; then
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    else
        BACKUP_FILE="$(pwd)/$BACKUP_FILE"
    fi
fi

# Run main function
if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN MODE - No actual restore will be performed"
    echo "Would restore database: $DB_NAME"
    echo "Would restore from: $BACKUP_FILE"
    echo "Pre-restore backup: $CREATE_BACKUP_BEFORE_RESTORE"
    echo "Validation enabled: $VALIDATE_RESTORE"
    echo "Force mode: $FORCE_RESTORE"
else
    main "$BACKUP_FILE"
fi