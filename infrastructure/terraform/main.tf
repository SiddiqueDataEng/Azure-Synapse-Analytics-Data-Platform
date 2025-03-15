# =====================================================
# Azure Synapse Analytics Data Platform (ASADP)
# Terraform Configuration - Production-Ready Infrastructure
# =====================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =====================================================
# Data Sources
# =====================================================
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# =====================================================
# Random Suffix
# =====================================================
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# =====================================================
# Local Variables
# =====================================================
locals {
  resource_prefix = "asadp-${var.environment}-${random_string.suffix.result}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = "ASADP"
    ManagedBy   = "Terraform"
  })

  # Environment-specific configurations
  sql_pool_config = {
    dev = {
      name = "DataWarehouse"
      sku  = "DW100c"
    }
    test = {
      name = "DataWarehouse"
      sku  = "DW200c"
    }
    prod = {
      name = "DataWarehouse"
      sku  = "DW500c"
    }
  }

  spark_pool_config = {
    dev = {
      name           = "SparkPool"
      node_size      = "Small"
      min_node_count = 3
      max_node_count = 10
      auto_pause     = true
      delay_minutes  = 15
    }
    test = {
      name           = "SparkPool"
      node_size      = "Medium"
      min_node_count = 3
      max_node_count = 20
      auto_pause     = true
      delay_minutes  = 15
    }
    prod = {
      name           = "SparkPool"
      node_size      = "Large"
      min_node_count = 5
      max_node_count = 50
      auto_pause     = false
      delay_minutes  = 30
    }
  }
}

# =====================================================
# Key Vault
# =====================================================
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.resource_prefix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true
  enable_rbac_authorization       = true
  soft_delete_retention_days      = 90
  purge_protection_enabled        = var.environment == "prod"

  network_acls {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# =====================================================
# Data Lake Storage Gen2
# =====================================================
resource "azurerm_storage_account" "data_lake" {
  name                = "dl${replace(local.resource_prefix, "-", "")}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "ZRS" : "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  is_hns_enabled          = true # Enable hierarchical namespace for Data Lake Gen2

  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = true

  network_rules {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = var.environment == "prod"
    
    delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
    
    container_delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
  }

  tags = local.common_tags
}

# Data Lake containers
resource "azurerm_storage_container" "containers" {
  for_each = toset([
    "raw",
    "processed",
    "curated",
    "sandbox",
    "synapse",
    "models",
    "logs"
  ])

  name                  = each.value
  storage_account_name  = azurerm_storage_account.data_lake.name
  container_access_type = "private"
}

# =====================================================
# Log Analytics Workspace
# =====================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.resource_prefix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  daily_quota_gb      = var.environment == "prod" ? 50 : 10

  tags = local.common_tags
}

# =====================================================
# Application Insights
# =====================================================
resource "azurerm_application_insights" "main" {
  name                = "ai-${local.resource_prefix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.common_tags
}

# =====================================================
# Container Registry
# =====================================================
resource "azurerm_container_registry" "main" {
  name                = "cr${replace(local.resource_prefix, "-", "")}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.environment == "prod" ? "Premium" : "Standard"
  admin_enabled       = true

  public_network_access_enabled = !var.enable_private_endpoints
  zone_redundancy_enabled       = var.environment == "prod"

  tags = local.common_tags
}

# =====================================================
# Machine Learning Workspace
# =====================================================
resource "azurerm_machine_learning_workspace" "main" {
  name                    = "ml-${local.resource_prefix}"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.main.name
  application_insights_id = azurerm_application_insights.main.id
  key_vault_id           = azurerm_key_vault.main.id
  storage_account_id     = azurerm_storage_account.data_lake.id
  container_registry_id  = azurerm_container_registry.main.id
  
  public_network_access_enabled = !var.enable_private_endpoints
  high_business_impact          = var.environment == "prod"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# =====================================================
# Synapse Analytics Workspace
# =====================================================
resource "azurerm_synapse_workspace" "main" {
  name                = "synapse-${local.resource_prefix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.sql_admin_username
  sql_administrator_login_password     = var.sql_admin_password
  managed_virtual_network_enabled      = var.enable_managed_vnet
  public_network_access_enabled        = !var.enable_private_endpoints
  managed_resource_group_name          = "rg-synapse-${local.resource_prefix}-managed"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Synapse filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.data_lake.id
}

# Synapse firewall rules
resource "azurerm_synapse_firewall_rule" "allow_azure" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource "azurerm_synapse_firewall_rule" "allow_all" {
  count                = var.enable_private_endpoints ? 0 : 1
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# =====================================================
# Synapse SQL Pool (Dedicated)
# =====================================================
resource "azurerm_synapse_sql_pool" "main" {
  name                 = local.sql_pool_config[var.environment].name
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  sku_name             = local.sql_pool_config[var.environment].sku
  create_mode          = "Default"
  collation            = "SQL_Latin1_General_CP1_CI_AS"

  tags = local.common_tags
}

# =====================================================
# Synapse Spark Pool
# =====================================================
resource "azurerm_synapse_spark_pool" "main" {
  name                 = local.spark_pool_config[var.environment].name
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  node_size_family     = "MemoryOptimized"
  node_size            = local.spark_pool_config[var.environment].node_size
  node_count           = local.spark_pool_config[var.environment].min_node_count

  auto_scale {
    max_node_count = local.spark_pool_config[var.environment].max_node_count
    min_node_count = local.spark_pool_config[var.environment].min_node_count
  }

  auto_pause {
    delay_in_minutes = local.spark_pool_config[var.environment].delay_minutes
  }

  spark_version = "3.4"

  library_requirement {
    content  = file("../../synapse/spark-pools/configurations/requirements.txt")
    filename = "requirements.txt"
  }

  session_level_packages_enabled = true
  cache_size                     = var.environment == "prod" ? 100 : 50

  tags = local.common_tags
}

# =====================================================
# Role Assignments
# =====================================================

# Synapse workspace managed identity access to Data Lake
resource "azurerm_role_assignment" "synapse_data_lake" {
  scope                = azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main.identity[0].principal_id
}

# ML workspace access to Data Lake
resource "azurerm_role_assignment" "ml_data_lake" {
  scope                = azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

# =====================================================
# Private Endpoints (if enabled)
# =====================================================
resource "azurerm_private_endpoint" "synapse" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-synapse-${local.resource_prefix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = var.synapse_subnet_id

  private_service_connection {
    name                           = "synapse-connection"
    private_connection_resource_id = azurerm_synapse_workspace.main.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "data_lake" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-datalake-${local.resource_prefix}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "datalake-connection"
    private_connection_resource_id = azurerm_storage_account.data_lake.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# =====================================================
# Diagnostic Settings
# =====================================================
resource "azurerm_monitor_diagnostic_setting" "synapse" {
  name                       = "synapse-diagnostics"
  target_resource_id         = azurerm_synapse_workspace.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "SynapseRbacOperations"
  }

  enabled_log {
    category = "GatewayApiRequests"
  }

  enabled_log {
    category = "BuiltinSqlReqsEnded"
  }

  enabled_log {
    category = "IntegrationPipelineRuns"
  }

  enabled_log {
    category = "IntegrationActivityRuns"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_pool" {
  name                       = "sqlpool-diagnostics"
  target_resource_id         = azurerm_synapse_sql_pool.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "SqlRequests"
  }

  enabled_log {
    category = "RequestSteps"
  }

  enabled_log {
    category = "ExecRequests"
  }

  enabled_log {
    category = "DmsWorkers"
  }

  enabled_log {
    category = "Waits"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}