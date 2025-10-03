# Azure Infrastructure Deployment Script for eShopLegacyMVC
# Story 3: Provision Azure Infrastructure Resources
# 
# This script creates all required Azure resources for the eShopLegacyMVC application
# following the architecture decisions from ADR002

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$SqlServerName = "sql-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "CatalogDb",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName = "kv-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanName = "asp-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminUsername,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$SqlAdminPassword
)

Write-Host "🚀 Starting Azure Infrastructure Deployment for eShopLegacyMVC" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Function to check if Azure CLI is logged in
function Test-AzureLogin {
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Host "✓ Authenticated as: $($account.user.name)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Not authenticated to Azure. Please run 'az login'" -ForegroundColor Red
        return $false
    }
    return $false
}

# Function to create resource with error handling
function Invoke-AzCommand {
    param(
        [string]$Command,
        [string]$Description,
        [bool]$ContinueOnError = $false
    )
    
    Write-Host "📋 $Description..." -ForegroundColor Yellow
    Write-Host "   Command: $Command" -ForegroundColor Gray
    
    try {
        $result = Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $Description completed successfully" -ForegroundColor Green
            return $result
        } else {
            Write-Host "❌ $Description failed" -ForegroundColor Red
            if (-not $ContinueOnError) {
                throw "Command failed with exit code $LASTEXITCODE"
            }
        }
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        if (-not $ContinueOnError) {
            throw
        }
    }
}

# Check Azure authentication
if (-not (Test-AzureLogin)) {
    Write-Host "Please authenticate to Azure first by running 'az login'" -ForegroundColor Red
    exit 1
}

# Convert SecureString password to plain text for Azure CLI
$SqlAdminPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlAdminPassword))

Write-Host "`n📋 Infrastructure Deployment Plan:" -ForegroundColor Cyan
Write-Host "  • Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  • Location: $Location" -ForegroundColor White
Write-Host "  • SQL Server: $SqlServerName" -ForegroundColor White
Write-Host "  • Database: $DatabaseName" -ForegroundColor White
Write-Host "  • Key Vault: $KeyVaultName" -ForegroundColor White
Write-Host "  • App Service Plan: $AppServicePlanName" -ForegroundColor White
Write-Host "  • App Service: $AppServiceName" -ForegroundColor White

Write-Host "`nPress Enter to continue or Ctrl+C to cancel..."
Read-Host

try {
    # 1. Create Resource Group
    $rgCommand = "az group create --name $ResourceGroupName --location $Location --tags 'Project=eShopLegacyMVC' 'Environment=Prototype' 'CostCenter=Development' 'CreatedBy=DevOpsScript' 'CreatedDate=$(Get-Date -Format 'yyyy-MM-dd')'"
    Invoke-AzCommand -Command $rgCommand -Description "Creating Resource Group"

    # 2. Create SQL Server
    $sqlServerCommand = "az sql server create --name $SqlServerName --resource-group $ResourceGroupName --location $Location --admin-user $SqlAdminUsername --admin-password '$SqlAdminPasswordText'"
    Invoke-AzCommand -Command $sqlServerCommand -Description "Creating SQL Server"

    # 3. Create SQL Database
    $sqlDbCommand = "az sql db create --resource-group $ResourceGroupName --server $SqlServerName --name $DatabaseName --service-objective S2"
    Invoke-AzCommand -Command $sqlDbCommand -Description "Creating SQL Database (S2 Standard tier)"

    # 4. Configure SQL Server firewall to allow Azure services
    $firewallAzureCommand = "az sql server firewall-rule create --resource-group $ResourceGroupName --server $SqlServerName --name 'AllowAzureServices' --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0"
    Invoke-AzCommand -Command $firewallAzureCommand -Description "Configuring SQL Server firewall for Azure services"

    # 5. Create Key Vault (soft delete is enabled by default in newer Azure CLI versions)
    $kvCommand = "az keyvault create --name $KeyVaultName --resource-group $ResourceGroupName --location $Location --sku standard"
    Invoke-AzCommand -Command $kvCommand -Description "Creating Key Vault"

    # 6. Create App Service Plan
    $aspCommand = "az appservice plan create --name $AppServicePlanName --resource-group $ResourceGroupName --sku S1 --location $Location"
    Invoke-AzCommand -Command $aspCommand -Description "Creating App Service Plan (S1 Standard for Windows web applications)"

    # 7. Create App Service (ready for .NET applications)
    $appCommand = "az webapp create --resource-group $ResourceGroupName --plan $AppServicePlanName --name $AppServiceName --runtime 'DOTNET|8.0'"
    Invoke-AzCommand -Command $appCommand -Description "Creating App Service for .NET applications"

    # 8. Enable Managed Identity
    $identityCommand = "az webapp identity assign --resource-group $ResourceGroupName --name $AppServiceName"
    $identityResult = Invoke-AzCommand -Command $identityCommand -Description "Enabling Managed Identity for App Service"

    # 9. Get the Managed Identity principal ID
    $identityInfo = az webapp identity show --resource-group $ResourceGroupName --name $AppServiceName --output json | ConvertFrom-Json
    $principalId = $identityInfo.principalId

    # 10. Grant Key Vault access to Managed Identity
    if ($principalId) {
        $kvAccessCommand = "az keyvault set-policy --name $KeyVaultName --object-id $principalId --secret-permissions get list"
        Invoke-AzCommand -Command $kvAccessCommand -Description "Granting Key Vault access to App Service Managed Identity"
    }

    # 11. Store database connection string in Key Vault
    $sqlServer = az sql server show --resource-group $ResourceGroupName --name $SqlServerName --output json | ConvertFrom-Json
    $connectionString = "Server=tcp:$($sqlServer.fullyQualifiedDomainName),1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$SqlAdminUsername;Password=$SqlAdminPasswordText;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    $secretCommand = "az keyvault secret set --vault-name $KeyVaultName --name 'CatalogDbConnectionString' --value '$connectionString'"
    Invoke-AzCommand -Command $secretCommand -Description "Storing database connection string in Key Vault"

    # 12. Configure cost alerts (basic budget)
    $budgetCommand = "az consumption budget create --resource-group $ResourceGroupName --budget-name 'eshop-monthly-budget' --amount 200 --category cost --time-grain monthly --time-period start-date=$(Get-Date -Format 'yyyy-MM-01') --notifications amount=150 contact-emails='admin@company.com'"
    Invoke-AzCommand -Command $budgetCommand -Description "Setting up cost budget and alerts" -ContinueOnError $true

    Write-Host "`n🎉 Infrastructure deployment completed successfully!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    
    # Output resource information
    Write-Host "`n📋 Created Resources:" -ForegroundColor Cyan
    Write-Host "  • Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "  • SQL Server: $($SqlServerName).database.windows.net" -ForegroundColor White
    Write-Host "  • SQL Database: $DatabaseName (S2 Standard)" -ForegroundColor White
    Write-Host "  • Key Vault: https://$KeyVaultName.vault.azure.net/" -ForegroundColor White
    Write-Host "  • App Service Plan: $AppServicePlanName (S1 Standard)" -ForegroundColor White
    Write-Host "  • App Service: https://$AppServiceName.azurewebsites.net" -ForegroundColor White
    Write-Host "  • Managed Identity Principal ID: $principalId" -ForegroundColor White

    Write-Host "`n🔐 Security Configuration:" -ForegroundColor Cyan
    Write-Host "  • SQL Server firewall configured for Azure services" -ForegroundColor White
    Write-Host "  • Key Vault access granted to App Service Managed Identity" -ForegroundColor White
    Write-Host "  • Database connection string stored securely in Key Vault" -ForegroundColor White

    Write-Host "`n💰 Cost Management:" -ForegroundColor Cyan
    Write-Host "  • Monthly budget set to \$200 with alerts at \$150" -ForegroundColor White
    Write-Host "  • All resources tagged for cost tracking" -ForegroundColor White

} catch {
    Write-Host "`n❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check the error details and retry." -ForegroundColor Red
    exit 1
} finally {
    # Clean up sensitive data
    if ($SqlAdminPasswordText) {
        $SqlAdminPasswordText = $null
    }
}

Write-Host "`n✅ Ready for application deployment (Story 7)!" -ForegroundColor Green