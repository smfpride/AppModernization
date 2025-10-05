# Quick Deployment Guide - Azure Infrastructure
## Story 3: Provision Azure Infrastructure Resources

### Prerequisites
- Azure CLI installed and authenticated (`az login`)
- PowerShell 5.1 or PowerShell Core
- Appropriate Azure subscription permissions

### Option 1: PowerShell Script Deployment (Recommended)

```powershell
# 1. Navigate to project directory
cd C:\dev\AppModernization\AppModernization

# 2. Set secure password for SQL Admin
$securePassword = ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force

# 3. Run deployment script
.\scripts\Deploy-AzureInfrastructure.ps1 -SqlAdminUsername "eshopadmin" -SqlAdminPassword $securePassword

# 4. Validate deployment
.\scripts\Test-AzureInfrastructure.ps1
```

### Option 2: Individual Azure CLI Commands

```bash
# Create Resource Group
az group create --name rg-eshop-prototype-eastus2 --location eastus2 --tags 'Project=eShopLegacyMVC' 'Environment=Prototype'

# Create SQL Server
az sql server create --name sql-eshop-prototype-eastus2 --resource-group rg-eshop-prototype-eastus2 --location eastus2 --admin-user eshopadmin --admin-password 'YourPassword123!'

# Create SQL Database
az sql db create --resource-group rg-eshop-prototype-eastus2 --server sql-eshop-prototype-eastus2 --name CatalogDb --service-objective S2

# Configure SQL Firewall
az sql server firewall-rule create --resource-group rg-eshop-prototype-eastus2 --server sql-eshop-prototype-eastus2 --name 'AllowAzureServices' --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Create Key Vault
az keyvault create --name kv-eshop-prototype --resource-group rg-eshop-prototype-eastus2 --sku standard --enable-soft-delete

# Create App Service Plan
az appservice plan create --name asp-eshop-prototype-eastus2 --resource-group rg-eshop-prototype-eastus2 --sku S1 --location eastus2 --is-linux false

# Create App Service
az webapp create --resource-group rg-eshop-prototype-eastus2 --plan asp-eshop-prototype-eastus2 --name app-eshop-prototype-eastus2 --deployment-container-image-name 'nginx:latest'

# Enable Managed Identity
az webapp identity assign --resource-group rg-eshop-prototype-eastus2 --name app-eshop-prototype-eastus2
```

### Validation Commands

```powershell
# Quick validation
az group show --name rg-eshop-prototype-eastus2 --output table
az sql server list --resource-group rg-eshop-prototype-eastus2 --output table
az keyvault list --resource-group rg-eshop-prototype-eastus2 --output table
az webapp list --resource-group rg-eshop-prototype-eastus2 --output table
```

### Expected Results
- **Resource Group**: `rg-eshop-prototype-eastus2` in East US 2
- **SQL Server**: `sql-eshop-prototype-eastus2.database.windows.net`
- **Database**: `CatalogDb` (S2 Standard, ~$75/month)
- **Key Vault**: `https://kv-eshop-prototype.vault.azure.net/`
- **App Service**: `https://app-eshop-prototype-eastus2.azurewebsites.net`
- **Total Cost**: ~$150/month for prototype environment

### Next Steps
1. Execute database migration (Story 2)
2. Deploy containerized application (Story 7)
3. Configure application settings with Key Vault integration