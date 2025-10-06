## Deployed Assets

### Core Infrastructure
| Resource Type | Resource Name | Status | Details |
|---------------|---------------|---------|---------|
| **Resource Group** | `rg-eshop-prototype-eastus2` | ✅ Created | East US 2, properly tagged |
| **SQL Server** | `sql-eshop-prototype-eastus2` | ✅ Created | v12.0, TLS 1.2 min, Azure firewall enabled |
| **SQL Database** | `CatalogDb` | ✅ Created | S2 Standard (50 DTUs, 250GB) |
| **Key Vault** | `kv-eshop-prototype` | ✅ Created | Standard tier, RBAC enabled, soft delete |
| **App Service Plan** | `asp-eshop-prototype-eastus2` | ✅ Created | S1 Standard, Windows platform |
| **App Service** | `app-eshop-prototype-eastus2` | ✅ Created | Managed Identity enabled |

### Container Infrastructure (.NET 8 Linux)
| Resource Type | Resource Name | Status | Details |
|---------------|---------------|---------|---------|
| **Container Registry** | `acreshopprototype.azurecr.io` | ✅ Created | Basic tier, admin enabled, managed identity access |
| **Linux App Service Plan** | `asp-eshop-linux-eastus2` | ✅ Created | S1 Standard, Linux platform |
| **Linux App Service** | `app-eshop-linux-eastus2` | ✅ Created | .NET 8 container, managed identity enabled |
| **Container Images** | `eshop-dotnet8:latest`, `eshop-dotnet8:v2` | ✅ Deployed | Multi-stage Linux builds, ~200MB |

### Security Configuration
| Security Feature | Status | Details |
|-------------------|---------|---------|
| **SQL Firewall** | ✅ Configured | AllowAzureServices rule active |
| **Managed Identity** | ✅ Enabled | Principal ID: `fbd53bd9-caac-4260-a995-6251c06f1dd9` |
| **Key Vault RBAC** | ✅ Configured | App Service has "Key Vault Secrets User" role |
| **Connection String** | ✅ Stored | Securely stored in Key Vault |
| **HTTPS Enforcement** | ✅ Available | App Service ready for HTTPS configuration |

## 🌐 Access URLs & Endpoints

### Legacy Windows Deployment
- **App Service URL**: https://app-eshop-prototype-eastus2.azurewebsites.net
- **SQL Server FQDN**: sql-eshop-prototype-eastus2.database.windows.net
- **Key Vault URI**: https://kv-eshop-prototype.vault.azure.net/

### Modern Linux Container Deployment (.NET 8)
- **Linux App Service URL**: https://app-eshop-linux-eastus2.azurewebsites.net
- **Container Registry**: acreshopprototype.azurecr.io
- **Health Check Endpoint**: https://app-eshop-linux-eastus2.azurewebsites.net/health
- **Resource Group**: /subscriptions/15ed6030-cc0e-4b95-9b8d-8d60f6b02b82/resourceGroups/rg-eshop-prototype-eastus2

### 🏗️ Container Details
- **Production Image**: `acreshopprototype.azurecr.io/eshop-dotnet8:modernized` ✅ **ACTIVE**
- **Image Digest**: `sha256:c560dfad75262410afe4072c5fbfee82dcfb48f6e6577b3490df4b6cb0dba468`
- **Previous Images**: `no-container-create`, `blob-only`, `debug-auth`, `v2`, `latest`
- **Platform**: Linux containers on .NET 8
- **Size**: ~200MB (90% reduction from Windows containers)
- **Architecture**: Multi-stage Docker build with optimized layers
- **Status**: ✅ Production-ready with complete blob storage integration

### 🗄️ Blob Storage Integration
| Resource Type | Resource Name | Status | Details |
|---------------|---------------|---------|---------|
| **Storage Account** | `steshopprototype` | ✅ Created | Standard LRS, public blob access enabled |
| **Blob Container** | `productimages` | ✅ Created | Public blob access, 13 product images uploaded |
| **Authentication** | Connection String | ✅ Configured | Stored in Key Vault as `StorageAccount-ConnectionString` |
| **Image Serving** | Blob URLs | ✅ Active | Direct redirects to Azure Blob Storage |

### 📂 Product Images
- **Total Images**: 13 product images (1.png - 13.png)
- **Storage Location**: https://steshopprototype.blob.core.windows.net/productimages/
- **Access Method**: App redirects `/items/{id}/pic` → blob storage URLs
- **Authentication**: Connection string via Key Vault
- **Status**: ✅ All images accessible and serving correctly