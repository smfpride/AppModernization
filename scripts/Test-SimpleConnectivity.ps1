# Simple Database Connectivity Test using .NET System.Data.SqlClient
# Story 4 Implementation - Database Connection Validation

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$UseEnvironmentVariable = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🔌 Simple Database Connectivity Test" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

try {
    # Load System.Data assembly
    Add-Type -AssemblyName System.Data

    # Determine connection string
    $connectionString = ""
    
    if ($UseEnvironmentVariable) {
        $connectionString = $env:ConnectionStrings__CatalogDBContext
        if ([string]::IsNullOrEmpty($connectionString)) {
            Write-Host "⚠️ Environment variable 'ConnectionStrings__CatalogDBContext' not found" -ForegroundColor Yellow
            Write-Host "   Falling back to Web.config simulation" -ForegroundColor Yellow
            $connectionString = "Data Source=(localdb)\MSSQLLocalDB; Initial Catalog=Microsoft.eShopOnContainers.Services.CatalogDb; Integrated Security=True; MultipleActiveResultSets=True;"
        } else {
            Write-Host "📋 Using connection string from environment variable" -ForegroundColor Green
        }
    } elseif (-not [string]::IsNullOrEmpty($Username) -and -not [string]::IsNullOrEmpty($Password)) {
        $connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        Write-Host "🔗 Using provided credentials for Azure SQL Database" -ForegroundColor Green
    } else {
        Write-Host "⚠️ No credentials provided. Testing with LocalDB fallback..." -ForegroundColor Yellow
        $connectionString = "Data Source=(localdb)\MSSQLLocalDB; Initial Catalog=Microsoft.eShopOnContainers.Services.CatalogDb; Integrated Security=True; MultipleActiveResultSets=True;"
    }

    # Mask password in output
    $maskedConnectionString = $connectionString -replace "Password=[^;]+", "Password=***"
    Write-Host "🔗 Connection String: $maskedConnectionString" -ForegroundColor White

    # Create connection
    Write-Host "`n🧪 Testing database connectivity..." -ForegroundColor Yellow
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    
    # Test connection
    $connection.Open()
    Write-Host "✅ Database connection opened successfully!" -ForegroundColor Green
    
    # Test basic query
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT @@VERSION as SqlVersion, DB_NAME() as DatabaseName, GETDATE() as CurrentTime"
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $sqlVersion = $reader["SqlVersion"].ToString().Split("`n")[0]
        $databaseName = $reader["DatabaseName"].ToString()
        $currentTime = $reader["CurrentTime"].ToString()
        
        Write-Host "   Database: $databaseName" -ForegroundColor White
        Write-Host "   Server Time: $currentTime" -ForegroundColor White
        Write-Host "   SQL Version: $sqlVersion" -ForegroundColor White
    }
    $reader.Close()

    # Test table existence
    Write-Host "`n📊 Checking database schema..." -ForegroundColor Yellow
    
    $command.CommandText = @"
        SELECT 
            TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_NAME
"@
    
    $reader = $command.ExecuteReader()
    $tables = @()
    while ($reader.Read()) {
        $tables += $reader["TABLE_NAME"].ToString()
    }
    $reader.Close()
    
    if ($tables.Count -gt 0) {
        Write-Host "✅ Found $($tables.Count) tables:" -ForegroundColor Green
        foreach ($table in $tables) {
            Write-Host "   - $table" -ForegroundColor White
        }
    } else {
        Write-Host "⚠️ No tables found in database (this is expected for a new database)" -ForegroundColor Yellow
    }

    # Test Entity Framework expected tables
    Write-Host "`n🏗️ Checking Entity Framework schema..." -ForegroundColor Yellow
    
    $efTables = @("CatalogBrand", "CatalogType", "Catalog", "__MigrationsHistory")
    $existingEfTables = @()
    
    foreach ($tableName in $efTables) {
        $command.CommandText = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$tableName'"
        $exists = [int]$command.ExecuteScalar() -gt 0
        $status = if ($exists) { "EXISTS" } else { "MISSING" }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "   $tableName : $status" -ForegroundColor $color
        
        if ($exists) {
            $existingEfTables += $tableName
        }
    }

    # Test performance
    Write-Host "`n⚡ Performance test..." -ForegroundColor Yellow
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $command.CommandText = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES"
    $recordCount = $command.ExecuteScalar()
    $stopwatch.Stop()
    
    Write-Host "✅ Query executed in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green

    $connection.Close()

    Write-Host "`n🎉 Database connectivity test completed successfully!" -ForegroundColor Green
    Write-Host "   ✅ Connection established" -ForegroundColor Green
    Write-Host "   ✅ Database accessible" -ForegroundColor Green
    Write-Host "   ✅ Schema validation completed" -ForegroundColor Green
    
    if ($existingEfTables.Count -eq 4) {
        Write-Host "   ✅ Entity Framework schema is ready" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Entity Framework schema needs migration" -ForegroundColor Yellow
        Write-Host "     Run the Deploy-DatabaseMigration.ps1 script to create the schema" -ForegroundColor Yellow
    }

    return $true

} catch {
    Write-Host "`n❌ Database connectivity test failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*Login failed*") {
        Write-Host "`n💡 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "   - Check your username and password" -ForegroundColor White
        Write-Host "   - Verify SQL Server authentication is enabled" -ForegroundColor White
        Write-Host "   - Ensure firewall rules allow your IP address" -ForegroundColor White
    } elseif ($_.Exception.Message -like "*server was not found*" -or $_.Exception.Message -like "*network-related*") {
        Write-Host "`n💡 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "   - Check the server name and port" -ForegroundColor White
        Write-Host "   - Verify network connectivity" -ForegroundColor White
        Write-Host "   - Ensure the SQL Server is running" -ForegroundColor White
        Write-Host "   - For LocalDB: ensure LocalDB is installed and running" -ForegroundColor White
    } elseif ($_.Exception.Message -like "*LocalDB*") {
        Write-Host "`n💡 LocalDB not available. This is expected in Azure environments." -ForegroundColor Yellow
        Write-Host "   - Use Azure SQL Database connection instead" -ForegroundColor White
        Write-Host "   - Set environment variable: ConnectionStrings__CatalogDBContext" -ForegroundColor White
    }
    
    return $false
} finally {
    if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
    }
}

Write-Host "`n🏁 Connectivity test complete!" -ForegroundColor Cyan