# Azure Key Vault Integration - Quick Reference

## 🔑 What Changed?

The application now retrieves secrets from Azure Key Vault instead of storing them in configuration files.

## 🚀 Getting Started

### For Local Development

1. **Authenticate with Azure CLI:**
   ```bash
   az login
   ```

2. **Set Key Vault endpoint:**
   
   **PowerShell:**
   ```powershell
   $env:KEYVAULT_ENDPOINT = "https://kv-eshop-prototype.vault.azure.net/"
   ```
   
   **Bash:**
   ```bash
   export KEYVAULT_ENDPOINT="https://kv-eshop-prototype.vault.azure.net/"
   ```

3. **Run the application** - It will automatically use Key Vault!

### For Azure Deployment

**No code changes needed!** The application automatically uses Managed Identity when running in Azure App Service.

Just ensure the `KEYVAULT_ENDPOINT` app setting is configured:
```bash
az webapp config appsettings set \
  --resource-group rg-eshop-prototype-eastus2 \
  --name app-eshop-prototype-eastus2 \
  --settings KEYVAULT_ENDPOINT="https://kv-eshop-prototype.vault.azure.net/"
```

## 📋 Configuration Hierarchy

The application looks for configuration in this order:

1. **🔐 Azure Key Vault** (if `KEYVAULT_ENDPOINT` is set)
2. **🌍 Environment Variables** (format: `ConnectionStrings__Name` or `AppSettings__Key`)
3. **📄 Web.config** (local development fallback)

## 🔍 How to Check if Key Vault is Working

### Check Application Logs

Look for these messages on startup:

✅ **Success:**
```
INFO - Initializing Key Vault integration with endpoint: https://...
INFO - Key Vault client initialized successfully
INFO - Successfully retrieved secret: CatalogDbConnectionString
```

❌ **Not Configured:**
```
INFO - KEYVAULT_ENDPOINT not configured, skipping Key Vault integration
```

⚠️ **Error:**
```
ERROR - Failed to initialize Key Vault client: ...
WARN - Application will continue without Key Vault integration
```

### Test Key Vault Access

Run the test script:
```powershell
.\test-keyvault-integration.ps1
```

## 🏗️ Architecture

```
Application Startup
    ↓
Initialize Key Vault (Global.asax.cs)
    ↓
ConfigurationProvider checks:
    1. Key Vault (KeyVaultConfigurationProvider)
    2. Environment Variables
    3. Web.config
    ↓
Application runs with retrieved configuration
```

## 🔐 Authentication Methods

| Environment | Method | How to Configure |
|-------------|--------|------------------|
| **Azure App Service** | Managed Identity | Automatic - no config needed |
| **Local Dev (VS)** | Visual Studio | Sign in to VS with Azure account |
| **Local Dev (CLI)** | Azure CLI | Run `az login` |
| **CI/CD Pipeline** | Service Principal | Set env vars: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID` |

## 📝 Common Secret Names

| Purpose | Key Vault Secret Name | Environment Variable | Web.config |
|---------|----------------------|---------------------|-----------|
| Database Connection | `CatalogDbConnectionString` | `ConnectionStrings__CatalogDBContext` | `<connectionStrings>` |
| App Insights | `ApplicationInsights--InstrumentationKey` | `APPINSIGHTS_INSTRUMENTATIONKEY` | `<appSettings>` |

## 🛠️ Troubleshooting

### "Authentication failed" in local development

**Solution:** Login with Azure CLI
```bash
az login
az account show
```

### "Key Vault access denied"

**Solution:** Request access from admin
```bash
az keyvault set-policy \
  --name kv-eshop-prototype \
  --upn your-email@company.com \
  --secret-permissions get list
```

### "Application starts but can't connect to database"

**Check:**
1. Key Vault has the connection string secret
2. Secret name matches expected name
3. Application logs show secret was retrieved
4. SQL Server firewall allows connections

### "Working locally but not in Azure"

**Check:**
1. Managed Identity is enabled for App Service
2. Key Vault access policy includes Managed Identity
3. `KEYVAULT_ENDPOINT` app setting is configured
4. Check App Service logs for errors

## 🧪 Testing

### Quick Test
```powershell
# Set Key Vault endpoint
$env:KEYVAULT_ENDPOINT = "https://kv-eshop-prototype.vault.azure.net/"

# Run test script
.\test-keyvault-integration.ps1

# Expected: 5/5 tests pass
```

### Verify Secret Retrieval
```bash
# List secrets
az keyvault secret list --vault-name kv-eshop-prototype

# Get secret value (redacted)
az keyvault secret show \
  --vault-name kv-eshop-prototype \
  --name CatalogDbConnectionString \
  --query "value" -o tsv
```

## 📚 Documentation

- **Full Guide:** [docs/KEYVAULT_INTEGRATION.md](KEYVAULT_INTEGRATION.md)
- **Manual Testing:** [docs/MANUAL_TESTING_KEYVAULT.md](MANUAL_TESTING_KEYVAULT.md)
- **Story 6:** [docs/user_stories/story6.md](user_stories/story6.md)

## 💡 Pro Tips

1. **Don't commit secrets** - Key Vault is configured, no need for secrets in code
2. **Use Azure CLI locally** - Fastest way to get started
3. **Check logs first** - Most issues show up in application logs
4. **Test without Key Vault** - App should still work with Web.config fallback
5. **Cache is your friend** - Secrets are cached after first retrieval

## 🎯 Quick Commands Cheat Sheet

```bash
# Login to Azure
az login

# Check Key Vault access
az keyvault secret list --vault-name kv-eshop-prototype

# Get a secret
az keyvault secret show --vault-name kv-eshop-prototype --name CatalogDbConnectionString

# Set a secret
az keyvault secret set --vault-name kv-eshop-prototype --name MySecret --value "MyValue"

# Check Managed Identity
az webapp identity show --resource-group rg-eshop-prototype-eastus2 --name app-eshop-prototype-eastus2

# Grant Key Vault access
az keyvault set-policy \
  --name kv-eshop-prototype \
  --object-id <principal-id> \
  --secret-permissions get list
```

## ❓ Questions?

- Check [docs/KEYVAULT_INTEGRATION.md](KEYVAULT_INTEGRATION.md) for detailed information
- Review application logs for specific errors
- Test with `test-keyvault-integration.ps1` script
- Contact the DevOps team for infrastructure issues

---

**Last Updated:** 2025-01-XX  
**Version:** 1.0  
**Story:** Story 6 - Configure Azure Key Vault Integration
