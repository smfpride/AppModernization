# Azure SQL Database Configuration
# Copy this file to azure-config.local.ps1 and update with your values
# azure-config.local.ps1 should be added to .gitignore for security

# Azure SQL Database Configuration
$AzureSqlConfig = @{
    # Azure SQL Server Details
    ServerName = "sql-eshop-prototype-eastus2.database.windows.net"  # Update with your Azure SQL Server FQDN
    DatabaseName = "CatalogDb"                                        # Update with your database name
    
    # SQL Authentication (use Azure AD authentication in production)
    Username = "sqladmin"                                             # Update with your SQL admin username
    # Password should be provided securely at runtime, not stored in files
    
    # Environment Variables for Deployment
    EnvironmentVariables = @{
        "SQL_SERVER" = "sql-eshop-prototype-eastus2.database.windows.net"
        "SQL_DATABASE" = "CatalogDb"
        "SQL_USER" = "sqladmin"
        # SQL_PASSWORD should be set securely in deployment environment
    }
}

# Usage Examples:
# 
# Deploy Database Schema:
# .\scripts\Deploy-DatabaseMigration.ps1 -ServerName $AzureSqlConfig.ServerName -DatabaseName $AzureSqlConfig.DatabaseName -Username $AzureSqlConfig.Username -Password (Read-Host "Enter SQL Password" -AsSecureString)
#
# Test Database Connectivity:
# .\scripts\Test-SimpleConnectivity.ps1 -ServerName $AzureSqlConfig.ServerName -DatabaseName $AzureSqlConfig.DatabaseName -Username $AzureSqlConfig.Username -Password "YourPassword"
#
# Using Environment Variables:
# $env:ConnectionStrings__CatalogDBContext = "Server=tcp:$($AzureSqlConfig.ServerName),1433;Initial Catalog=$($AzureSqlConfig.DatabaseName);Persist Security Info=False;User ID=$($AzureSqlConfig.Username);Password=YourPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Azure SQL Configuration loaded. Available settings:" -ForegroundColor Green
Write-Host "  Server: $($AzureSqlConfig.ServerName)" -ForegroundColor White
Write-Host "  Database: $($AzureSqlConfig.DatabaseName)" -ForegroundColor White
Write-Host "  Username: $($AzureSqlConfig.Username)" -ForegroundColor White
Write-Host "  Environment Variables configured: $($AzureSqlConfig.EnvironmentVariables.Count)" -ForegroundColor White