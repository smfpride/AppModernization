# Key Vault Integration Test Execution Script
# This script sets up the environment and executes the Key Vault integration tests

param(
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultEndpoint = "https://kv-eshop-prototype.vault.azure.net/"
)

Write-Host "🔑 Running Key Vault Integration Tests" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Set environment variable for this process and child processes
$env:KEYVAULT_ENDPOINT = $KeyVaultEndpoint
[Environment]::SetEnvironmentVariable("KEYVAULT_ENDPOINT", $KeyVaultEndpoint, "Process")

Write-Host "Environment configured:" -ForegroundColor Cyan
Write-Host "  KEYVAULT_ENDPOINT = $env:KEYVAULT_ENDPOINT" -ForegroundColor Cyan

Write-Host "`nRunning integration tests..." -ForegroundColor Yellow

# Run the specific integration tests
try {
    # Filter to run only the integration tests
    $testFilter = "Integration_GetSecret_WithValidKeyVault_ReturnsSecret|Integration_TryGetSecret_WithValidKeyVault_ReturnsTrue|Integration_GetSecret_WithNonExistentSecret_ReturnsNull"
    
    Write-Host "Executing: dotnet test --filter `"$testFilter`" --logger `"console;verbosity=detailed`"" -ForegroundColor Gray
    
    & dotnet test --filter $testFilter --logger "console;verbosity=detailed"
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "`n✅ Integration tests completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Integration tests failed with exit code: $exitCode" -ForegroundColor Red
    }
    
    return $exitCode
} catch {
    Write-Host "`n❌ Error running integration tests: $($_.Exception.Message)" -ForegroundColor Red
    return 1
}