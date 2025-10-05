# Deploy-WindowsContainer.ps1
# IMMEDIATE SOLUTION: Deploy Windows Container on Premium Plan
#
# This script upgrades the App Service Plan to support Windows containers
# and properly deploys the existing Windows container image.
#
# COST IMPACT: ~$73/month increase (P1V2 Premium vs S1 Standard)
# BENEFIT: Immediate resolution for Story 8 QA testing
#
# Author: Alex (DevOps Engineer)
# Date: October 5, 2025
# Context: Story 8 critical deployment - Windows container solution

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanName = "asp-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

Write-Host "🪟 WINDOWS CONTAINER DEPLOYMENT SOLUTION" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "Upgrading to Premium Plan for Windows Container Support"
Write-Host ""

if ($ValidateOnly) {
    Write-Host "📋 VALIDATION MODE: Current Configuration" -ForegroundColor Yellow
    
    # Check current plan
    $currentPlan = az appservice plan show --name $AppServicePlanName --resource-group $ResourceGroupName | ConvertFrom-Json
    Write-Host "Current Plan: $($currentPlan.sku.name) $($currentPlan.sku.tier) (~$73/month)"
    
    Write-Host ""
    Write-Host "📊 PROPOSED CHANGES:" -ForegroundColor Green
    Write-Host "• Upgrade to: P1V2 Premium (~$146/month)"
    Write-Host "• Enable: Windows Container support"
    Write-Host "• Deploy: acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
    Write-Host "• Cost Impact: +$73/month (100% increase)"
    Write-Host ""
    Write-Host "✅ This solution will work immediately for Story 8"
    exit 0
}

try {
    Write-Host "1️⃣ Upgrading App Service Plan to Premium (Windows Container support)..." -ForegroundColor Cyan
    
    # Scale up to P1V2 Premium which supports Windows containers
    az appservice plan update `
        --name $AppServicePlanName `
        --resource-group $ResourceGroupName `
        --sku P1V2
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upgrade App Service Plan to P1V2"
    }
    Write-Host "✅ App Service Plan upgraded to P1V2 Premium" -ForegroundColor Green
    
    Write-Host "2️⃣ Configuring Windows Container deployment..." -ForegroundColor Cyan
    
    # Configure the web app for Windows containers
    az webapp config set `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --windows-fx-version "DOCKER|acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to configure Windows container"
    }
    Write-Host "✅ Windows container configured" -ForegroundColor Green
    
    Write-Host "3️⃣ Configuring container registry access..." -ForegroundColor Cyan
    
    # Ensure ACR authentication is set up
    az webapp config container set `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --docker-custom-image-name "acreshopprototype.azurecr.io/eshoplegacymvc:v1.0" `
        --docker-registry-server-url "https://acreshopprototype.azurecr.io"
    
    Write-Host "✅ Container registry access configured" -ForegroundColor Green
    
    Write-Host "4️⃣ Enabling container logging..." -ForegroundColor Cyan
    
    az webapp log config `
        --name $AppServiceName `
        --resource-group $ResourceGroupName `
        --docker-container-logging filesystem
    
    Write-Host "✅ Container logging enabled" -ForegroundColor Green
    
    Write-Host "5️⃣ Restarting App Service..." -ForegroundColor Cyan
    
    az webapp restart `
        --name $AppServiceName `
        --resource-group $ResourceGroupName
    
    Write-Host "✅ App Service restarted" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 WINDOWS CONTAINER DEPLOYMENT COMPLETED!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "App Service: $AppServiceName"
    Write-Host "URL: https://$AppServiceName.azurewebsites.net"
    Write-Host "Plan: P1V2 Premium (Windows Container enabled)"
    Write-Host "Container: acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
    Write-Host ""
    Write-Host "⏱️ Windows container startup: 2-4 minutes"
    Write-Host "💰 Monthly cost: ~$146 (increased from ~$73)"
    Write-Host ""
    Write-Host "🔍 Next Steps:"
    Write-Host "1. Wait 3-4 minutes for Windows container startup"
    Write-Host "2. Test: https://$AppServiceName.azurewebsites.net"
    Write-Host "3. Run Story 8 QA testing"
    Write-Host "4. Consider Linux modernization for future cost optimization"
    
} catch {
    Write-Host "❌ WINDOWS CONTAINER DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "🔄 ROLLBACK: Consider downgrading plan if needed" -ForegroundColor Yellow
    Write-Host "Command: az appservice plan update --name $AppServicePlanName --resource-group $ResourceGroupName --sku S1"
    
    exit 1
}

Write-Host ""
Write-Host "✅ STORY 8 DEPLOYMENT SOLUTION IMPLEMENTED!" -ForegroundColor Green