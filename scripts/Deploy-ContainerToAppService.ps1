# Deploy-ContainerToAppService.ps1
# CRITICAL DEPLOYMENT FIX: Configure App Service for Windows Container deployment
# 
# Purpose: Fix Story 8 critical deployment issue where App Service shows default Azure page
# Root Cause: App Service configured as regular Windows app instead of Windows container
# Solution: Configure container deployment from ACR image
#
# Author: Alex (DevOps Engineer)
# Date: October 5, 2025
# Context: URGENT fix for Story 8 QA testing blocker

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerImage = "acreshopprototype.azurecr.io/eshoplegacymvc:v1.0",
    
    [Parameter(Mandatory=$false)]
    [string]$RegistryServer = "acreshopprototype.azurecr.io",
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput
)

# Error handling
$ErrorActionPreference = "Stop"

Write-Host "🚨 CRITICAL DEPLOYMENT FIX: Container Configuration for App Service" -ForegroundColor Red
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "App Service: $AppServiceName"
Write-Host "Container Image: $ContainerImage"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host ""

# Validate prerequisites
Write-Host "📋 Validating prerequisites..." -ForegroundColor Cyan

try {
    # Check Azure CLI login
    $account = az account show --query "name" -o tsv 2>$null
    if (-not $account) {
        throw "Not logged into Azure CLI. Run 'az login' first."
    }
    Write-Host "✅ Azure CLI authenticated: $account" -ForegroundColor Green
    
    # Verify Resource Group exists
    $rgExists = az group exists --name $ResourceGroupName
    if ($rgExists -eq "false") {
        throw "Resource Group '$ResourceGroupName' does not exist"
    }
    Write-Host "✅ Resource Group exists: $ResourceGroupName" -ForegroundColor Green
    
    # Verify App Service exists
    $appService = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
    if (-not $appService) {
        throw "App Service '$AppServiceName' not found in resource group '$ResourceGroupName'"
    }
    Write-Host "✅ App Service exists: $AppServiceName" -ForegroundColor Green
    
    # Check container image exists in ACR
    Write-Host "🔍 Verifying container image in ACR..." -ForegroundColor Cyan
    $registryName = $RegistryServer.Split('.')[0]  # Extract registry name from FQDN
    
    $imageExists = az acr repository show --name $registryName --image "eshoplegacymvc:v1.0" --query "name" -o tsv 2>$null
    if (-not $imageExists) {
        throw "Container image 'eshoplegacymvc:v1.0' not found in ACR '$registryName'"
    }
    Write-Host "✅ Container image verified: $ContainerImage" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Prerequisite validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($ValidateOnly) {
    Write-Host "✅ Validation completed successfully. All prerequisites met." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "🔧 CRITICAL FIX: Configuring container deployment..." -ForegroundColor Yellow

try {
    # Step 1: Configure App Service for Windows containers
    Write-Host "1️⃣ Configuring App Service for Windows container deployment..." -ForegroundColor Cyan
    
    # Set the container image - this is the critical missing configuration
    az webapp config container set `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --docker-custom-image-name $ContainerImage `
        --docker-registry-server-url "https://$RegistryServer"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to configure container image"
    }
    Write-Host "✅ Container image configured: $ContainerImage" -ForegroundColor Green
    
    # Step 2: Enable container logging for troubleshooting
    Write-Host "2️⃣ Enabling container logging..." -ForegroundColor Cyan
    
    az webapp log config `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --docker-container-logging filesystem
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "⚠️ Container logging configuration failed (non-critical)"
    } else {
        Write-Host "✅ Container logging enabled" -ForegroundColor Green
    }
    
    # Step 3: Configure App Service settings for container
    Write-Host "3️⃣ Configuring container runtime settings..." -ForegroundColor Cyan
    
    # Ensure HTTPS only (security best practice)
    az webapp update `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --https-only true
    
    # Step 4: Restart App Service to apply container configuration
    Write-Host "4️⃣ Restarting App Service to apply container configuration..." -ForegroundColor Cyan
    
    az webapp restart `
        --name $AppServiceName `
        --resource-group $ResourceGroupName
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to restart App Service"
    }
    Write-Host "✅ App Service restarted" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 CRITICAL FIX APPLIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "App Service URL: https://$AppServiceName.azurewebsites.net"
    Write-Host "Container Image: $ContainerImage"
    Write-Host ""
    Write-Host "⏱️ Application startup may take 2-3 minutes for first container deployment" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "❌ CRITICAL ERROR: Failed to configure container deployment" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "🔍 Troubleshooting information:" -ForegroundColor Yellow
    Write-Host "- Check App Service logs: az webapp log tail --name $AppServiceName --resource-group $ResourceGroupName"
    Write-Host "- Verify ACR access: az acr login --name $registryName"
    Write-Host "- Check container status: az webapp show --name $AppServiceName --resource-group $ResourceGroupName"
    
    exit 1
}

Write-Host "🔍 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait 2-3 minutes for container startup"
Write-Host "2. Verify application: https://$AppServiceName.azurewebsites.net"
Write-Host "3. Check logs if issues: az webapp log tail --name $AppServiceName --resource-group $ResourceGroupName"
Write-Host "4. Run validation script: .\Test-ContainerDeployment.ps1"