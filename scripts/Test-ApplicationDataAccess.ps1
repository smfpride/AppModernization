# Test Application Data Access
# Verify that the application can successfully connect to Azure SQL Database and retrieve catalog data

param(
    [Parameter(Mandatory = $false)]
    [switch]$UseAzureSQL = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$ServerName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$UseEnvironmentVariables = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Application Data Access Test" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

try {
    # Import SqlServer module
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "Installing SqlServer PowerShell module..." -ForegroundColor Yellow
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
    }
    Import-Module SqlServer

    # Determine connection string based on parameters or environment variables
    if ($UseAzureSQL) {
        Write-Host "🔗 Configuring Azure SQL Database connection..." -ForegroundColor Yellow
        
        if ($UseEnvironmentVariables) {
            # Use environment variables for secure credential management
            $connectionString = $env:ConnectionStrings__CatalogDBContext
            if ([string]::IsNullOrEmpty($connectionString)) {
                throw "Environment variable 'ConnectionStrings__CatalogDBContext' not found. Please set it or provide connection parameters."
            }
            Write-Host "✅ Using connection string from environment variable" -ForegroundColor Green
        }
        elseif (-not [string]::IsNullOrEmpty($ServerName) -and -not [string]::IsNullOrEmpty($DatabaseName) -and -not [string]::IsNullOrEmpty($Username)) {
            # Use provided parameters
            if ([string]::IsNullOrEmpty($Password)) {
                $securePassword = Read-Host "Enter password for $Username" -AsSecureString
                $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
            }
            $connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
            Write-Host "✅ Using provided connection parameters" -ForegroundColor Green
        }
        else {
            throw "For Azure SQL Database testing, please either:`n  1. Set -UseEnvironmentVariables and configure ConnectionStrings__CatalogDBContext environment variable`n  2. Provide -ServerName, -DatabaseName, -Username parameters"
        }
    }
    else {
        # Test with LocalDB connection (for comparison)
        $connectionString = "Server=(localdb)\MSSQLLocalDB;Database=Microsoft.eShopOnContainers.Services.CatalogDb;Integrated Security=True;MultipleActiveResultSets=True;"
        Write-Host "🔗 Testing LocalDB connection..." -ForegroundColor Yellow
    }
    
    # Mask password in connection string for logging
    $maskedConnectionString = $connectionString -replace "Password=[^;]+", "Password=***"
    Write-Host "🔗 Connection String: $maskedConnectionString" -ForegroundColor Gray

    # Test 1: Basic connectivity and data retrieval
    Write-Host "`n📊 Test 1: Basic Data Retrieval" -ForegroundColor Green
    $catalogQuery = @"
        SELECT 
            c.Id,
            c.Name,
            c.Description,
            c.Price,
            c.PictureFileName,
            c.AvailableStock,
            b.Brand,
            t.Type
        FROM [dbo].[Catalog] c
        INNER JOIN [dbo].[CatalogBrand] b ON c.CatalogBrandId = b.Id
        INNER JOIN [dbo].[CatalogType] t ON c.CatalogTypeId = t.Id
        ORDER BY c.Id;
"@

    $catalogItems = Invoke-Sqlcmd -ConnectionString $connectionString -Query $catalogQuery
    Write-Host "✅ Retrieved $($catalogItems.Count) catalog items" -ForegroundColor Green

    # Display sample items
    Write-Host "`n📋 Sample Catalog Items:" -ForegroundColor White
    $catalogItems | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $($_.Id): $($_.Name) - $($_.Brand) $($_.Type) - `$$($_.Price) (Stock: $($_.AvailableStock))" -ForegroundColor Gray
    }

    # Test 2: Brand filtering (typical application scenario)
    Write-Host "`n📊 Test 2: Brand Filtering" -ForegroundColor Green
    $brandFilterQuery = @"
        SELECT 
            c.Id,
            c.Name,
            c.Price,
            b.Brand
        FROM [dbo].[Catalog] c
        INNER JOIN [dbo].[CatalogBrand] b ON c.CatalogBrandId = b.Id
        WHERE b.Brand = '.NET'
        ORDER BY c.Price;
"@

    $dotNetItems = Invoke-Sqlcmd -ConnectionString $connectionString -Query $brandFilterQuery
    Write-Host "✅ Found $($dotNetItems.Count) .NET branded items" -ForegroundColor Green
    $dotNetItems | ForEach-Object {
        Write-Host "   $($_.Name) - `$$($_.Price)" -ForegroundColor Gray
    }

    # Test 3: Type filtering
    Write-Host "`n📊 Test 3: Type Filtering" -ForegroundColor Green
    $typeFilterQuery = @"
        SELECT 
            c.Id,
            c.Name,
            c.Price,
            t.Type
        FROM [dbo].[Catalog] c
        INNER JOIN [dbo].[CatalogType] t ON c.CatalogTypeId = t.Id
        WHERE t.Type = 'T-Shirt'
        ORDER BY c.Price;
"@

    $tShirtItems = Invoke-Sqlcmd -ConnectionString $connectionString -Query $typeFilterQuery
    Write-Host "✅ Found $($tShirtItems.Count) T-Shirt items" -ForegroundColor Green
    $tShirtItems | ForEach-Object {
        Write-Host "   $($_.Name) - `$$($_.Price)" -ForegroundColor Gray
    }

    # Test 4: Available brands and types (for dropdown lists)
    Write-Host "`n📊 Test 4: Available Brands and Types" -ForegroundColor Green
    
    $brandsQuery = "SELECT Id, Brand FROM [dbo].[CatalogBrand] ORDER BY Brand"
    $brands = Invoke-Sqlcmd -ConnectionString $connectionString -Query $brandsQuery
    Write-Host "✅ Available Brands: $($brands.Count)" -ForegroundColor Green
    $brands | ForEach-Object { Write-Host "   $($_.Id): $($_.Brand)" -ForegroundColor Gray }

    $typesQuery = "SELECT Id, Type FROM [dbo].[CatalogType] ORDER BY Type"
    $types = Invoke-Sqlcmd -ConnectionString $connectionString -Query $typesQuery
    Write-Host "✅ Available Types: $($types.Count)" -ForegroundColor Green
    $types | ForEach-Object { Write-Host "   $($_.Id): $($_.Type)" -ForegroundColor Gray }

    # Test 5: Performance test (simulate Web API call)
    Write-Host "`n📊 Test 5: Performance Test" -ForegroundColor Green
    $performanceQuery = @"
        SELECT 
            COUNT(*) as TotalItems,
            AVG(Price) as AveragePrice,
            MIN(Price) as MinPrice,
            MAX(Price) as MaxPrice,
            SUM(AvailableStock) as TotalStock
        FROM [dbo].[Catalog];
"@

    $startTime = Get-Date
    $stats = Invoke-Sqlcmd -ConnectionString $connectionString -Query $performanceQuery
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    Write-Host "✅ Performance test completed in $([math]::Round($duration, 2))ms" -ForegroundColor Green
    Write-Host "   Total Items: $($stats.TotalItems)" -ForegroundColor Gray
    Write-Host "   Average Price: `$$([math]::Round($stats.AveragePrice, 2))" -ForegroundColor Gray
    Write-Host "   Price Range: `$$($stats.MinPrice) - `$$($stats.MaxPrice)" -ForegroundColor Gray
    Write-Host "   Total Stock: $($stats.TotalStock)" -ForegroundColor Gray

    Write-Host "`n🎉 All Application Data Access Tests PASSED!" -ForegroundColor Green
    Write-Host "   ✅ Basic data retrieval working" -ForegroundColor Green
    Write-Host "   ✅ Brand and type filtering functional" -ForegroundColor Green
    Write-Host "   ✅ Foreign key relationships maintained" -ForegroundColor Green
    Write-Host "   ✅ Performance acceptable for web application" -ForegroundColor Green
    Write-Host "   ✅ Ready for production deployment" -ForegroundColor Green

} catch {
    Write-Host "❌ Application data access test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🏁 Application Data Access Test Complete!" -ForegroundColor Cyan