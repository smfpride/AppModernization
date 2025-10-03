# Test Case 2: Configuration Externalization and Azure Key Vault Testing

## Overview
Test cases for validating configuration externalization (Story 2) and Azure Key Vault integration (Story 6) of the eShopLegacyMVC application.

## Test Environment Setup
- **Local Environment**: Visual Studio, Local IIS Express
- **Azure Environment**: Azure Key Vault, App Service with Managed Identity
- **Tools Required**: Azure CLI, Postman, Browser developer tools

---

## Story 2: Configuration Externalization Test Cases

### TC011: Web.config Analysis and Baseline
**Objective**: Identify and document all configuration values that need externalization

**Prerequisites**: 
- Access to current Web.config file
- Understanding of application configuration requirements

**Test Steps**:
1. Review Web.config file for sensitive configuration:
   - Connection strings
   - Application Insights instrumentation key
   - API keys or secrets
   - Environment-specific settings
2. Document current configuration structure
3. Identify which values should be externalized
4. Create baseline configuration for comparison
5. Validate application runs with current configuration

**Expected Results**:
- Complete inventory of configuration values
- Clear categorization of sensitive vs. non-sensitive config
- Baseline functionality established

**Pass/Fail Criteria**: All configuration values identified and categorized

---

### TC012: Environment Variable Configuration Loading
**Objective**: Validate application can read configuration from environment variables

**Prerequisites**: 
- Application code updated to support environment variables
- Configuration provider implemented

**Test Steps**:
1. Set test environment variables:
   - `ConnectionStrings__DefaultConnection`
   - `ApplicationInsights__InstrumentationKey`
2. Remove or comment out corresponding Web.config values
3. Start application locally
4. Verify application reads environment variables correctly
5. Check application logs for configuration loading messages
6. Test database connectivity with environment variable connection string

**Expected Results**:
- Application starts successfully
- Environment variables take precedence over Web.config
- Database connection works with externalized connection string

**Pass/Fail Criteria**: Application functions with environment variable configuration

---

### TC013: Configuration Fallback Mechanism
**Objective**: Validate fallback to Web.config when environment variables are not present

**Prerequisites**: 
- Environment variables cleared
- Original Web.config values restored

**Test Steps**:
1. Clear all test environment variables
2. Ensure Web.config contains original configuration values
3. Restart application
4. Verify application starts successfully
5. Confirm Web.config values are being used
6. Test all application functionality works normally
7. Check configuration loading priority in logs

**Expected Results**:
- Application falls back to Web.config gracefully
- No configuration-related errors
- All functionality remains operational

**Pass/Fail Criteria**: Fallback mechanism works without issues

---

### TC014: Configuration Transformation Testing
**Objective**: Validate Web.config transformations work for different environments

**Prerequisites**: 
- Web.Debug.config and Web.Release.config files present
- Build configurations properly set up

**Test Steps**:
1. Build application in Debug configuration
2. Verify Debug-specific transformations applied
3. Build application in Release configuration
4. Verify Release-specific transformations applied
5. Test that sensitive values are properly transformed
6. Validate transformation preview in Visual Studio

**Expected Results**:
- Transformations apply correctly per build configuration
- Sensitive data appropriately handled in Release builds
- No transformation errors or warnings

**Pass/Fail Criteria**: Configuration transformations work as expected

---

### TC015: Local Development Environment Compatibility
**Objective**: Ensure local development workflow remains unaffected

**Prerequisites**: 
- Configuration changes implemented
- Local development environment set up

**Test Steps**:
1. Clone fresh copy of repository
2. Open solution in Visual Studio
3. Build and run application without any environment variable setup
4. Verify application runs using Web.config defaults
5. Test debugging functionality works normally
6. Validate Entity Framework Code First migrations still work
7. Check that new developer onboarding is not complicated

**Expected Results**:
- Application runs immediately after clone
- No additional setup required for local development
- All development tools continue to work

**Pass/Fail Criteria**: Local development experience unchanged

---

## Story 6: Azure Key Vault Integration Test Cases

### TC016: Azure Key Vault Setup and Access Validation
**Objective**: Validate Azure Key Vault is properly configured and accessible

**Prerequisites**: 
- Azure Key Vault created
- App Service Managed Identity enabled
- Access policies configured

**Test Steps**:
1. Navigate to Azure Portal > Key Vault
2. Verify Key Vault exists and is accessible
3. Check Access policies include App Service Managed Identity
4. Validate permissions include: Get, List for Secrets
5. Test Key Vault connectivity from Azure CLI
6. Verify Managed Identity is properly assigned to App Service

**Expected Results**:
- Key Vault accessible and properly configured
- Managed Identity has appropriate permissions
- No access policy conflicts

**Pass/Fail Criteria**: Key Vault setup and access working correctly

---

### TC017: Secret Storage and Retrieval Validation
**Objective**: Validate secrets can be stored and retrieved from Key Vault

**Prerequisites**: 
- Key Vault accessible
- Azure CLI or PowerShell access

**Test Steps**:
1. Store test secrets in Key Vault:
   - `DefaultConnection` (database connection string)
   - `ApplicationInsights--InstrumentationKey`
2. Verify secrets appear in Azure Portal
3. Test secret retrieval using Azure CLI:
   - `az keyvault secret show --vault-name <vault> --name DefaultConnection`
4. Validate secret values are encrypted at rest
5. Check audit logs for secret access attempts

**Expected Results**:
- Secrets stored successfully in Key Vault
- Values retrievable through Azure CLI
- Audit logs show access attempts

**Pass/Fail Criteria**: Secret storage and retrieval functioning

---

### TC018: Application Key Vault Integration Testing
**Objective**: Validate application can retrieve secrets from Key Vault using Managed Identity

**Prerequisites**: 
- Application code updated with Key Vault SDK
- DefaultAzureCredential implementation in place
- App Service deployed with Managed Identity

**Test Steps**:
1. Deploy application to App Service
2. Configure App Service to use Key Vault secrets:
   - Add Key Vault references in Application Settings
   - Format: `@Microsoft.KeyVault(SecretUri=<secret-identifier>)`
3. Restart App Service to apply changes
4. Monitor application startup logs
5. Verify application can connect to database using Key Vault connection string
6. Test Application Insights integration with Key Vault instrumentation key

**Expected Results**:
- Application starts successfully
- Database connection works with Key Vault connection string
- Application Insights receives telemetry
- No authentication errors in logs

**Pass/Fail Criteria**: Key Vault integration working in App Service

---

### TC019: DefaultAzureCredential Authentication Flow
**Objective**: Validate authentication chain works correctly for different environments

**Prerequisites**: 
- Azure SDK for .NET configured
- DefaultAzureCredential implementation

**Test Steps**:
1. Test authentication in different contexts:
   - Local development (Visual Studio account)
   - Azure App Service (Managed Identity)
   - Azure DevOps pipeline (Service Principal, if applicable)
2. Monitor authentication logs for each context
3. Verify fallback mechanisms work appropriately
4. Test authentication failure scenarios
5. Validate credential caching behavior

**Expected Results**:
- Authentication succeeds in all supported contexts
- Appropriate credential type used for each environment
- Graceful fallback when primary credential unavailable

**Pass/Fail Criteria**: Authentication works across all environments

---

### TC020: Key Vault Access Performance Testing
**Objective**: Validate Key Vault access doesn't significantly impact application startup

**Prerequisites**: 
- Application deployed with Key Vault integration
- Performance baseline established

**Test Steps**:
1. Measure application startup time with Key Vault integration
2. Compare against baseline startup time (Web.config only)
3. Monitor Key Vault response times using Application Insights
4. Test concurrent secret retrieval performance
5. Validate caching mechanisms for retrieved secrets
6. Check for any timeout or throttling issues

**Expected Results**:
- Startup time increase < 30 seconds
- Key Vault response times < 2 seconds
- No throttling errors under normal load
- Secret caching reduces subsequent Key Vault calls

**Pass/Fail Criteria**: Key Vault integration doesn't degrade performance significantly

---

### TC021: Security Validation and Audit Testing
**Objective**: Validate security aspects of Key Vault integration

**Prerequisites**: 
- Key Vault audit logging enabled
- Security scanning tools available

**Test Steps**:
1. Verify no hardcoded secrets remain in source code
2. Check that connection strings are not logged in plain text
3. Validate Key Vault audit logs capture all access attempts
4. Test access denial scenarios:
   - Invalid Managed Identity
   - Insufficient permissions
   - Malformed secret requests
5. Verify secrets are not exposed in application error messages
6. Check environment variables don't contain sensitive values

**Expected Results**:
- No hardcoded secrets in codebase
- Audit logs properly capture access attempts
- Access denied scenarios handled gracefully
- No sensitive data in error messages or environment variables

**Pass/Fail Criteria**: All security requirements met

---

### TC022: Disaster Recovery and Backup Testing
**Objective**: Validate Key Vault availability and backup scenarios

**Prerequisites**: 
- Key Vault backup/restore procedures understood
- Test Key Vault or backup region available

**Test Steps**:
1. Test application behavior when Key Vault is temporarily unavailable
2. Verify application graceful degradation or retry mechanisms
3. Test secret rotation scenarios if applicable
4. Validate backup Key Vault access in secondary region
5. Check application behavior during Key Vault maintenance windows
6. Test secret version management if implemented

**Expected Results**:
- Application handles Key Vault unavailability gracefully
- Retry mechanisms work appropriately
- Backup scenarios function correctly
- No application crashes during Key Vault issues

**Pass/Fail Criteria**: Application resilient to Key Vault availability issues

---

## Test Execution Summary Template

| Test Case | Status | Pass/Fail | Notes | Date Executed |
|-----------|--------|-----------|-------|---------------|
| TC011 | Pending | - | - | - |
| TC012 | Pending | - | - | - |
| TC013 | Pending | - | - | - |
| TC014 | Pending | - | - | - |
| TC015 | Pending | - | - | - |
| TC016 | Pending | - | - | - |
| TC017 | Pending | - | - | - |
| TC018 | Pending | - | - | - |
| TC019 | Pending | - | - | - |
| TC020 | Pending | - | - | - |
| TC021 | Pending | - | - | - |
| TC022 | Pending | - | - | - |

---

**Document Version**: 1.0  
**Created By**: Taylor (QA Engineer)  
**Date**: October 3, 2025  
**Related Stories**: Story 2 (Configuration Externalization), Story 6 (Azure Key Vault Integration)