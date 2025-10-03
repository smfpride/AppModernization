# Azure Deployment Environment Variable Substitution Script
# This script replaces tokenized values in Web.config with environment variables

param(
    [string]$ConfigFile = "Web.config",
    [string]$Environment = "Production"
)

Write-Host "Starting environment variable substitution for $Environment environment..."

# Read the configuration file
$content = Get-Content $ConfigFile -Raw

# Define environment variable mappings
$environmentVariables = @{
    "#{CATALOG_DB_CONNECTION_STRING}#" = $env:CATALOG_DB_CONNECTION_STRING ?? "Server=tcp:your-server.database.windows.net,1433;Initial Catalog=CatalogDb;Persist Security Info=False;User ID=your-user;Password=your-password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "#{USE_MOCK_DATA}#" = $env:USE_MOCK_DATA ?? "false"
    "#{USE_CUSTOMIZATION_DATA}#" = $env:USE_CUSTOMIZATION_DATA ?? "false"
    "#{ASPNET_ENVIRONMENT}#" = $env:ASPNET_ENVIRONMENT ?? $Environment
    "#{APPINSIGHTS_INSTRUMENTATIONKEY}#" = $env:APPINSIGHTS_INSTRUMENTATIONKEY ?? ""
    "#{KEYVAULT_ENDPOINT}#" = $env:KEYVAULT_ENDPOINT ?? ""
    "#{MACHINE_KEY_VALIDATION}#" = $env:MACHINE_KEY_VALIDATION ?? ""
    "#{MACHINE_KEY_DECRYPTION}#" = $env:MACHINE_KEY_DECRYPTION ?? ""
}

# Replace tokens with environment variables
foreach ($token in $environmentVariables.Keys) {
    $value = $environmentVariables[$token]
    if ($value) {
        $content = $content -replace [regex]::Escape($token), $value
        Write-Host "✓ Replaced $token"
    } else {
        Write-Warning "⚠ Environment variable for $token is not set"
    }
}

# Write the updated content back to the file
$content | Set-Content $ConfigFile -Encoding UTF8

Write-Host "Environment variable substitution completed for $ConfigFile"

# Validate the result
if ($content -match "#{.*}#") {
    Write-Warning "⚠ Some tokens were not replaced. Please check environment variables."
    $unresolved = [regex]::Matches($content, "#{[^}]+}#") | ForEach-Object { $_.Value }
    Write-Host "Unresolved tokens: $($unresolved -join ', ')"
} else {
    Write-Host "✓ All tokens successfully resolved"
}