# Azure Key Vault Integration Guide

This document describes the Azure Key Vault integration for the eShopLegacyMVC application.

## Overview

The application now supports retrieving secrets from Azure Key Vault using the Azure SDK for .NET. This provides:

- **Secure secret storage**: Connection strings and API keys are stored in Key Vault
- **Managed Identity authentication**: No credentials needed in production
- **Local development fallback**: Works seamlessly with local development
- **DefaultAzureCredential**: Automatic authentication across different environments

## Architecture

### Authentication Flow

The application uses `DefaultAzureCredential` which tries authentication methods in this order:

1. **Environment variables** - For service principal authentication
2. **Managed Identity** - When running in Azure App Service
3. **Azure CLI** - For local development
4. **Visual Studio** - For local development in Visual Studio

### Configuration Hierarchy

Secrets are retrieved in this order of precedence:

1. **Azure Key Vault** (if enabled and configured)
2. **Environment Variables** (using `ConnectionStrings__Name` or `AppSettings__Key` format)
3. **Web.config** (fallback for local development)

## Setup Instructions

### 1. Azure Key Vault Setup

The Key Vault should already be created by the infrastructure deployment script. If not, create it:

```bash
az keyvault create \
  --name kv-eshop-prototype-eastus2 \
  --resource-group rg-eshop-prototype-eastus2 \
  --location eastus2
```

### 2. Store Secrets in Key Vault

Store your connection strings and secrets:

```bash
# Database connection string
az keyvault secret set \
  --vault-name kv-eshop-prototype-eastus2 \
  --name "CatalogDbConnectionString" \
  --value "Server=tcp:your-server.database.windows.net,1433;Initial Catalog=CatalogDb;..."

# Application Insights instrumentation key (optional)
az keyvault secret set \
  --vault-name kv-eshop-prototype-eastus2 \
  --name "ApplicationInsights--InstrumentationKey" \
  --value "your-instrumentation-key"
```

### 3. Configure App Service Managed Identity

Enable Managed Identity for your App Service:

```bash
az webapp identity assign \
  --resource-group rg-eshop-prototype-eastus2 \
  --name app-eshop-prototype-eastus2
```

Grant the Managed Identity access to Key Vault:

```bash
# Get the principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --resource-group rg-eshop-prototype-eastus2 \
  --name app-eshop-prototype-eastus2 \
  --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name kv-eshop-prototype-eastus2 \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### 4. Configure Application Settings

Set the Key Vault endpoint in your App Service:

```bash
az webapp config appsettings set \
  --resource-group rg-eshop-prototype-eastus2 \
  --name app-eshop-prototype-eastus2 \
  --settings KEYVAULT_ENDPOINT="https://kv-eshop-prototype-eastus2.vault.azure.net/"
```

## Local Development

### Prerequisites

1. Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. Login to Azure: `az login`
3. Ensure you have access to the Key Vault

### Configuration

Set the Key Vault endpoint as an environment variable:

**PowerShell:**
```powershell
$env:KEYVAULT_ENDPOINT="https://kv-eshop-prototype-eastus2.vault.azure.net/"
```

**Bash:**
```bash
export KEYVAULT_ENDPOINT="https://kv-eshop-prototype-eastus2.vault.azure.net/"
```

### Testing Local Development

Run the test script to verify Key Vault access:

```powershell
.\test-keyvault-integration.ps1
```

### Fallback Mode

If Key Vault is not configured (no `KEYVAULT_ENDPOINT` environment variable), the application will:
1. Skip Key Vault initialization
2. Use environment variables if available
3. Fall back to Web.config values

This allows local development without Azure access.

## Code Integration

### Initialization

Key Vault is initialized during application startup in `Global.asax.cs`:

```csharp
var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
if (!string.IsNullOrEmpty(keyVaultEndpoint))
{
    KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);
}
```

### Usage

The `ConfigurationProvider` automatically checks Key Vault:

```csharp
// Automatically checks Key Vault first, then env vars, then Web.config
var connectionString = ConfigurationProvider.GetConnectionString("CatalogDBContext");
```

### Direct Key Vault Access

You can also access Key Vault directly:

```csharp
if (KeyVaultConfigurationProvider.IsEnabled)
{
    var secret = KeyVaultConfigurationProvider.GetSecret("MySecretName");
    
    // Or use TryGetSecret for safer access
    if (KeyVaultConfigurationProvider.TryGetSecret("MySecretName", out string secretValue))
    {
        // Use secretValue
    }
}
```

## Secret Naming Conventions

The application looks for secrets using these naming patterns:

### Connection Strings
- Format: `{Name}ConnectionString`
- Example: `CatalogDbConnectionString` for connection string named "CatalogDBContext"
- Alternative: Exact name match (e.g., `CatalogDBContext`)

### Application Settings
- Format: `{Key}` or `{Key}--{SubKey}` (using double dash for nested keys)
- Example: `ApplicationInsights--InstrumentationKey`

## Security Best Practices

1. **Least Privilege**: Grant only `get` and `list` permissions to Managed Identity
2. **Secret Rotation**: Regularly rotate secrets in Key Vault
3. **Audit Logs**: Enable Key Vault logging to track secret access
4. **Local Development**: Use Azure CLI authentication for local dev (never store credentials in code)
5. **Secret Names**: Use descriptive names that don't reveal sensitive information

## Troubleshooting

### Key Vault Not Initialized

**Symptom**: Application logs "KEYVAULT_ENDPOINT not configured"

**Solution**: Set the `KEYVAULT_ENDPOINT` environment variable

### Authentication Failed

**Symptom**: Error "Failed to initialize Key Vault client"

**Local Development:**
- Run `az login` to authenticate
- Verify you have access: `az keyvault secret list --vault-name kv-eshop-prototype-eastus2`

**Azure App Service:**
- Verify Managed Identity is enabled
- Check Key Vault access policies include the Managed Identity
- Review App Service logs for authentication errors

### Secret Not Found

**Symptom**: Application logs "Secret not found in Key Vault"

**Solution:**
- Verify secret exists: `az keyvault secret show --vault-name kv-eshop-prototype-eastus2 --name SecretName`
- Check secret name matches the expected naming convention
- Verify Key Vault permissions include "get" permission

### Performance Issues

**Symptom**: Slow application startup

**Solution:**
- Key Vault calls are cached during application startup
- First access to each secret may take 1-2 seconds
- Consider implementing application-level caching for frequently accessed secrets

## Testing

### Unit Tests

Run the Key Vault integration tests:

```bash
# Note: Integration tests require actual Key Vault access
dotnet test --filter "FullyQualifiedName~KeyVaultConfigurationProviderTests"
```

### Integration Tests

Run the PowerShell test script:

```powershell
.\test-keyvault-integration.ps1
```

This validates:
- Azure CLI authentication
- Key Vault existence
- Secret retrieval
- Local development fallback

## Monitoring

### Application Insights

Key Vault operations are logged automatically through log4net. Check logs for:
- `Initializing Key Vault client for endpoint`
- `Key Vault client initialized successfully`
- `Successfully retrieved secret`
- `Error retrieving secret from Key Vault`

### Key Vault Metrics

Monitor Key Vault metrics in Azure Portal:
- Secret access requests
- Authentication failures
- API latency

## Migration Checklist

- [x] Add Azure Key Vault SDK packages
- [x] Create KeyVaultConfigurationProvider class
- [x] Update ConfigurationProvider to check Key Vault
- [x] Initialize Key Vault in Global.asax.cs
- [x] Add unit tests for Key Vault integration
- [x] Create test script for validation
- [ ] Store secrets in Azure Key Vault (deployment task)
- [ ] Configure Managed Identity access policies (deployment task)
- [ ] Test in Azure App Service environment (QA task)
- [ ] Remove hardcoded credentials from Web.config (post-validation)
- [ ] Document secret rotation procedures (operations task)

## Additional Resources

- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [DefaultAzureCredential Documentation](https://docs.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential)
- [Managed Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Azure SDK for .NET](https://docs.microsoft.com/en-us/dotnet/azure/)
