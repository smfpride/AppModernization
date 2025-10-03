# Setup Secure Environment Variables for Database Testing
# This script configures environment variables for secure database connectivity testing

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerName = "sql-eshop-prototype-eastus2.database.windows.net",
    
    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "CatalogDb",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "eshopadmin",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Process", "User", "Machine")]
    [string]$Scope = "Process"
)

Write-Host "🔐 Setting up Secure Environment Variables for Database Testing" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

try {
    # Prompt for password if not provided
    if ([string]::IsNullOrEmpty($Password)) {
        $securePassword = Read-Host "Enter password for SQL user '$Username'" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }

    # Build the connection string
    $connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

    # Set environment variables
    Write-Host "🔧 Setting environment variables..." -ForegroundColor Yellow
    
    [Environment]::SetEnvironmentVariable("ConnectionStrings__CatalogDBContext", $connectionString, $Scope)
    [Environment]::SetEnvironmentVariable("SQL_SERVER", $ServerName, $Scope)
    [Environment]::SetEnvironmentVariable("SQL_DATABASE", $DatabaseName, $Scope)
    [Environment]::SetEnvironmentVariable("SQL_USER", $Username, $Scope)
    # Note: We don't store the password separately for security
    
    Write-Host "✅ Environment variables configured successfully!" -ForegroundColor Green
    Write-Host "   Scope: $Scope" -ForegroundColor White
    Write-Host "   Server: $ServerName" -ForegroundColor White
    Write-Host "   Database: $DatabaseName" -ForegroundColor White
    Write-Host "   Username: $Username" -ForegroundColor White
    
    # Test the environment variable
    Write-Host "`n🧪 Testing environment variable..." -ForegroundColor Yellow
    $testConnectionString = [Environment]::GetEnvironmentVariable("ConnectionStrings__CatalogDBContext", $Scope)
    if (-not [string]::IsNullOrEmpty($testConnectionString)) {
        $maskedConnectionString = $testConnectionString -replace "Password=[^;]+", "Password=***"
        Write-Host "✅ Environment variable set correctly:" -ForegroundColor Green
        Write-Host "   $maskedConnectionString" -ForegroundColor Gray
    } else {
        throw "Failed to set environment variable"
    }
    
    Write-Host "`n📋 Usage Examples:" -ForegroundColor Green
    Write-Host "   Test Database Connectivity:" -ForegroundColor White
    Write-Host "   .\scripts\Test-DatabaseConnectivity.ps1 -UseEnvironmentVariables" -ForegroundColor Gray
    Write-Host "`n   Test Application Data Access:" -ForegroundColor White
    Write-Host "   .\scripts\Test-ApplicationDataAccess.ps1 -UseEnvironmentVariables" -ForegroundColor Gray
    
    if ($Scope -eq "Process") {
        Write-Host "`n⚠️ Note: Process-scoped environment variables will be lost when the PowerShell session ends." -ForegroundColor Yellow
        Write-Host "   For persistent configuration, use -Scope User or -Scope Machine" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Failed to setup environment variables: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🏁 Secure Environment Setup Complete!" -ForegroundColor Cyan