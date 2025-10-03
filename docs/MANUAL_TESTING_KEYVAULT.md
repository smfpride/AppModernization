# Manual Testing Guide for Story 6: Azure Key Vault Integration

This guide provides step-by-step instructions for manually testing the Azure Key Vault integration.

## Prerequisites

1. Azure infrastructure must be deployed using `scripts/Deploy-AzureInfrastructure.ps1`
2. Azure CLI installed and configured
3. Access to the Azure subscription and Key Vault

## Test Scenarios

### Scenario 1: Verify Infrastructure Setup

**Objective**: Confirm that Azure Key Vault is properly configured with secrets

**Steps**:
1. Open PowerShell or Bash terminal
2. Login to Azure CLI:
   ```bash
   az login
   ```

3. Verify Key Vault exists:
   ```bash
   az keyvault show --name kv-eshop-prototype-eastus2
   ```
   Expected: Should display Key Vault details

4. List secrets in Key Vault:
   ```bash
   az keyvault secret list --vault-name kv-eshop-prototype-eastus2 --query "[].name"
   ```
   Expected: Should show at least `CatalogDbConnectionString`

5. Verify secret value (redacted):
   ```bash
   az keyvault secret show --vault-name kv-eshop-prototype-eastus2 --name CatalogDbConnectionString --query "value"
   ```
   Expected: Should display a SQL connection string

**Pass Criteria**: All commands succeed and secret exists

---

### Scenario 2: Local Development with Azure CLI

**Objective**: Test Key Vault integration in local development environment

**Steps**:
1. Ensure Azure CLI is authenticated (from Scenario 1)

2. Set the Key Vault endpoint environment variable:
   
   **PowerShell:**
   ```powershell
   $env:KEYVAULT_ENDPOINT = "https://kv-eshop-prototype-eastus2.vault.azure.net/"
   ```
   
   **Bash:**
   ```bash
   export KEYVAULT_ENDPOINT="https://kv-eshop-prototype-eastus2.vault.azure.net/"
   ```

3. Run the test script:
   ```powershell
   .\test-keyvault-integration.ps1
   ```

4. Verify test results:
   - Azure CLI Authentication: PASS
   - Key Vault Exists: PASS
   - Connection String Secret: PASS
   - DefaultAzureCredential Setup: PASS
   - Local Development Fallback: PASS

**Pass Criteria**: All tests pass (5/5)

---

### Scenario 3: Application Startup with Key Vault

**Objective**: Verify the application initializes Key Vault correctly

**Steps**:
1. Set the Key Vault endpoint (from Scenario 2)

2. Review the application startup logs (in log4net output)

3. Look for these log entries:
   ```
   INFO - Initializing Key Vault integration with endpoint: https://kv-eshop-prototype-eastus2.vault.azure.net/
   INFO - Key Vault client initialized successfully
   INFO - Application starting with configuration: Environment: Local, ConnectionString: Configured, AppInsights: Configured
   ```

4. Verify no error messages about Key Vault initialization

**Pass Criteria**: Application starts successfully with Key Vault logs

---

### Scenario 4: Connection String Retrieval

**Objective**: Verify the application retrieves connection string from Key Vault

**Steps**:
1. Set the Key Vault endpoint (from Scenario 2)

2. Remove local connection string environment variable (if set):
   ```powershell
   $env:ConnectionStrings__CatalogDBContext = $null
   ```

3. Start the application

4. Check logs for:
   ```
   DEBUG - Retrieving secret from Key Vault: CatalogDbConnectionString
   INFO - Successfully retrieved secret: CatalogDbConnectionString
   ```

5. Verify the application connects to the database successfully

**Pass Criteria**: Application retrieves connection string from Key Vault and connects to database

---

### Scenario 5: Fallback to Web.config

**Objective**: Verify local development fallback works when Key Vault is not configured

**Steps**:
1. Clear the Key Vault endpoint:
   ```powershell
   $env:KEYVAULT_ENDPOINT = $null
   ```

2. Clear connection string environment variable:
   ```powershell
   $env:ConnectionStrings__CatalogDBContext = $null
   ```

3. Start the application

4. Check logs for:
   ```
   INFO - KEYVAULT_ENDPOINT not configured, skipping Key Vault integration
   INFO - Application starting with configuration: Environment: Local, ConnectionString: Configured, AppInsights: ...
   ```

5. Verify the application uses the Web.config connection string (LocalDB)

**Pass Criteria**: Application falls back to Web.config and starts successfully

---

### Scenario 6: Azure App Service with Managed Identity

**Objective**: Test Key Vault integration in Azure App Service using Managed Identity

**Prerequisites**:
- Application deployed to Azure App Service
- Managed Identity enabled for App Service
- Key Vault access policy configured for Managed Identity

**Steps**:
1. Verify App Service configuration:
   ```bash
   az webapp config appsettings list \
     --resource-group rg-eshop-prototype-eastus2 \
     --name app-eshop-prototype-eastus2 \
     --query "[?name=='KEYVAULT_ENDPOINT'].value"
   ```
   Expected: Should show the Key Vault endpoint

2. Check Managed Identity is assigned:
   ```bash
   az webapp identity show \
     --resource-group rg-eshop-prototype-eastus2 \
     --name app-eshop-prototype-eastus2
   ```
   Expected: Should show principalId and tenantId

3. Verify Key Vault access policy:
   ```bash
   az keyvault show \
     --name kv-eshop-prototype-eastus2 \
     --query "properties.accessPolicies[?objectId=='<principal-id>'].permissions"
   ```
   Expected: Should show get and list permissions for secrets

4. Access the application in browser:
   ```
   https://app-eshop-prototype-eastus2.azurewebsites.net
   ```

5. Check application logs in Azure Portal:
   - Navigate to App Service > Logs > App Service Logs
   - Look for Key Vault initialization messages
   - Verify no authentication errors

6. Test application functionality:
   - Browse catalog items
   - Verify database operations work
   - Check that Application Insights receives telemetry

**Pass Criteria**: Application runs successfully in Azure using Managed Identity to access Key Vault

---

### Scenario 7: Error Handling - Invalid Key Vault Endpoint

**Objective**: Verify application handles invalid Key Vault configuration gracefully

**Steps**:
1. Set an invalid Key Vault endpoint:
   ```powershell
   $env:KEYVAULT_ENDPOINT = "https://invalid-vault.vault.azure.net/"
   ```

2. Start the application

3. Check logs for:
   ```
   ERROR - Failed to initialize Key Vault client: ...
   WARN - Application will continue without Key Vault integration
   ```

4. Verify the application continues to start and falls back to environment variables or Web.config

**Pass Criteria**: Application logs the error but continues to run using fallback configuration

---

### Scenario 8: Performance - Key Vault Access Time

**Objective**: Measure Key Vault access performance

**Steps**:
1. Set the Key Vault endpoint (from Scenario 2)

2. Start the application and note startup time

3. Review logs for timing information

4. Expected behavior:
   - First Key Vault access: 1-3 seconds
   - Subsequent accesses: Cached, negligible time
   - Total startup time increase: < 10 seconds

**Pass Criteria**: Key Vault access doesn't significantly impact application startup time

---

## Test Results Template

| Scenario | Status | Notes | Tester | Date |
|----------|--------|-------|--------|------|
| 1. Verify Infrastructure Setup | ⬜ | | | |
| 2. Local Development with Azure CLI | ⬜ | | | |
| 3. Application Startup with Key Vault | ⬜ | | | |
| 4. Connection String Retrieval | ⬜ | | | |
| 5. Fallback to Web.config | ⬜ | | | |
| 6. Azure App Service with Managed Identity | ⬜ | | | |
| 7. Error Handling - Invalid Endpoint | ⬜ | | | |
| 8. Performance - Key Vault Access Time | ⬜ | | | |

**Legend**: ⬜ Not Tested | ✅ Pass | ❌ Fail

## Troubleshooting

### Issue: Azure CLI Authentication Failed

**Solution**: 
```bash
az login
az account show
```

### Issue: Key Vault Access Denied

**Solution**:
```bash
# Check your access
az keyvault secret list --vault-name kv-eshop-prototype-eastus2

# If access denied, have admin grant permissions
az keyvault set-policy \
  --name kv-eshop-prototype-eastus2 \
  --upn your-email@company.com \
  --secret-permissions get list
```

### Issue: Application Can't Connect to Database

**Symptoms**: Application starts but database operations fail

**Checks**:
1. Verify connection string is retrieved:
   - Check logs for "Successfully retrieved secret: CatalogDbConnectionString"
2. Test connection string manually
3. Verify SQL Server firewall allows connections
4. Check if Managed Identity has SQL permissions

### Issue: Managed Identity Not Working in Azure

**Symptoms**: Application works locally but fails in Azure

**Checks**:
1. Verify Managed Identity is enabled:
   ```bash
   az webapp identity show --resource-group rg-eshop-prototype-eastus2 --name app-eshop-prototype-eastus2
   ```

2. Verify Key Vault access policy includes the Managed Identity:
   ```bash
   az keyvault show --name kv-eshop-prototype-eastus2 --query "properties.accessPolicies"
   ```

3. Check App Service logs for authentication errors

## Sign-Off

**Developer**: _________________ Date: _______

**QA Engineer**: _________________ Date: _______

**Notes**:
