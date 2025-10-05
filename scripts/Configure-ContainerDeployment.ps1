# Configure App Service for Windows Container
# This script configures the eShop App Service to use Windows containers

$resourceGroup = "rg-eshop-prototype-eastus2"
$appServiceName = "app-eshop-prototype-eastus2"
$containerImage = "acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
$registryUrl = "https://acreshopprototype.azurecr.io"

Write-Host "Configuring App Service for Windows containers..." -ForegroundColor Yellow

# Set the Windows container image
$windowsFxVersion = "DOCKER|$containerImage"
Write-Host "Setting windowsFxVersion to: $windowsFxVersion" -ForegroundColor Green

# Use az resource update to set the Windows container configuration
$command = "az resource update --resource-group $resourceGroup --name $appServiceName --resource-type `"Microsoft.Web/sites`" --set `"properties.siteConfig.windowsFxVersion=$windowsFxVersion`""
Write-Host "Executing: $command" -ForegroundColor Cyan
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Successfully configured Windows container image" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to configure Windows container image" -ForegroundColor Red
    exit 1
}

# Configure additional container settings
Write-Host "Configuring container settings..." -ForegroundColor Yellow

az webapp config appsettings set `
    --resource-group $resourceGroup `
    --name $appServiceName `
    --settings `
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=false `
    DOCKER_REGISTRY_SERVER_URL=$registryUrl

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Successfully configured container settings" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to configure container settings" -ForegroundColor Red
}

Write-Host "Container configuration completed!" -ForegroundColor Green