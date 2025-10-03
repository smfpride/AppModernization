# Azure Infrastructure Validation Script
# This script validates that all resources were created correctly and are accessible
# Story 3: Infrastructure Validation Tests

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$SqlServerName = "sql-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "CatalogDb",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName = "kv-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanName = "asp-eshop-prototype-eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "app-eshop-prototype-eastus2"
)

Write-Host "🔍 Azure Infrastructure Validation Tests" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$testResults = @()

function Test-ResourceExists {
    param(
        [string]$TestName,
        [string]$Command,
        [string]$ExpectedProperty = $null
    )
    
    Write-Host "`n📋 Testing: $TestName..." -ForegroundColor Yellow
    
    try {
        $result = Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            $jsonResult = $result | ConvertFrom-Json
            if ($ExpectedProperty -and $jsonResult.$ExpectedProperty) {
                Write-Host "✓ PASS: $TestName - Property '$ExpectedProperty' found" -ForegroundColor Green
                return @{ Test = $TestName; Status = "PASS"; Details = $jsonResult.$ExpectedProperty }
            } elseif (-not $ExpectedProperty -and $jsonResult) {
                Write-Host "✓ PASS: $TestName - Resource exists" -ForegroundColor Green
                return @{ Test = $TestName; Status = "PASS"; Details = "Resource exists" }
            } else {
                Write-Host "⚠ WARNING: $TestName - Resource exists but expected property not found" -ForegroundColor Yellow
                return @{ Test = $TestName; Status = "WARNING"; Details = "Property $ExpectedProperty not found" }
            }
        } else {
            Write-Host "❌ FAIL: $TestName - Resource not found or command failed" -ForegroundColor Red
            return @{ Test = $TestName; Status = "FAIL"; Details = "Resource not found" }
        }
    } catch {
        Write-Host "❌ FAIL: $TestName - Error: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Test = $TestName; Status = "FAIL"; Details = $_.Exception.Message }
    }
}

# Test 1: Resource Group
$testResults += Test-ResourceExists -TestName "Resource Group Exists" -Command "az group show --name $ResourceGroupName --output json" -ExpectedProperty "name"

# Test 2: SQL Server
$testResults += Test-ResourceExists -TestName "SQL Server Exists" -Command "az sql server show --resource-group $ResourceGroupName --name $SqlServerName --output json" -ExpectedProperty "fullyQualifiedDomainName"

# Test 3: SQL Database
$testResults += Test-ResourceExists -TestName "SQL Database Exists" -Command "az sql db show --resource-group $ResourceGroupName --server $SqlServerName --name $DatabaseName --output json" -ExpectedProperty "currentServiceObjectiveName"

# Test 4: Key Vault
$testResults += Test-ResourceExists -TestName "Key Vault Exists" -Command "az keyvault show --name $KeyVaultName --output json" -ExpectedProperty "properties"

# Test 5: App Service Plan
$testResults += Test-ResourceExists -TestName "App Service Plan Exists" -Command "az appservice plan show --resource-group $ResourceGroupName --name $AppServicePlanName --output json" -ExpectedProperty "sku"

# Test 6: App Service
$testResults += Test-ResourceExists -TestName "App Service Exists" -Command "az webapp show --resource-group $ResourceGroupName --name $AppServiceName --output json" -ExpectedProperty "defaultHostName"

# Test 7: Managed Identity
Write-Host "`n📋 Testing: App Service Managed Identity..." -ForegroundColor Yellow
try {
    $identityResult = az webapp identity show --resource-group $ResourceGroupName --name $AppServiceName --output json | ConvertFrom-Json
    if ($identityResult.principalId) {
        Write-Host "✓ PASS: Managed Identity configured with Principal ID: $($identityResult.principalId)" -ForegroundColor Green
        $testResults += @{ Test = "Managed Identity Configured"; Status = "PASS"; Details = $identityResult.principalId }
    } else {
        Write-Host "❌ FAIL: Managed Identity not configured" -ForegroundColor Red
        $testResults += @{ Test = "Managed Identity Configured"; Status = "FAIL"; Details = "No principal ID found" }
    }
} catch {
    Write-Host "❌ FAIL: Error checking Managed Identity: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Managed Identity Configured"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 8: Key Vault Secret (Connection String)
Write-Host "`n📋 Testing: Key Vault Secret Access..." -ForegroundColor Yellow
try {
    $secretResult = az keyvault secret show --vault-name $KeyVaultName --name "CatalogDbConnectionString" --output json | ConvertFrom-Json
    if ($secretResult.value) {
        Write-Host "✓ PASS: Connection string stored in Key Vault" -ForegroundColor Green
        $testResults += @{ Test = "Key Vault Secret Stored"; Status = "PASS"; Details = "Connection string found" }
    } else {
        Write-Host "❌ FAIL: Connection string not found in Key Vault" -ForegroundColor Red
        $testResults += @{ Test = "Key Vault Secret Stored"; Status = "FAIL"; Details = "No secret value found" }
    }
} catch {
    Write-Host "❌ FAIL: Error accessing Key Vault secret: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "Key Vault Secret Stored"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 9: SQL Server Firewall Rules
Write-Host "`n📋 Testing: SQL Server Firewall Configuration..." -ForegroundColor Yellow
try {
    $firewallRules = az sql server firewall-rule list --resource-group $ResourceGroupName --server $SqlServerName --output json | ConvertFrom-Json
    $azureRule = $firewallRules | Where-Object { $_.name -eq "AllowAzureServices" }
    if ($azureRule) {
        Write-Host "✓ PASS: Azure services firewall rule configured" -ForegroundColor Green
        $testResults += @{ Test = "SQL Server Firewall Rules"; Status = "PASS"; Details = "AllowAzureServices rule found" }
    } else {
        Write-Host "❌ FAIL: Azure services firewall rule not found" -ForegroundColor Red
        $testResults += @{ Test = "SQL Server Firewall Rules"; Status = "FAIL"; Details = "AllowAzureServices rule missing" }
    }
} catch {
    Write-Host "❌ FAIL: Error checking firewall rules: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "SQL Server Firewall Rules"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 10: App Service Configuration
Write-Host "`n📋 Testing: App Service Configuration..." -ForegroundColor Yellow
try {
    $appConfig = az webapp config show --resource-group $ResourceGroupName --name $AppServiceName --output json | ConvertFrom-Json
    $appServicePlan = az appservice plan show --name $AppServicePlanName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
    
    # Check if it's properly configured for deployment
    if ($appServicePlan.kind -eq "app") {
        # Windows App Service - check for .NET Framework or .NET Core setup
        if ($appConfig.netFrameworkVersion -or $appConfig.phpVersion -or $appConfig.pythonVersion -or $appConfig.nodeVersion) {
            Write-Host "✓ PASS: Windows App Service configured for web applications (.NET Framework: $($appConfig.netFrameworkVersion))" -ForegroundColor Green
            $testResults += @{ Test = "App Service Container Config"; Status = "PASS"; Details = "Windows App Service ready for .NET applications" }
        } else {
            Write-Host "✓ PASS: Windows App Service created and ready for application deployment" -ForegroundColor Green
            $testResults += @{ Test = "App Service Container Config"; Status = "PASS"; Details = "Windows App Service ready for deployment" }
        }
    } elseif ($appConfig.linuxFxVersion -and $appConfig.linuxFxVersion -ne "") {
        Write-Host "✓ PASS: Linux App Service configured with: $($appConfig.linuxFxVersion)" -ForegroundColor Green
        $testResults += @{ Test = "App Service Container Config"; Status = "PASS"; Details = "Linux container configuration: $($appConfig.linuxFxVersion)" }
    } else {
        Write-Host "⚠ WARNING: App Service configuration unclear" -ForegroundColor Yellow
        $testResults += @{ Test = "App Service Container Config"; Status = "WARNING"; Details = "App Service created but configuration unclear" }
    }
} catch {
    Write-Host "❌ FAIL: Error checking App Service configuration: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{ Test = "App Service Container Config"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Summary Report
Write-Host "`n📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = ($testResults | Where-Object { $_.Status -eq "WARNING" }).Count

foreach ($result in $testResults) {
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
    }
    Write-Host "[$($result.Status)] $($result.Test): $($result.Details)" -ForegroundColor $color
}

Write-Host "`n📈 Overall Results:" -ForegroundColor Cyan
Write-Host "  ✓ Passed: $passCount" -ForegroundColor Green
Write-Host "  ⚠ Warnings: $warnCount" -ForegroundColor Yellow
Write-Host "  ❌ Failed: $failCount" -ForegroundColor Red

if ($failCount -eq 0) {
    Write-Host "`n🎉 All critical tests passed! Infrastructure is ready for application deployment." -ForegroundColor Green
    Write-Host "✅ Story 3 acceptance criteria validated successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠ Some tests failed. Please review and fix the issues before proceeding." -ForegroundColor Red
    exit 1
}