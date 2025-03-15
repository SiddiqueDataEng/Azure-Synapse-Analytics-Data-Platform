# =====================================================
# Azure Synapse Analytics Data Platform (ASADP)
# Terraform Outputs
# =====================================================

# =====================================================
# Resource Group Outputs
# =====================================================
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = data.azurerm_resource_group.main.location
}

# =====================================================
# Synapse Workspace Outputs
# =====================================================
output "synapse_workspace_name" {
  description = "Name of the Synapse workspace"
  value       = azurerm_synapse_workspace.main.name
}

output "synapse_workspace_id" {
  description = "ID of the Synapse workspace"
  value       = azurerm_synapse_workspace.main.id
}

output "synapse_workspace_identity_principal_id" {
  description = "Principal ID of the Synapse workspace managed identity"
  value       = azurerm_synapse_workspace.main.identity[0].principal_id
}

output "synapse_connectivity_endpoints" {
  description = "Synapse workspace connectivity endpoints"
  value       = azurerm_synapse_workspace.main.connectivity_endpoints
  sensitive   = false
}

output "synapse_web_url" {
  description = "Synapse Studio web URL"
  value       = "https://web.azuresynapse.net?workspace=%2Fsubscriptions%2F${data.azurerm_client_config.current.subscription_id}%2FresourceGroups%2F${data.azurerm_resource_group.main.name}%2Fproviders%2FMicrosoft.Synapse%2Fworkspaces%2F${azurerm_synapse_workspace.main.name}"
}

# =====================================================
# SQL Pool Outputs
# =====================================================
output "sql_pool_name" {
  description = "Name of the dedicated SQL pool"
  value       = azurerm_synapse_sql_pool.main.name
}

output "sql_pool_id" {
  description = "ID of the dedicated SQL pool"
  value       = azurerm_synapse_sql_pool.main.id
}

output "sql_pool_sku" {
  description = "SKU of the dedicated SQL pool"
  value       = azurerm_synapse_sql_pool.main.sku_name
}

# =====================================================
# Spark Pool Outputs
# =====================================================
output "spark_pool_name" {
  description = "Name of the Spark pool"
  value       = azurerm_synapse_spark_pool.main.name
}

output "spark_pool_id" {
  description = "ID of the Spark pool"
  value       = azurerm_synapse_spark_pool.main.id
}

output "spark_pool_node_size" {
  description = "Node size of the Spark pool"
  value       = azurerm_synapse_spark_pool.main.node_size
}

# =====================================================
# Data Lake Storage Outputs
# =====================================================
output "data_lake_storage_account_name" {
  description = "Name of the Data Lake Storage account"
  value       = azurerm_storage_account.data_lake.name
}

output "data_lake_storage_account_id" {
  description = "ID of the Data Lake Storage account"
  value       = azurerm_storage_account.data_lake.id
}

output "data_lake_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the Data Lake Storage account"
  value       = azurerm_storage_account.data_lake.primary_dfs_endpoint
}

output "data_lake_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Data Lake Storage account"
  value       = azurerm_storage_account.data_lake.primary_blob_endpoint
}

output "data_lake_containers" {
  description = "List of created Data Lake containers"
  value       = [for container in azurerm_storage_container.containers : container.name]
}

# =====================================================
# Key Vault Outputs
# =====================================================
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# =====================================================
# Machine Learning Workspace Outputs
# =====================================================
output "ml_workspace_name" {
  description = "Name of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.name
}

output "ml_workspace_id" {
  description = "ID of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.id
}

output "ml_workspace_discovery_url" {
  description = "Discovery URL of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.discovery_url
}

# =====================================================
# Container Registry Outputs
# =====================================================
output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}

# =====================================================
# Monitoring Outputs
# =====================================================
output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = azurerm_application_insights.main.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# =====================================================
# Connection Strings
# =====================================================
output "connection_strings" {
  description = "Connection strings for various services"
  value = {
    synapse_sql_dedicated = "Server=tcp:${azurerm_synapse_workspace.main.name}.sql.azuresynapse.net,1433;Database=${azurerm_synapse_sql_pool.main.name};Authentication=Active Directory Integrated;"
    synapse_sql_serverless = "Server=tcp:${azurerm_synapse_workspace.main.name}-ondemand.sql.azuresynapse.net,1433;Database=master;Authentication=Active Directory Integrated;"
    data_lake_dfs = azurerm_storage_account.data_lake.primary_dfs_endpoint
    data_lake_blob = azurerm_storage_account.data_lake.primary_blob_endpoint
  }
  sensitive = false
}

# =====================================================
# Private Endpoint Outputs
# =====================================================
output "private_endpoints" {
  description = "Private endpoint information"
  value = var.enable_private_endpoints ? {
    synapse = {
      id   = azurerm_private_endpoint.synapse[0].id
      name = azurerm_private_endpoint.synapse[0].name
    }
    data_lake = {
      id   = azurerm_private_endpoint.data_lake[0].id
      name = azurerm_private_endpoint.data_lake[0].name
    }
  } : {}
}

# =====================================================
# Security Outputs
# =====================================================
output "managed_identities" {
  description = "Managed identity information"
  value = {
    synapse_workspace = {
      principal_id = azurerm_synapse_workspace.main.identity[0].principal_id
      tenant_id    = azurerm_synapse_workspace.main.identity[0].tenant_id
    }
    ml_workspace = {
      principal_id = azurerm_machine_learning_workspace.main.identity[0].principal_id
      tenant_id    = azurerm_machine_learning_workspace.main.identity[0].tenant_id
    }
  }
}

# =====================================================
# Configuration Outputs
# =====================================================
output "environment_config" {
  description = "Environment configuration summary"
  value = {
    environment = var.environment
    location    = var.location
    sql_pool_sku = local.sql_pool_config[var.environment].sku
    spark_pool_node_size = local.spark_pool_config[var.environment].node_size
    private_endpoints_enabled = var.enable_private_endpoints
    managed_vnet_enabled = var.enable_managed_vnet
  }
}

# =====================================================
# Resource URLs and Endpoints
# =====================================================
output "resource_urls" {
  description = "URLs and endpoints for accessing resources"
  value = {
    synapse_studio = "https://web.azuresynapse.net?workspace=%2Fsubscriptions%2F${data.azurerm_client_config.current.subscription_id}%2FresourceGroups%2F${data.azurerm_resource_group.main.name}%2Fproviders%2FMicrosoft.Synapse%2Fworkspaces%2F${azurerm_synapse_workspace.main.name}"
    azure_ml_studio = "https://ml.azure.com/workspaces/${azurerm_machine_learning_workspace.main.id}"
    azure_portal_synapse = "https://portal.azure.com/#@/resource${azurerm_synapse_workspace.main.id}"
    azure_portal_ml = "https://portal.azure.com/#@/resource${azurerm_machine_learning_workspace.main.id}"
    data_lake_explorer = "https://portal.azure.com/#@/resource${azurerm_storage_account.data_lake.id}/storageexplorer"
  }
}

# =====================================================
# Cost Management Outputs
# =====================================================
output "cost_information" {
  description = "Cost-related information and recommendations"
  value = {
    sql_pool_sku = azurerm_synapse_sql_pool.main.sku_name
    spark_pool_auto_pause = azurerm_synapse_spark_pool.main.auto_pause[0].delay_in_minutes
    storage_replication_type = azurerm_storage_account.data_lake.account_replication_type
    environment_tier = var.environment
    cost_optimization_notes = var.environment == "dev" ? "Development environment with cost-optimized settings" : var.environment == "prod" ? "Production environment with high availability settings" : "Test environment with balanced settings"
  }
}

# =====================================================
# Deployment Information
# =====================================================
output "deployment_info" {
  description = "Deployment information and next steps"
  value = {
    deployment_timestamp = timestamp()
    terraform_version = "~> 1.0"
    provider_version = "~> 3.0"
    next_steps = [
      "Configure Synapse pipelines and datasets",
      "Set up data sources and linked services",
      "Deploy notebooks and SQL scripts",
      "Configure monitoring and alerting",
      "Set up CI/CD pipelines",
      "Configure security and access controls"
    ]
    useful_commands = {
      connect_synapse_sql = "sqlcmd -S ${azurerm_synapse_workspace.main.name}.sql.azuresynapse.net -d ${azurerm_synapse_sql_pool.main.name} -G"
      connect_serverless_sql = "sqlcmd -S ${azurerm_synapse_workspace.main.name}-ondemand.sql.azuresynapse.net -d master -G"
      azure_cli_synapse = "az synapse workspace show --name ${azurerm_synapse_workspace.main.name} --resource-group ${data.azurerm_resource_group.main.name}"
    }
  }
}