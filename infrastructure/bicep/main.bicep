// =====================================================
// Azure Synapse Analytics Data Platform (ASADP)
// Main Bicep Template - Production-Ready Infrastructure
// =====================================================

@description('Environment name (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Unique suffix for resource names')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 6)

@description('Administrator email for notifications')
param adminEmail string

@description('Enable private endpoints for production')
param enablePrivateEndpoints bool = false

@description('Enable managed virtual network')
param enableManagedVNet bool = true

@description('SQL Administrator username')
param sqlAdminUsername string = 'sqladmin'

@description('SQL Administrator password')
@secure()
param sqlAdminPassword string

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  Project: 'ASADP'
  Owner: 'DataEngineering'
  CostCenter: 'IT-DataPlatform'
}

// =====================================================
// Variables
// =====================================================
var resourcePrefix = 'asadp-${environment}-${uniqueSuffix}'
var synapseWorkspaceName = 'synapse-${resourcePrefix}'
var dataLakeAccountName = 'dl${replace(resourcePrefix, '-', '')}'
var keyVaultName = 'kv-${resourcePrefix}'
var logAnalyticsWorkspace = 'log-${resourcePrefix}'
var appInsightsName = 'ai-${resourcePrefix}'
var mlWorkspaceName = 'ml-${resourcePrefix}'
var containerRegistryName = 'cr${replace(resourcePrefix, '-', '')}'

// SQL Pool configurations based on environment
var sqlPoolConfigs = {
  dev: {
    name: 'DataWarehouse'
    sku: 'DW100c'
    createMode: 'Default'
  }
  test: {
    name: 'DataWarehouse'
    sku: 'DW200c'
    createMode: 'Default'
  }
  prod: {
    name: 'DataWarehouse'
    sku: 'DW500c'
    createMode: 'Default'
  }
}

// Spark Pool configurations based on environment
var sparkPoolConfigs = {
  dev: {
    name: 'SparkPool'
    nodeSize: 'Small'
    minNodeCount: 3
    maxNodeCount: 10
    autoScale: true
    autoPause: true
    delayInMinutes: 15
  }
  test: {
    name: 'SparkPool'
    nodeSize: 'Medium'
    minNodeCount: 3
    maxNodeCount: 20
    autoScale: true
    autoPause: true
    delayInMinutes: 15
  }
  prod: {
    name: 'SparkPool'
    nodeSize: 'Large'
    minNodeCount: 5
    maxNodeCount: 50
    autoScale: true
    autoPause: false
    delayInMinutes: 30
  }
}

// =====================================================
// Key Vault
// =====================================================
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: environment == 'prod'
    networkAcls: {
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store SQL admin password in Key Vault
resource sqlAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-admin-password'
  properties: {
    value: sqlAdminPassword
  }
}

// =====================================================
// Data Lake Storage Gen2
// =====================================================
resource dataLakeStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: dataLakeAccountName
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true // Hierarchical namespace for Data Lake Gen2
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Data Lake containers
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: dataLakeStorage
  name: 'default'
}

resource dataLakeContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in [
  'raw'
  'processed'
  'curated'
  'sandbox'
  'synapse'
  'models'
  'logs'
]: {
  parent: blobServices
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}]

// =====================================================
// Log Analytics Workspace
// =====================================================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspace
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: environment == 'prod' ? 50 : 10
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// =====================================================
// Application Insights
// =====================================================
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// =====================================================
// Container Registry
// =====================================================
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Premium' : 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: environment == 'prod' ? 'Enabled' : 'Disabled'
  }
}

// =====================================================
// Machine Learning Workspace
// =====================================================
resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2023-10-01' = {
  name: mlWorkspaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'Synapse ML Workspace'
    storageAccount: dataLakeStorage.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    containerRegistry: containerRegistry.id
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    hbiWorkspace: environment == 'prod'
    managedNetwork: {
      isolationMode: enableManagedVNet ? 'AllowInternetOutbound' : 'Disabled'
    }
  }
}

// =====================================================
// Synapse Analytics Workspace
// =====================================================
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: dataLakeStorage.properties.primaryEndpoints.dfs
      filesystem: 'synapse'
    }
    sqlAdministratorLogin: sqlAdminUsername
    sqlAdministratorLoginPassword: sqlAdminPassword
    managedVirtualNetwork: enableManagedVNet ? 'default' : ''
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    managedResourceGroupName: 'rg-${synapseWorkspaceName}-managed'
    connectivityEndpoints: {}
    workspaceRepositoryConfiguration: {
      type: 'GitHub'
      hostName: 'github.com'
      accountName: 'your-github-account'
      projectName: 'Azure-Synapse-Analytics-Data-Platform'
      repositoryName: 'Azure-Synapse-Analytics-Data-Platform'
      collaborationBranch: 'main'
      rootFolder: '/synapse'
    }
  }
}

// =====================================================
// Synapse Firewall Rules
// =====================================================
resource synapseFirewallAllowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseWorkspace
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource synapseFirewallAllowClient 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = if (!enablePrivateEndpoints) {
  parent: synapseWorkspace
  name: 'AllowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// =====================================================
// Synapse SQL Pool (Dedicated)
// =====================================================
resource synapseSqlPool 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  parent: synapseWorkspace
  name: sqlPoolConfigs[environment].name
  location: location
  tags: tags
  sku: {
    name: sqlPoolConfigs[environment].sku
  }
  properties: {
    createMode: sqlPoolConfigs[environment].createMode
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// =====================================================
// Synapse Spark Pool
// =====================================================
resource synapseSparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: sparkPoolConfigs[environment].name
  location: location
  tags: tags
  properties: {
    nodeCount: sparkPoolConfigs[environment].minNodeCount
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: sparkPoolConfigs[environment].nodeSize
    autoScale: {
      enabled: sparkPoolConfigs[environment].autoScale
      minNodeCount: sparkPoolConfigs[environment].minNodeCount
      maxNodeCount: sparkPoolConfigs[environment].maxNodeCount
    }
    autoPause: {
      enabled: sparkPoolConfigs[environment].autoPause
      delayInMinutes: sparkPoolConfigs[environment].delayInMinutes
    }
    sparkVersion: '3.4'
    libraryRequirements: {
      content: loadTextContent('../../synapse/spark-pools/configurations/requirements.txt')
      filename: 'requirements.txt'
    }
    sessionLevelPackagesEnabled: true
    cacheSize: environment == 'prod' ? 100 : 50
  }
}

// =====================================================
// Role Assignments
// =====================================================

// Synapse workspace managed identity access to Data Lake
resource synapseDataLakeRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataLakeStorage.id, synapseWorkspace.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: dataLakeStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: synapseWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ML workspace access to Data Lake
resource mlDataLakeRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataLakeStorage.id, mlWorkspace.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: dataLakeStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: mlWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// =====================================================
// Private Endpoints (if enabled)
// =====================================================
resource synapsePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints) {
  name: 'pe-${synapseWorkspaceName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/vnet-${resourcePrefix}/subnets/synapse-subnet'
    }
    privateLinkServiceConnections: [
      {
        name: 'synapse-connection'
        properties: {
          privateLinkServiceId: synapseWorkspace.id
          groupIds: ['Sql']
        }
      }
    ]
  }
}

resource dataLakePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints) {
  name: 'pe-${dataLakeAccountName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/vnet-${resourcePrefix}/subnets/data-subnet'
    }
    privateLinkServiceConnections: [
      {
        name: 'datalake-connection'
        properties: {
          privateLinkServiceId: dataLakeStorage.id
          groupIds: ['dfs']
        }
      }
    ]
  }
}

// =====================================================
// Outputs
// =====================================================
output resourceGroupName string = resourceGroup().name
output synapseWorkspaceName string = synapseWorkspace.name
output synapseWorkspaceId string = synapseWorkspace.id
output dataLakeStorageAccountName string = dataLakeStorage.name
output dataLakeStorageAccountId string = dataLakeStorage.id
output sqlPoolName string = synapseSqlPool.name
output sparkPoolName string = synapseSparkPool.name
output keyVaultName string = keyVault.name
output mlWorkspaceName string = mlWorkspace.name
output containerRegistryName string = containerRegistry.name
output logAnalyticsWorkspaceName string = logAnalytics.name
output appInsightsName string = appInsights.name

output synapseEndpoints object = {
  web: 'https://web.azuresynapse.net?workspace=%2Fsubscriptions%2F${subscription().subscriptionId}%2FresourceGroups%2F${resourceGroup().name}%2Fproviders%2FMicrosoft.Synapse%2Fworkspaces%2F${synapseWorkspace.name}'
  dev: synapseWorkspace.properties.connectivityEndpoints.dev
  sql: synapseWorkspace.properties.connectivityEndpoints.sql
  sqlOnDemand: synapseWorkspace.properties.connectivityEndpoints.sqlOnDemand
}

output connectionStrings object = {
  dataLake: dataLakeStorage.properties.primaryEndpoints.dfs
  synapseSql: 'Server=tcp:${synapseWorkspace.name}.sql.azuresynapse.net,1433;Database=${synapseSqlPool.name};'
  synapseServerless: 'Server=tcp:${synapseWorkspace.name}-ondemand.sql.azuresynapse.net,1433;Database=master;'
}