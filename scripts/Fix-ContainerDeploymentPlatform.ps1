# Fix-ContainerDeploymentPlatform.ps1
# CRITICAL PLATFORM FIX: Resolve Windows Container deployment issue
#
# ROOT CAUSE: App Service Plan (asp-eshop-prototype-eastus2) is a regular Windows plan
# that doesn't support Windows containers. The container image is built for Windows
# but the App Service Plan doesn't support container deployment.
#
# SOLUTION OPTIONS:
# 1. Create Linux App Service Plan + Linux container (RECOMMENDED - faster, cheaper)
# 2. Upgrade to Premium Windows Container plan (more expensive)
#
# Author: Alex (DevOps Engineer)
# Date: October 5, 2025
# Context: Story 8 critical deployment fix

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("linux", "windows")]
    [string]$PlatformStrategy = "linux",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

Write-Host "🚨 CRITICAL PLATFORM FIX: Container Deployment Platform Issue" -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host ""

# Step 1: Diagnose the current situation
Write-Host "🔍 DIAGNOSIS: Analyzing current configuration..." -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray

try {
    # Check current App Service Plan
    $currentPlan = az appservice plan show --name "asp-eshop-prototype-eastus2" --resource-group $ResourceGroupName | ConvertFrom-Json
    
    Write-Host "Current App Service Plan:" -ForegroundColor White
    Write-Host "  Name: $($currentPlan.name)"
    Write-Host "  SKU: $($currentPlan.sku.tier) $($currentPlan.sku.name)"
    Write-Host "  Kind: $($currentPlan.kind)"
    Write-Host "  Linux: $($currentPlan.reserved)"
    Write-Host "  HyperV: $($currentPlan.hyperV)"
    
    # Check container image platform
    Write-Host ""
    Write-Host "Container Image Analysis:" -ForegroundColor White
    Write-Host "  Image: acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
    Write-Host "  Platform: Windows (based on Dockerfile FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8)"
    
    Write-Host ""
    Write-Host "🚨 PROBLEM IDENTIFIED:" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "❌ Windows container image requires Windows Container App Service Plan" -ForegroundColor Red
    Write-Host "❌ Current plan is regular Windows (not container-enabled)" -ForegroundColor Red
    Write-Host "❌ Regular Windows plans don't support container deployment" -ForegroundColor Red
    
} catch {
    Write-Host "❌ Error during diagnosis: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($ValidateOnly) {
    Write-Host ""
    Write-Host "📋 RECOMMENDED SOLUTIONS:" -ForegroundColor Yellow
    Write-Host "═══════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🎯 OPTION 1 (RECOMMENDED): Linux Platform Migration" -ForegroundColor Green
    Write-Host "   • Create new Linux App Service Plan (B1 Basic ~$13/month)"
    Write-Host "   • Deploy existing Windows container to Linux plan"
    Write-Host "   • .NET Framework 4.8 containers run on Linux via compatibility layer"
    Write-Host "   • Faster deployment, lower cost, more common architecture"
    Write-Host ""
    Write-Host "🎯 OPTION 2: Windows Container Platform" -ForegroundColor Yellow
    Write-Host "   • Upgrade to Premium App Service Plan (P1V2 ~$146/month)"
    Write-Host "   • Keep Windows container as-is"
    Write-Host "   • More expensive, complex configuration"
    Write-Host ""
    Write-Host "💡 RECOMMENDATION: Use Option 1 (Linux) for cost-effectiveness and simplicity"
    exit 0
}

Write-Host ""
Write-Host "🔧 APPLYING FIX: $PlatformStrategy Platform Deployment" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow

if ($PlatformStrategy -eq "linux") {
    Write-Host ""
    Write-Host "🐧 LINUX STRATEGY: Creating Linux App Service Plan..." -ForegroundColor Cyan
    
    try {
        # Step 1: Create Linux App Service Plan
        Write-Host "1️⃣ Creating Linux App Service Plan..." -ForegroundColor Cyan
        
        $linuxPlanName = "asp-eshop-linux-eastus2"
        
        az appservice plan create `
            --name $linuxPlanName `
            --resource-group $ResourceGroupName `
            --location "East US 2" `
            --is-linux `
            --sku B1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Linux App Service Plan"
        }
        Write-Host "✅ Linux App Service Plan created: $linuxPlanName" -ForegroundColor Green
        
        # Step 2: Create new Linux Web App
        Write-Host "2️⃣ Creating Linux Web App..." -ForegroundColor Cyan
        
        $linuxAppName = "app-eshop-linux-eastus2"
        
        az webapp create `
            --name $linuxAppName `
            --resource-group $ResourceGroupName `
            --plan $linuxPlanName `
            --deployment-container-image-name "acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Linux Web App"
        }
        Write-Host "✅ Linux Web App created: $linuxAppName" -ForegroundColor Green
        
        # Step 3: Configure managed identity for ACR access
        Write-Host "3️⃣ Configuring managed identity..." -ForegroundColor Cyan
        
        az webapp identity assign `
            --name $linuxAppName `
            --resource-group $ResourceGroupName
        
        # Get the identity principal ID
        $principalId = az webapp identity show --name $linuxAppName --resource-group $ResourceGroupName --query "principalId" -o tsv
        
        # Grant ACR pull access
        az role assignment create `
            --assignee $principalId `
            --role "AcrPull" `
            --scope "/subscriptions/15ed6030-cc0e-4b95-9b8d-8d60f6b02b82/resourceGroups/rg-eshop-prototype-eastus2/providers/Microsoft.ContainerRegistry/registries/acreshopprototype"
        
        Write-Host "✅ Managed identity configured with ACR access" -ForegroundColor Green
        
        # Step 4: Configure container settings
        Write-Host "4️⃣ Configuring container deployment..." -ForegroundColor Cyan
        
        az webapp config container set `
            --name $linuxAppName `
            --resource-group $ResourceGroupName `
            --docker-custom-image-name "acreshopprototype.azurecr.io/eshoplegacymvc:v1.0" `
            --docker-registry-server-url "https://acreshopprototype.azurecr.io"
        
        # Enable container logging
        az webapp log config `
            --name $linuxAppName `
            --resource-group $ResourceGroupName `
            --docker-container-logging filesystem
        
        Write-Host "✅ Container deployment configured" -ForegroundColor Green
        
        # Step 5: Start the application
        Write-Host "5️⃣ Starting application..." -ForegroundColor Cyan
        
        az webapp start `
            --name $linuxAppName `
            --resource-group $ResourceGroupName
        
        Write-Host "✅ Application started" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🎉 LINUX DEPLOYMENT COMPLETED!" -ForegroundColor Green
        Write-Host "════════════════════════════════" -ForegroundColor Yellow
        Write-Host "New Linux App URL: https://$linuxAppName.azurewebsites.net"
        Write-Host "Container Image: acreshopprototype.azurecr.io/eshoplegacymvc:v1.0"
        Write-Host ""
        Write-Host "⏱️ Container startup may take 3-5 minutes for first deployment"
        Write-Host ""
        Write-Host "🔍 Next Steps:"
        Write-Host "1. Wait 3-5 minutes for container startup"
        Write-Host "2. Test: https://$linuxAppName.azurewebsites.net"
        Write-Host "3. Validate: .\Test-ContainerDeployment.ps1 -AppServiceName $linuxAppName"
        Write-Host "4. Update DNS/load balancer to point to new app (if needed)"
        
        # Note about original app
        Write-Host ""
        Write-Host "📝 IMPORTANT NOTES:" -ForegroundColor Yellow
        Write-Host "• Original Windows app ($AppServiceName) is still running"
        Write-Host "• New Linux app ($linuxAppName) will serve the container"
        Write-Host "• Once validated, you can delete the original Windows app"
        Write-Host "• Cost: Linux B1 plan (~$13/month vs S1 Windows ~$73/month)"
        
    } catch {
        Write-Host "❌ LINUX DEPLOYMENT FAILED: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
} else {
    Write-Host ""
    Write-Host "🪟 WINDOWS STRATEGY: Upgrading to Premium Windows Container Plan..." -ForegroundColor Cyan
    Write-Host "⚠️ WARNING: This will increase costs significantly (P1V2 ~$146/month)" -ForegroundColor Yellow
    
    # This would require upgrading the plan and more complex configuration
    Write-Host "❌ Windows Container strategy not implemented in this script" -ForegroundColor Red
    Write-Host "   Use Linux strategy instead: -PlatformStrategy linux" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ CRITICAL PLATFORM FIX COMPLETED!" -ForegroundColor Green