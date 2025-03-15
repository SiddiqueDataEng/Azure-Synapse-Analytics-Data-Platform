# Azure Synapse Analytics Data Platform - Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the Azure Synapse Analytics Data Platform (ASADP) across different environments. The platform supports both Bicep and Terraform deployment methods with full automation capabilities.

## Prerequisites

### Required Tools

- **Azure CLI** (version 2.40+)
- **PowerShell** (version 7.0+) with Az modules
- **Terraform** (version 1.0+) - if using Terraform deployment
- **Git** for source code management

### Azure Requirements

- Azure subscription with appropriate permissions
- Resource quotas for Synapse Analytics, Storage, and related services
- Azure Active Directory permissions for service principal creation

### Permissions Required

- **Subscription Contributor** or **Owner** role
- **Azure Active Directory** permissions for RBAC configuration
- **Key Vault** access for secrets management

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/Azure-Synapse-Analytics-Data-Platform.git
cd Azure-Synapse-Analytics-Data-Platform
```

### 2. Configure Environment

Edit the environment configuration file for your target environment:

```bash
# For development environment
code config/environments/dev.json

# For production environment
code config/environments/prod.json
```

### 3. Deploy Infrastructure

#### Option A: PowerShell Deployment (Recommended)

```powershell
# Development environment
.\scripts\Deploy-Synapse-Data-Platform.ps1 `
    -Environment "dev" `
    -Region "East US" `
    -NotificationEmails @("admin@company.com") `
    -DeploymentMethod "Bicep"

# Production environment
.\scripts\Deploy-Synapse-Data-Platform.ps1 `
    -Environment "prod" `
    -Region "East US" `
    -NotificationEmails @("ops@company.com", "alerts@company.com") `
    -DeploymentMethod "Bicep" `
    -EnablePrivateEndpoints `
    -EnableManagedVNet
```

#### Option B: Direct Bicep Deployment

```bash
# Create resource group
az group create --name "rg-asadp-dev" --location "East US"

# Deploy infrastructure
az deployment group create \
  --resource-group "rg-asadp-dev" \
  --template-file infrastructure/bicep/main.bicep \
  --parameters environment=dev \
               location="East US" \
               adminEmail="admin@company.com" \
               sqlAdminPassword="YourSecurePassword123!"
```

#### Option C: Terraform Deployment

```bash
# Navigate to Terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Create variables file
cat > terraform.tfvars << EOF
environment = "dev"
location = "East US"
resource_group_name = "rg-asadp-dev"
admin_email = "admin@company.com"
sql_admin_password = "YourSecurePassword123!"
EOF

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

## Environment Configurations

### Development Environment

- **Purpose**: Development and testing
- **SQL Pool**: DW100c (auto-pause enabled)
- **Spark Pool**: Small nodes, 3-10 nodes
- **Storage**: Standard LRS
- **Private Endpoints**: Disabled
- **Cost Optimization**: Enabled

### Production Environment

- **Purpose**: Production workloads
- **SQL Pool**: DW500c+ (always on)
- **Spark Pool**: Large nodes, 5-50 nodes
- **Storage**: Standard ZRS
- **Private Endpoints**: Enabled
- **High Availability**: Enabled

## Deployment Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| Environment | Target environment | dev, test, prod |
| Region | Azure region | East US, West Europe |
| NotificationEmails | Admin email addresses | ["admin@company.com"] |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| ResourceGroupName | Resource group name | rg-asadp-{environment} |
| DeploymentMethod | Deployment method | Bicep |
| EnablePrivateEndpoints | Enable private endpoints | false |
| EnableManagedVNet | Enable managed VNet | true |

## Post-Deployment Steps

### 1. Verify Deployment

```powershell
# Check resource group
az group show --name "rg-asadp-dev"

# List deployed resources
az resource list --resource-group "rg-asadp-dev" --output table

# Check Synapse workspace
az synapse workspace show --name "synapse-asadp-dev" --resource-group "rg-asadp-dev"
```

### 2. Configure Access

```powershell
# Add users to Synapse workspace
az synapse role assignment create \
  --workspace-name "synapse-asadp-dev" \
  --role "Synapse Administrator" \
  --assignee "user@company.com"

# Configure SQL pool access
az synapse sql ad-admin create \
  --workspace-name "synapse-asadp-dev" \
  --display-name "SQL Admins" \
  --object-id "group-object-id"
```

### 3. Deploy Synapse Artifacts

The deployment script automatically deploys:
- SQL schemas and tables
- Spark notebooks
- Data pipelines
- Datasets and linked services

### 4. Configure Monitoring

```powershell
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --name "synapse-diagnostics" \
  --resource "/subscriptions/{subscription-id}/resourceGroups/rg-asadp-dev/providers/Microsoft.Synapse/workspaces/synapse-asadp-dev" \
  --workspace "/subscriptions/{subscription-id}/resourceGroups/rg-asadp-dev/providers/Microsoft.OperationalInsights/workspaces/log-asadp-dev" \
  --logs '[{"category":"SynapseRbacOperations","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

## Security Configuration

### 1. Network Security

For production environments, configure private endpoints:

```bash
# Create private endpoint for Synapse
az network private-endpoint create \
  --name "pe-synapse-asadp-prod" \
  --resource-group "rg-asadp-prod" \
  --vnet-name "vnet-asadp-prod" \
  --subnet "synapse-subnet" \
  --private-connection-resource-id "/subscriptions/{subscription-id}/resourceGroups/rg-asadp-prod/providers/Microsoft.Synapse/workspaces/synapse-asadp-prod" \
  --connection-name "synapse-connection" \
  --group-ids "Sql"
```

### 2. Data Protection

```powershell
# Enable transparent data encryption
az synapse sql pool tde set \
  --workspace-name "synapse-asadp-prod" \
  --name "DataWarehouse" \
  --status Enabled

# Configure data masking
az synapse sql pool data-masking-policy update \
  --workspace-name "synapse-asadp-prod" \
  --name "DataWarehouse" \
  --state Enabled
```

### 3. Access Control

```powershell
# Configure row-level security
# This is done through SQL scripts in the synapse/sql-pools/security/ folder

# Set up column-level security
# This is configured through SQL scripts and data classification
```

## Monitoring and Alerting

### 1. Key Metrics to Monitor

- **Performance**: Query execution time, resource utilization
- **Availability**: Service health, pipeline success rates
- **Cost**: Daily/monthly spending, resource usage
- **Security**: Failed login attempts, unusual access patterns

### 2. Alert Configuration

The deployment automatically configures alerts for:
- High CPU usage (>80%)
- Failed pipeline runs
- High query duration (>5 minutes)
- Storage usage (>80%)

### 3. Dashboards

Access pre-built dashboards:
- **Synapse Studio**: https://web.azuresynapse.net
- **Azure Portal**: Resource-specific dashboards
- **Azure Monitor**: Custom workbooks

## Troubleshooting

### Common Issues

#### 1. Deployment Failures

```powershell
# Check deployment status
az deployment group show \
  --resource-group "rg-asadp-dev" \
  --name "asadp-deployment-{timestamp}"

# View deployment logs
az deployment group list \
  --resource-group "rg-asadp-dev" \
  --query "[?properties.provisioningState=='Failed']"
```

#### 2. Access Issues

```powershell
# Check current user permissions
az synapse role assignment list \
  --workspace-name "synapse-asadp-dev" \
  --assignee "$(az account show --query user.name -o tsv)"

# Verify firewall rules
az synapse workspace firewall-rule list \
  --workspace-name "synapse-asadp-dev" \
  --resource-group "rg-asadp-dev"
```

#### 3. Performance Issues

```sql
-- Check SQL pool performance
SELECT 
    request_id,
    session_id,
    status,
    command,
    total_elapsed_time,
    resource_class
FROM sys.dm_pdw_exec_requests
WHERE status IN ('Running', 'Suspended')
ORDER BY total_elapsed_time DESC;
```

### Support Resources

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/synapse-analytics/
- **Community Support**: https://docs.microsoft.com/en-us/answers/topics/azure-synapse-analytics.html
- **GitHub Issues**: Create issues in this repository
- **Microsoft Support**: For production issues

## Best Practices

### 1. Resource Management

- Use auto-pause for development environments
- Implement proper resource tagging
- Monitor costs regularly
- Use appropriate SKUs for each environment

### 2. Security

- Enable private endpoints for production
- Use Azure AD authentication
- Implement row-level and column-level security
- Regular security assessments

### 3. Performance

- Optimize data distribution strategies
- Use appropriate file formats (Parquet, Delta)
- Implement proper partitioning
- Monitor and tune query performance

### 4. Data Governance

- Implement data classification
- Set up data lineage tracking
- Use proper naming conventions
- Document data sources and transformations

## Maintenance

### Regular Tasks

- **Daily**: Monitor pipeline runs and performance
- **Weekly**: Review costs and resource utilization
- **Monthly**: Update security patches and review access
- **Quarterly**: Performance tuning and capacity planning

### Backup and Recovery

- SQL pools: Automatic backups enabled
- Data Lake: Geo-redundant storage for production
- Configuration: Version control in Git
- Disaster recovery: Cross-region replication

## Next Steps

After successful deployment:

1. **Data Integration**: Set up data sources and ingestion pipelines
2. **Analytics**: Create reports and dashboards
3. **Machine Learning**: Develop and deploy ML models
4. **Governance**: Implement data governance policies
5. **Training**: Train users on Synapse Studio and analytics tools

For detailed information on each component, refer to the specific documentation in the `docs/` folder.