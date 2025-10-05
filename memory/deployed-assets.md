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

### Security Configuration
| Security Feature | Status | Details |
|-------------------|---------|---------|
| **SQL Firewall** | ✅ Configured | AllowAzureServices rule active |
| **Managed Identity** | ✅ Enabled | Principal ID: `fbd53bd9-caac-4260-a995-6251c06f1dd9` |
| **Key Vault RBAC** | ✅ Configured | App Service has "Key Vault Secrets User" role |
| **Connection String** | ✅ Stored | Securely stored in Key Vault |
| **HTTPS Enforcement** | ✅ Available | App Service ready for HTTPS configuration |

## 🌐 Access URLs & Endpoints

- **App Service URL**: https://app-eshop-prototype-eastus2.azurewebsites.net
- **SQL Server FQDN**: sql-eshop-prototype-eastus2.database.windows.net
- **Key Vault URI**: https://kv-eshop-prototype.vault.azure.net/
- **Resource Group**: /subscriptions/15ed6030-cc0e-4b95-9b8d-8d60f6b02b82/resourceGroups/rg-eshop-prototype-eastus2