# Test-ContainerDeployment.ps1
# DEPLOYMENT VALIDATION: Verify container deployment success for Story 8
#
# Purpose: Validate that App Service container deployment fixed the critical issue
# Tests: Application accessibility, content verification, container status
# Context: Post-deployment validation for Story 8 QA testing
#
# Author: Alex (DevOps Engineer)
# Date: October 5, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [int]$TimeoutMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowLogs,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

# Error handling and logging
$ErrorActionPreference = "Stop"
$appUrl = "https://$AppServiceName.azurewebsites.net"

Write-Host "🧪 DEPLOYMENT VALIDATION: Container Deployment Test" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Yellow
Write-Host "App Service: $AppServiceName"
Write-Host "Target URL: $appUrl"
Write-Host "Timeout: $TimeoutMinutes minutes"
Write-Host ""

# Test Results Tracking
$testResults = @{
    "PrerequisiteCheck" = $false
    "AppServiceStatus" = $false
    "ContainerConfiguration" = $false
    "HttpResponse" = $false
    "ContentValidation" = $false
    "StartTime" = Get-Date
}

try {
    # Test 1: Prerequisites Check
    Write-Host "📋 Test 1: Prerequisites Check" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────" -ForegroundColor Gray
    
    # Verify Azure CLI login
    $account = az account show --query "name" -o tsv 2>$null
    if (-not $account) {
        throw "Not logged into Azure CLI"
    }
    Write-Host "✅ Azure CLI authenticated: $account" -ForegroundColor Green
    
    # Verify resources exist
    $appExists = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
    if (-not $appExists) {
        throw "App Service '$AppServiceName' not found"
    }
    Write-Host "✅ App Service exists: $AppServiceName" -ForegroundColor Green
    
    $testResults.PrerequisiteCheck = $true
    Write-Host ""
    
    # Test 2: App Service Status Check
    Write-Host "🏃 Test 2: App Service Status Check" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────" -ForegroundColor Gray
    
    $appState = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "state" -o tsv
    $appKind = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "kind" -o tsv
    
    Write-Host "App State: $appState"
    Write-Host "App Kind: $appKind"
    
    if ($appState -ne "Running") {
        Write-Host "⚠️ App Service not in Running state: $appState" -ForegroundColor Yellow
        Write-Host "Attempting to start App Service..." -ForegroundColor Yellow
        
        az webapp start --name $AppServiceName --resource-group $ResourceGroupName
        Start-Sleep -Seconds 30
        
        $appState = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "state" -o tsv
    }
    
    if ($appState -eq "Running") {
        Write-Host "✅ App Service is running" -ForegroundColor Green
        $testResults.AppServiceStatus = $true
    } else {
        Write-Host "❌ App Service not running: $appState" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 3: Container Configuration Check
    Write-Host "📦 Test 3: Container Configuration Check" -ForegroundColor Cyan
    Write-Host "──────────────────────────────────────────" -ForegroundColor Gray
    
    # Check Linux container configuration (different approach)
    $siteConfig = az webapp config show --name $AppServiceName --resource-group $ResourceGroupName --query "{linuxFxVersion: linuxFxVersion, windowsFxVersion: windowsFxVersion}" | ConvertFrom-Json
    
    Write-Host "Linux FX Version: $($siteConfig.linuxFxVersion)"
    Write-Host "Windows FX Version: $($siteConfig.windowsFxVersion)"
    
    # Check app settings for container image
    $appSettings = az webapp config appsettings list --name $AppServiceName --resource-group $ResourceGroupName | ConvertFrom-Json
    $dockerImageSetting = $appSettings | Where-Object { $_.name -eq "DOCKER_CUSTOM_IMAGE_NAME" }
    
    if ($dockerImageSetting) {
        Write-Host "Docker Image Setting: $($dockerImageSetting.value)"
        
        if ($dockerImageSetting.value -and $dockerImageSetting.value.Contains("eshoplegacymvc")) {
            Write-Host "✅ Container image correctly configured" -ForegroundColor Green
            $testResults.ContainerConfiguration = $true
        } else {
            Write-Host "❌ Container image not properly configured" -ForegroundColor Red
            Write-Host "Expected: eshoplegacymvc image, Got: $($dockerImageSetting.value)" -ForegroundColor Red
        }
    } elseif ($siteConfig.linuxFxVersion -and $siteConfig.linuxFxVersion.Contains("eshoplegacymvc")) {
        Write-Host "✅ Container image correctly configured in linuxFxVersion" -ForegroundColor Green
        $testResults.ContainerConfiguration = $true
    } elseif ($siteConfig.windowsFxVersion -and $siteConfig.windowsFxVersion.Contains("eshoplegacymvc")) {
        Write-Host "✅ Container image correctly configured in windowsFxVersion" -ForegroundColor Green
        $testResults.ContainerConfiguration = $true
    } else {
        Write-Host "❌ No container configuration found" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 4: HTTP Response Test with Retry Logic
    Write-Host "🌐 Test 4: HTTP Response Test (with retry)" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────" -ForegroundColor Gray
    
    $maxRetries = ($TimeoutMinutes * 60) / 30  # Check every 30 seconds
    $retryCount = 0
    $httpSuccess = $false
    $responseContent = ""
    
    while ($retryCount -lt $maxRetries -and -not $httpSuccess) {
        try {
            Write-Host "Attempt $($retryCount + 1)/$maxRetries - Testing: $appUrl" -ForegroundColor Gray
            
            $response = Invoke-WebRequest -Uri $appUrl -TimeoutSec 30 -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ HTTP 200 OK received" -ForegroundColor Green
                $responseContent = $response.Content
                $httpSuccess = $true
                $testResults.HttpResponse = $true
            } else {
                Write-Host "⚠️ HTTP $($response.StatusCode) received" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "⚠️ HTTP request failed: $($_.Exception.Message)" -ForegroundColor Yellow
            
            if ($retryCount -lt ($maxRetries - 1)) {
                Write-Host "⏱️ Waiting 30 seconds before retry..." -ForegroundColor Gray
                Start-Sleep -Seconds 30
            }
        }
        
        $retryCount++
    }
    
    if (-not $httpSuccess) {
        Write-Host "❌ HTTP response test failed after $maxRetries attempts" -ForegroundColor Red
    }
    Write-Host ""
    
    # Test 5: Content Validation
    Write-Host "📝 Test 5: Content Validation" -ForegroundColor Cyan
    Write-Host "──────────────────────────────────" -ForegroundColor Gray
    
    if ($httpSuccess -and $responseContent) {
        # Check for default Azure page (the original problem)
        if ($responseContent -match "Microsoft Azure App Service.*Welcome" -or 
            $responseContent -match "Your web app is running and waiting") {
            Write-Host "❌ Still showing default Azure welcome page!" -ForegroundColor Red
            Write-Host "🚨 DEPLOYMENT FIX DID NOT WORK - Container not deployed" -ForegroundColor Red
        }
        # Check for eShop application content
        elseif ($responseContent -match "eShop|catalog|Catalog|eshop" -or
                $responseContent -match "Microsoft.*ASP\.NET" -or
                $responseContent -match "Home.*About.*Contact") {
            Write-Host "✅ eShopLegacyMVC application content detected!" -ForegroundColor Green
            Write-Host "🎉 DEPLOYMENT FIX SUCCESSFUL - Container deployed correctly" -ForegroundColor Green
            $testResults.ContentValidation = $true
        }
        else {
            Write-Host "⚠️ Unknown content - manual verification needed" -ForegroundColor Yellow
            if ($Detailed) {
                Write-Host "Response preview (first 500 chars):" -ForegroundColor Gray
                Write-Host $responseContent.Substring(0, [Math]::Min(500, $responseContent.Length)) -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ No content to validate - HTTP test failed" -ForegroundColor Red
    }
    Write-Host ""
    
} catch {
    Write-Host "❌ VALIDATION ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Show container logs if requested or if tests failed
if ($ShowLogs -or (-not $testResults.ContentValidation -and $testResults.HttpResponse)) {
    Write-Host "📋 Container Logs (last 50 lines):" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────" -ForegroundColor Gray
    try {
        az webapp log tail --name $AppServiceName --resource-group $ResourceGroupName --num-lines 50
    } catch {
        Write-Host "⚠️ Could not retrieve logs: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Final Results
Write-Host "📊 VALIDATION RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Yellow

$testResults.EndTime = Get-Date
$testDuration = $testResults.EndTime - $testResults.StartTime

Write-Host "Test Duration: $($testDuration.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host ""

$passCount = ($testResults.Values | Where-Object { $_ -eq $true }).Count - 2  # Exclude timestamps
$totalTests = $testResults.Count - 2  # Exclude timestamps

foreach ($test in $testResults.Keys | Where-Object { $_ -notmatch "Time" }) {
    $status = if ($testResults[$test]) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($testResults[$test]) { "Green" } else { "Red" }
    Write-Host "$test`: $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "Overall Result: $passCount/$totalTests tests passed" -ForegroundColor $(if ($passCount -eq $totalTests) { "Green" } else { "Yellow" })

if ($testResults.ContentValidation) {
    Write-Host ""
    Write-Host "🎉 SUCCESS: Container deployment is working!" -ForegroundColor Green
    Write-Host "✅ Story 8 QA testing can proceed" -ForegroundColor Green
    Write-Host "🌐 Application URL: $appUrl" -ForegroundColor Green
} elseif ($testResults.HttpResponse -and -not $testResults.ContentValidation) {
    Write-Host ""
    Write-Host "⚠️ PARTIAL SUCCESS: App responds but content needs manual verification" -ForegroundColor Yellow
    Write-Host "🔍 Please manually check: $appUrl" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ DEPLOYMENT VALIDATION FAILED" -ForegroundColor Red
    Write-Host "🚨 Container deployment issue not resolved" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Recommended next steps:" -ForegroundColor Yellow
    Write-Host "1. Check container logs: az webapp log tail --name $AppServiceName --resource-group $ResourceGroupName"
    Write-Host "2. Verify container image: az acr repository show --name acreshopprototype --image eshoplegacymvc:v1.0"
    Write-Host "3. Review App Service configuration: az webapp config container show --name $AppServiceName --resource-group $ResourceGroupName"
}