# Terraform Variables for Sistema de Inventario PYMES
# Define all configurable parameters for infrastructure deployment

# ==================== GENERAL CONFIGURATION ====================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "inventario-pymes"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==================== NETWORKING CONFIGURATION ====================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

# ==================== EKS CLUSTER CONFIGURATION ====================

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.27"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

variable "node_ssh_key" {
  description = "EC2 Key Pair name for SSH access to worker nodes"
  type        = string
  default     = ""
}

# ==================== DATABASE CONFIGURATION ====================

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "inventario_pymes"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "inventario_user"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# ==================== REDIS CONFIGURATION ====================

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster"
  type        = number
  default     = 1
}

variable "redis_auth_token" {
  description = "Auth token for Redis cluster"
  type        = string
  sensitive   = true
  default     = ""
}

# ==================== STORAGE CONFIGURATION ====================

variable "enable_s3_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_lifecycle_enabled" {
  description = "Enable lifecycle management on S3 buckets"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups in S3"
  type        = number
  default     = 30
}

# ==================== MONITORING CONFIGURATION ====================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for EKS cluster"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 14
}

variable "enable_container_insights" {
  description = "Enable Container Insights for EKS cluster"
  type        = bool
  default     = true
}

# ==================== SECURITY CONFIGURATION ====================

variable "enable_encryption" {
  description = "Enable encryption for all supported resources"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ==================== APPLICATION CONFIGURATION ====================

variable "app_domain" {
  description = "Domain name for the application"
  type        = string
  default     = "inventario-pymes.com"
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for the domain"
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Enable AWS WAF for the application"
  type        = bool
  default     = false
}

# ==================== COST OPTIMIZATION ====================

variable "enable_spot_instances" {
  description = "Enable spot instances for worker nodes"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "EC2 spot instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "m5.large"]
}

# ==================== ENVIRONMENT-SPECIFIC DEFAULTS ====================

locals {
  # Environment-specific configurations
  env_config = {
    dev = {
      node_desired_size           = 2
      node_max_size              = 5
      node_min_size              = 1
      db_instance_class          = "db.t3.micro"
      redis_node_type            = "cache.t3.micro"
      db_backup_retention_period = 3
      log_retention_days         = 7
      enable_deletion_protection = false
    }
    staging = {
      node_desired_size           = 3
      node_max_size              = 8
      node_min_size              = 2
      db_instance_class          = "db.t3.small"
      redis_node_type            = "cache.t3.small"
      db_backup_retention_period = 7
      log_retention_days         = 14
      enable_deletion_protection = false
    }
    production = {
      node_desired_size           = 5
      node_max_size              = 20
      node_min_size              = 3
      db_instance_class          = "db.t3.medium"
      redis_node_type            = "cache.t3.medium"
      redis_num_cache_nodes      = 2
      db_backup_retention_period = 30
      log_retention_days         = 30
      enable_deletion_protection = true
    }
  }
  
  # Current environment configuration
  current_env = local.env_config[var.environment]
  
  # Common tags
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.tags
  )
}

# ==================== VALIDATION RULES ====================

# Validate database password strength
variable "db_password_validation" {
  description = "Enable database password validation"
  type        = bool
  default     = true
  
  validation {
    condition = var.db_password_validation == false || (
      length(var.db_password) >= 8 &&
      can(regex("[A-Z]", var.db_password)) &&
      can(regex("[a-z]", var.db_password)) &&
      can(regex("[0-9]", var.db_password))
    )
    error_message = "Database password must be at least 8 characters long and contain uppercase, lowercase, and numeric characters."
  }
}

# Validate environment-specific constraints
locals {
  validation_errors = [
    for constraint in [
      {
        condition = var.environment == "production" ? var.node_min_size >= 3 : true
        message   = "Production environment must have at least 3 worker nodes"
      },
      {
        condition = var.environment == "production" ? var.db_backup_retention_period >= 7 : true
        message   = "Production environment must have at least 7 days backup retention"
      },
      {
        condition = var.node_max_size >= var.node_desired_size
        message   = "Maximum node size must be greater than or equal to desired size"
      },
      {
        condition = var.node_desired_size >= var.node_min_size
        message   = "Desired node size must be greater than or equal to minimum size"
      }
    ] : constraint.message if !constraint.condition
  ]
}

# Trigger validation errors
resource "null_resource" "validation" {
  count = length(local.validation_errors) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'Validation errors: ${join(", ", local.validation_errors)}' && exit 1"
  }
}