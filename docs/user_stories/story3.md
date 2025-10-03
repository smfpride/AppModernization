# Story 3: Provision Azure Infrastructure Resources

## Status
Ready for QA

## Story

**As a** DevOps Engineer  
**I want** to create the core Azure infrastructure for hosting the eShopLegacyMVC application  
**so that** we have the foundation services ready for application deployment

## Acceptance Criteria

1. Azure Resource Group created with consistent naming convention
2. Azure SQL Server and Database provisioned (S2 Standard tier)
3. Azure Key Vault created with appropriate access policies
4. Azure App Service Plan created (S1 Standard for Windows containers)
5. Azure App Service for Containers created with Managed Identity enabled
6. Basic firewall rules configured for Azure SQL Database
7. All resources tagged appropriately for cost tracking

## Dev Notes

- Use Azure CLI or ARM templates for consistent provisioning
- Reference `docs/architecture/adr002.md` for specific service configurations
- Follow naming conventions: rg-eshop-prototype-eastus2
- Estimated time: 1 hour from 8-hour roadmap

## QA Results

**Status**: Ready for QA  
**QA Engineer**: Taylor  
**Test Plan**: [Master Test Plan](../test_plans/plan1.md)  
**Test Cases**: [Infrastructure Test Cases](../test_cases/case4.md) - TC034 through TC044  
**Priority**: High - Foundation for all other Azure services  

### Test Coverage
- Resource Group creation and configuration
- Azure SQL Server and Database provisioning
- Key Vault setup and security configuration
- App Service Plan and App Service creation
- Network connectivity and security testing
- Cost management and budget validation

### Notes
- All infrastructure must be properly provisioned before application deployment
- Security configuration is critical - firewall rules and access policies must be validated
- Cost monitoring and alerts should be configured from the start


## Tasks / Subtasks

- [ ] Create resource group
- [ ] Provision Azure SQL Server and Database
- [ ] Create Azure Key Vault
- [ ] Create App Service Plan for Windows containers
- [ ] Create App Service with container support
- [ ] Configure firewall rules and access policies
- [ ] Validate all resources are accessible

## Definition of Done
- [ ] All Azure resources provisioned successfully
- [ ] Resource naming follows established conventions
- [ ] Basic connectivity tests pass
- [ ] Cost alerts configured for resource group