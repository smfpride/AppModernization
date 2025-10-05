# Azure Infrastructure Implementation Documentation
# Story 3: Provision Azure Infrastructure Resources

## Overview

This document describes the complete Azure infrastructure implementation for the eShopLegacyMVC application modernization project. The infrastructure follows the architectural decisions outlined in ADR001 and ADR002, providing a solid foundation for containerized application deployment.

## Infrastructure Architecture

### Resource Overview
```
Azure Subscription
└── Resource Group: rg-eshop-prototype-eastus2
    ├── SQL Server: sql-eshop-prototype-eastus2.database.windows.net
    │   └── Database: CatalogDb (S2 Standard tier)
    ├── Key Vault: kv-eshop-prototype.vault.azure.net
    ├── App Service Plan: asp-eshop-prototype-eastus2 (S1 Standard)
    └── App Service: app-eshop-prototype-eastus2.azurewebsites.net
        └── System Managed Identity (enabled)
```

### Service Dependencies
- **App Service** → **SQL Database** (via connection string)
- **App Service** → **Key Vault** (via Managed Identity)
- **Key Vault** → **SQL Database** (stores connection string)
- **App Service** → **App Service Plan** (hosting platform)

## Deployment Methods

### Method 1: PowerShell Script (Recommended for Development)

**File**: `scripts/Deploy-AzureInfrastructure.ps1`

**Usage**:
```powershell
# Set secure password
$securePassword = ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force

# Deploy infrastructure
.\scripts\Deploy-AzureInfrastructure.ps1 -SqlAdminUsername "eshopadmin" -SqlAdminPassword $securePassword
```

**Features**:
- Interactive confirmation prompts
- Comprehensive error handling
- Progress indicators and colored output
- Automatic firewall configuration
- Managed Identity setup
- Cost budget configuration
- Connection string storage in Key Vault

### Method 2: ARM Template (Recommended for Production)

**Files**: 
- `infrastructure/azure-infrastructure.json` (ARM template)
- `infrastructure/azure-infrastructure.parameters.json` (parameters file)

**Usage**:
```powershell
# Deploy using Azure CLI
az deployment group create \
  --resource-group rg-eshop-prototype-eastus2 \
  --template-file infrastructure/azure-infrastructure.json \
  --parameters infrastructure/azure-infrastructure.parameters.json
```

**Benefits**:
- Infrastructure as Code (IaC)
- Repeatable deployments
- Version control friendly
- Azure Resource Manager validation
- Rollback capabilities

## Resource Specifications

### 1. Resource Group
- **Name**: `rg-eshop-prototype-eastus2`
- **Location**: `East US 2`
- **Tags**: 
  - Project: eShopLegacyMVC
  - Environment: Prototype
  - CostCenter: Development
  - CreatedBy: DevOpsScript
  - CreatedDate: 2025-10-03

### 2. SQL Server & Database
- **Server Name**: `sql-eshop-prototype-eastus2`
- **Database Name**: `CatalogDb`
- **Tier**: S2 Standard (50 DTUs, 250 GB max)
- **Firewall Rules**: 
  - AllowAzureServices (0.0.0.0 - 0.0.0.0)
- **Authentication**: SQL Server Authentication
- **Features**:
  - Automated backups (7-day retention)
  - Point-in-time restore
  - Built-in monitoring
  - Threat detection (optional)

### 3. Key Vault
- **Name**: `kv-eshop-prototype`
- **SKU**: Standard
- **Access Policies**:
  - App Service Managed Identity: Get, List secrets
  - Deployment principal: Full access
- **Features**:
  - Soft delete enabled (7-day retention)
  - Azure RBAC integration ready
  - Audit logging
- **Stored Secrets**:
  - `CatalogDbConnectionString`: Complete SQL connection string

### 4. App Service Plan
- **Name**: `asp-eshop-prototype-eastus2`
- **SKU**: S1 Standard (1 vCPU, 1.75 GB RAM)
- **OS**: Windows
- **Features**:
  - Auto-scale ready
  - Deployment slots support
  - SSL/TLS support
  - Custom domains support

### 5. App Service
- **Name**: `app-eshop-prototype-eastus2`
- **URL**: `https://app-eshop-prototype-eastus2.azurewebsites.net`
- **Runtime**: Windows Containers
- **Identity**: System Managed Identity (enabled)
- **Configuration**:
  - HTTPS Only: Enabled
  - Always On: Enabled
  - Container Support: Windows containers
- **Environment Variables**:
  - `ASPNET_ENVIRONMENT`: Production
  - `WEBSITES_ENABLE_APP_SERVICE_STORAGE`: false

## Security Configuration

### Network Security
- **SQL Server**: Firewall configured for Azure services only
- **Key Vault**: Public access enabled (can be restricted to VNet)
- **App Service**: HTTPS enforcement enabled
- **TLS**: Minimum version 1.2 enforced

### Identity & Access Management
- **Managed Identity**: System-assigned identity for App Service
- **Key Vault Access**: Least-privilege access (Get, List secrets only)
- **SQL Authentication**: SQL Server authentication (can upgrade to Azure AD)

### Data Protection
- **Encryption at Rest**: Enabled for all services
- **Encryption in Transit**: TLS 1.2+ for all connections
- **Secret Management**: Centralized in Key Vault
- **Backup**: Automated for SQL Database

## Cost Management

### Estimated Monthly Costs (October 2025 pricing)
- **SQL Database (S2 Standard)**: ~$75/month
- **App Service Plan (S1 Standard)**: ~$73/month
- **Key Vault (Standard)**: ~$3/month (10K operations)
- **Total Estimated**: ~$151/month

### Cost Optimization Features
- **Budget Alert**: $200 monthly limit with $150 alert threshold
- **Resource Tags**: Consistent tagging for cost tracking
- **Right-sizing**: S1/S2 tiers appropriate for prototype workload
- **Auto-shutdown**: Can be configured for non-production hours

## Monitoring & Observability

### Built-in Monitoring
- **Application Insights**: Pre-configured in application
- **Azure Monitor**: Automatic metrics collection
- **SQL Insights**: Database performance monitoring
- **Key Vault Logs**: Access and operation logging

### Health Checks
- **App Service**: Built-in health monitoring
- **SQL Database**: Connection and performance monitoring
- **Key Vault**: Access and availability monitoring

## Validation & Testing

### Automated Validation Script
**File**: `scripts/Test-AzureInfrastructure.ps1`

**Test Coverage**:
1. Resource Group existence
2. SQL Server and Database accessibility
3. Key Vault configuration
4. App Service Plan and App Service status
5. Managed Identity configuration
6. Key Vault secret storage
7. SQL firewall rules
8. App Service container configuration

**Usage**:
```powershell
.\scripts\Test-AzureInfrastructure.ps1
```

### Manual Validation Checklist
- [ ] All resources visible in Azure Portal
- [ ] SQL Database accessible via SSMS
- [ ] Key Vault secrets readable by App Service
- [ ] App Service responds with placeholder content
- [ ] Cost alerts configured and active
- [ ] All resources properly tagged

## Integration Points

### Story Dependencies
This infrastructure supports the following stories:
- **Story 1**: Container deployment target (App Service)
- **Story 2**: Database migration target (Azure SQL Database)
- **Story 4**: Configuration externalization (Key Vault)
- **Story 7**: Application deployment platform
- **Story 8**: CI/CD pipeline target

### Next Steps
1. **Database Migration**: Execute Story 2 to migrate LocalDB to Azure SQL
2. **Application Deployment**: Use Story 7 to deploy containerized application
3. **Configuration Setup**: Implement Story 4 for Key Vault integration
4. **Monitoring Setup**: Enhance Application Insights configuration

## Troubleshooting

### Common Issues
1. **Key Vault Access Denied**: Verify Managed Identity is assigned and access policy is configured
2. **SQL Connection Failures**: Check firewall rules and connection string
3. **Container Deployment Issues**: Verify App Service Plan supports Windows containers
4. **Cost Budget Alerts**: Ensure proper permissions for budget creation

### Useful Commands
```powershell
# Check resource status
az group show --name rg-eshop-prototype-eastus2

# Test SQL connectivity
az sql db show-connection-string --server sql-eshop-prototype-eastus2 --name CatalogDb

# Verify Key Vault access
az keyvault secret show --vault-name kv-eshop-prototype --name CatalogDbConnectionString

# Check App Service status
az webapp show --resource-group rg-eshop-prototype-eastus2 --name app-eshop-prototype-eastus2
```

## Compliance with Acceptance Criteria

✅ **Azure Resource Group created with consistent naming convention**
- Name: `rg-eshop-prototype-eastus2`
- Follows pattern: `rg-{project}-{environment}-{location}`

✅ **Azure SQL Server and Database provisioned (S2 Standard tier)**
- Server: `sql-eshop-prototype-eastus2`
- Database: `CatalogDb` with S2 Standard tier (50 DTUs)

✅ **Azure Key Vault created with appropriate access policies**
- Name: `kv-eshop-prototype`
- Managed Identity access configured
- Connection string stored securely

✅ **Azure App Service Plan created (S1 Standard for Windows containers)**
- Name: `asp-eshop-prototype-eastus2`
- SKU: S1 Standard with Windows container support

✅ **Azure App Service for Containers created with Managed Identity enabled**
- Name: `app-eshop-prototype-eastus2`
- System Managed Identity enabled and configured

✅ **Basic firewall rules configured for Azure SQL Database**
- AllowAzureServices rule configured (0.0.0.0 - 0.0.0.0)

✅ **All resources tagged appropriately for cost tracking**
- Consistent tagging across all resources
- Project, Environment, CostCenter, and timestamp tags

---

**Status**: ✅ **Completed**  
**Implementation Date**: October 3, 2025  
**DevOps Engineer**: GitHub Copilot Assistant  
**Next Phase**: Database Migration (Story 2) and Application Deployment (Story 7)