# Test Database Connectivity Script
# Story 4 Implementation - Database Connection Validation

param(
    [Parameter(Mandatory = $false)]
    [string]$ConnectionString = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$UseEnvironmentVariables = $false,
    
    [Parameter(Mandatory = $false)]
    [string]$ServerName = "sql-eshop-prototype-eastus2.database.windows.net",
    
    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "CatalogDb",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "eshopadmin",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

Write-Host "🔌 Database Connectivity Test" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

try {
    # Import required modules
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "⚠️ SqlServer module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
    }
    Import-Module SqlServer

    # Determine connection string
    if ($UseEnvironmentVariables) {
        $ConnectionString = $env:ConnectionStrings__CatalogDBContext
        if ([string]::IsNullOrEmpty($ConnectionString)) {
            throw "Environment variable 'ConnectionStrings__CatalogDBContext' not found"
        }
        Write-Host "📋 Using connection string from environment variable" -ForegroundColor Green
    } elseif ([string]::IsNullOrEmpty($ConnectionString)) {
        if ([string]::IsNullOrEmpty($Password)) {
            $securePassword = Read-Host "Enter password for $Username" -AsSecureString
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        }
        
        # Build connection string with provided parameters
        $ConnectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        Write-Host "📋 Using provided connection parameters for $ServerName" -ForegroundColor Green
    }

    # Mask password in output
    $maskedConnectionString = $ConnectionString -replace "Password=[^;]+", "Password=***"
    Write-Host "🔗 Connection String: $maskedConnectionString" -ForegroundColor White

    # Test basic connectivity
    Write-Host "`n🧪 Testing database connectivity..." -ForegroundColor Yellow
    
    $testQuery = "SELECT @@VERSION as SqlVersion, DB_NAME() as DatabaseName, GETDATE() as CurrentTime"
    $result = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $testQuery -QueryTimeout 30
    
    Write-Host "✅ Database connection successful!" -ForegroundColor Green
    Write-Host "   Database: $($result.DatabaseName)" -ForegroundColor White
    Write-Host "   Server Time: $($result.CurrentTime)" -ForegroundColor White
    Write-Host "   SQL Version: $($result.SqlVersion.Split("`n")[0])" -ForegroundColor White

    # Test table existence
    Write-Host "`n📊 Checking database schema..." -ForegroundColor Yellow
    
    $schemaQuery = @"
        SELECT 
            TABLE_NAME,
            TABLE_TYPE
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_NAME
"@
    
    $tables = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $schemaQuery
    
    if ($tables.Count -gt 0) {
        Write-Host "✅ Found $($tables.Count) tables:" -ForegroundColor Green
        foreach ($table in $tables) {
            Write-Host "   - $($table.TABLE_NAME)" -ForegroundColor White
        }
    } else {
        Write-Host "⚠️ No tables found in database" -ForegroundColor Yellow
    }

    # Test Entity Framework expected tables
    Write-Host "`n🏗️ Checking Entity Framework schema..." -ForegroundColor Yellow
    
    $efTablesQuery = @"
        SELECT 
            CASE 
                WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CatalogBrand') THEN 'EXISTS'
                ELSE 'MISSING'
            END as CatalogBrand,
            CASE 
                WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CatalogType') THEN 'EXISTS'
                ELSE 'MISSING'
            END as CatalogType,
            CASE 
                WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Catalog') THEN 'EXISTS'
                ELSE 'MISSING'
            END as Catalog,
            CASE 
                WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '__MigrationsHistory') THEN 'EXISTS'
                ELSE 'MISSING'
            END as MigrationsHistory
"@
    
    $efTables = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $efTablesQuery
    
    Write-Host "📋 Entity Framework Tables Status:" -ForegroundColor White
    Write-Host "   CatalogBrand: $($efTables.CatalogBrand)" -ForegroundColor $(if ($efTables.CatalogBrand -eq 'EXISTS') { 'Green' } else { 'Red' })
    Write-Host "   CatalogType: $($efTables.CatalogType)" -ForegroundColor $(if ($efTables.CatalogType -eq 'EXISTS') { 'Green' } else { 'Red' })
    Write-Host "   Catalog: $($efTables.Catalog)" -ForegroundColor $(if ($efTables.Catalog -eq 'EXISTS') { 'Green' } else { 'Red' })
    Write-Host "   __MigrationsHistory: $($efTables.MigrationsHistory)" -ForegroundColor $(if ($efTables.MigrationsHistory -eq 'EXISTS') { 'Green' } else { 'Red' })

    # Test data if tables exist
    if ($efTables.CatalogBrand -eq 'EXISTS' -and $efTables.CatalogType -eq 'EXISTS' -and $efTables.Catalog -eq 'EXISTS') {
        Write-Host "`n📈 Checking data counts..." -ForegroundColor Yellow
        
        $dataQuery = @"
            SELECT 
                (SELECT COUNT(*) FROM CatalogBrand) as BrandCount,
                (SELECT COUNT(*) FROM CatalogType) as TypeCount,
                (SELECT COUNT(*) FROM Catalog) as ItemCount
"@
        
        $dataCounts = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $dataQuery
        
        Write-Host "📊 Data Summary:" -ForegroundColor White
        Write-Host "   Brands: $($dataCounts.BrandCount)" -ForegroundColor White
        Write-Host "   Types: $($dataCounts.TypeCount)" -ForegroundColor White
        Write-Host "   Items: $($dataCounts.ItemCount)" -ForegroundColor White
    }

    # Performance test
    Write-Host "`n⚡ Performance test..." -ForegroundColor Yellow
    
    $performanceQuery = "SELECT COUNT(*) as RecordCount FROM INFORMATION_SCHEMA.TABLES"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $perfResult = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $performanceQuery
    $stopwatch.Stop()
    
    Write-Host "✅ Query executed in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green

    Write-Host "`n🎉 Database connectivity test completed successfully!" -ForegroundColor Green
    Write-Host "   ✅ Connection established" -ForegroundColor Green
    Write-Host "   ✅ Database accessible" -ForegroundColor Green
    Write-Host "   ✅ Schema validation completed" -ForegroundColor Green
    Write-Host "   ✅ Ready for Entity Framework operations" -ForegroundColor Green

} catch {
    Write-Host "`n❌ Database connectivity test failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*Login failed*") {
        Write-Host "`n💡 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "   - Check your username and password" -ForegroundColor White
        Write-Host "   - Verify SQL Server authentication is enabled" -ForegroundColor White
        Write-Host "   - Ensure firewall rules allow your IP address" -ForegroundColor White
    } elseif ($_.Exception.Message -like "*server was not found*") {
        Write-Host "`n💡 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "   - Check the server name and port" -ForegroundColor White
        Write-Host "   - Verify network connectivity" -ForegroundColor White
        Write-Host "   - Ensure the SQL Server is running" -ForegroundColor White
    }
    
    throw $_
}

Write-Host "`n🏁 Connectivity test complete!" -ForegroundColor Cyan