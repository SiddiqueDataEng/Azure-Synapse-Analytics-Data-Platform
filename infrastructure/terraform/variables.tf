# =====================================================
# Azure Synapse Analytics Data Platform (ASADP)
# Terraform Variables
# =====================================================

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sql_admin_username" {
  description = "SQL Administrator username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Administrator password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.sql_admin_password) >= 12
    error_message = "SQL admin password must be at least 12 characters long."
  }
}

variable "admin_email" {
  description = "Administrator email for notifications"
  type        = string
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = false
}

variable "enable_managed_vnet" {
  description = "Enable managed virtual network for Synapse workspace"
  type        = bool
  default     = true
}

variable "synapse_subnet_id" {
  description = "Subnet ID for Synapse private endpoint"
  type        = string
  default     = null
}

variable "data_subnet_id" {
  description = "Subnet ID for Data Lake private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Owner       = "DataEngineering"
    CostCenter  = "IT-DataPlatform"
    Project     = "ASADP"
  }
}

# =====================================================
# Synapse Configuration Variables
# =====================================================

variable "synapse_workspace_config" {
  description = "Synapse workspace configuration"
  type = object({
    enable_git_integration = optional(bool, false)
    git_account_name      = optional(string, "")
    git_project_name      = optional(string, "")
    git_repository_name   = optional(string, "")
    git_collaboration_branch = optional(string, "main")
    git_root_folder       = optional(string, "/synapse")
  })
  default = {}
}

variable "sql_pool_config" {
  description = "SQL Pool configuration overrides"
  type = object({
    name                    = optional(string, "DataWarehouse")
    sku_name               = optional(string, null)
    create_mode            = optional(string, "Default")
    collation              = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    geo_backup_policy_enabled = optional(bool, true)
  })
  default = {}
}

variable "spark_pool_config" {
  description = "Spark Pool configuration overrides"
  type = object({
    name                           = optional(string, "SparkPool")
    node_size_family              = optional(string, "MemoryOptimized")
    node_size                     = optional(string, null)
    min_node_count                = optional(number, null)
    max_node_count                = optional(number, null)
    auto_pause_enabled            = optional(bool, true)
    auto_pause_delay_in_minutes   = optional(number, 15)
    spark_version                 = optional(string, "3.4")
    session_level_packages_enabled = optional(bool, true)
    cache_size                    = optional(number, null)
  })
  default = {}
}

# =====================================================
# Data Lake Configuration Variables
# =====================================================

variable "data_lake_config" {
  description = "Data Lake configuration"
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, null)
    access_tier              = optional(string, "Hot")
    enable_versioning        = optional(bool, null)
    backup_retention_days    = optional(number, null)
  })
  default = {}
}

variable "data_lake_containers" {
  description = "List of containers to create in the data lake"
  type        = list(string)
  default = [
    "raw",
    "processed", 
    "curated",
    "sandbox",
    "synapse",
    "models",
    "logs"
  ]
}

# =====================================================
# Security Configuration Variables
# =====================================================

variable "security_config" {
  description = "Security configuration"
  type = object({
    key_vault_sku                    = optional(string, "standard")
    key_vault_soft_delete_retention  = optional(number, 90)
    enable_purge_protection          = optional(bool, null)
    enable_rbac_authorization        = optional(bool, true)
  })
  default = {}
}

# =====================================================
# Monitoring Configuration Variables
# =====================================================

variable "monitoring_config" {
  description = "Monitoring and logging configuration"
  type = object({
    log_analytics_sku         = optional(string, "PerGB2018")
    log_retention_days        = optional(number, null)
    daily_quota_gb           = optional(number, null)
    application_insights_type = optional(string, "web")
  })
  default = {}
}

# =====================================================
# Machine Learning Configuration Variables
# =====================================================

variable "ml_config" {
  description = "Machine Learning workspace configuration"
  type = object({
    friendly_name                    = optional(string, "Synapse ML Workspace")
    high_business_impact            = optional(bool, null)
    enable_public_network_access    = optional(bool, null)
    container_registry_sku          = optional(string, null)
  })
  default = {}
}

# =====================================================
# Network Configuration Variables
# =====================================================

variable "network_config" {
  description = "Network configuration"
  type = object({
    virtual_network_name    = optional(string, "")
    synapse_subnet_name     = optional(string, "synapse-subnet")
    data_subnet_name        = optional(string, "data-subnet")
    enable_ddos_protection  = optional(bool, false)
  })
  default = {}
}

# =====================================================
# Backup and Disaster Recovery Variables
# =====================================================

variable "backup_config" {
  description = "Backup and disaster recovery configuration"
  type = object({
    enable_geo_backup           = optional(bool, true)
    backup_retention_days       = optional(number, 7)
    enable_point_in_time_restore = optional(bool, true)
    cross_region_restore_enabled = optional(bool, false)
  })
  default = {}
}

# =====================================================
# Cost Management Variables
# =====================================================

variable "cost_config" {
  description = "Cost management configuration"
  type = object({
    enable_auto_pause           = optional(bool, true)
    auto_pause_delay_minutes    = optional(number, 15)
    enable_auto_scale           = optional(bool, true)
    budget_amount               = optional(number, 1000)
    budget_time_grain           = optional(string, "Monthly")
  })
  default = {}
}

# =====================================================
# Development and Testing Variables
# =====================================================

variable "dev_config" {
  description = "Development and testing configuration"
  type = object({
    enable_sample_data          = optional(bool, false)
    create_sample_notebooks     = optional(bool, false)
    create_sample_pipelines     = optional(bool, false)
    enable_debug_logging        = optional(bool, false)
  })
  default = {}
}