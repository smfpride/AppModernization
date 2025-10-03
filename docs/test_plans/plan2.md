# Test Plan 2: Story 4 Database Schema Migration QA

## Overview
**Story**: Database Schema Migration from LocalDB to Azure SQL Database  
**QA Engineer**: Taylor  
**Priority**: Critical (Data integrity is paramount)  
**Test Start Date**: October 3, 2025  
**Expected Duration**: 2-3 days  

## Scope
This test plan validates the complete database schema migration from LocalDB to Azure SQL Database for the eShopLegacyMVC application, ensuring all acceptance criteria are met.

## Acceptance Criteria Validation
1. ✅ Database schema exported from LocalDB and analyzed for compatibility
2. ✅ Schema created successfully in Azure SQL Database  
3. ✅ All tables, indexes, and constraints migrated correctly
4. ✅ Entity Framework Code First migrations work against Azure SQL Database
5. ✅ Database connection string updated for Azure SQL Database format
6. ✅ Basic connectivity test from development environment successful

## Test Strategy
- **Static Analysis**: Review implemented code, connection strings, and configuration files
- **Functional Testing**: Execute all test cases TC023-TC027 systematically
- **Integration Testing**: Validate Entity Framework integration with Azure SQL Database
- **Security Testing**: Verify database access controls and connection security
- **Regression Testing**: Ensure existing functionality remains intact

## Risk Assessment
- **High Risk**: Data integrity during schema migration
- **Medium Risk**: Entity Framework compatibility with Azure SQL Database
- **Medium Risk**: Connection string configuration and environment variables
- **Low Risk**: Performance impact of connection resilience patterns

## Test Environment
- **Development**: Local eShopLegacyMVC application with Entity Framework 6.2.0
- **Database**: Azure SQL Database (schema migration target)
- **Tools**: Visual Studio 2022, SSMS, Azure Data Studio, MSBuild
- **Validation**: Unit tests, integration tests, manual testing

## Pre-Test Validation
Before executing test cases, validate:
- [x] Project compiles successfully without errors
- [x] All required files (ConfigurationProvider, AzureSqlConnectionResilienceProvider) are present
- [x] Entity Framework context configured correctly
- [ ] LocalDB instance available with sample data
- [ ] Azure SQL Database provisioned and accessible

## Test Cases Summary
- **TC023**: LocalDB Schema Analysis and Export (Priority: High)
- **TC024**: Azure SQL Database Compatibility Analysis (Priority: High)  
- **TC025**: Azure SQL Database Schema Creation (Priority: Critical)
- **TC026**: Entity Framework Connection Testing (Priority: Critical)
- **TC027**: Database Security and Access Validation (Priority: Medium)

## Exit Criteria
- All test cases executed and passing
- Schema successfully migrated to Azure SQL Database
- Entity Framework fully functional with cloud database
- Connection resilience patterns validated
- No critical or high-severity defects remaining
- Story 4 marked as "QA Approved"

## Dependencies
- Azure SQL Database provisioning completed
- Database firewall rules configured
- Connection string environment variables available
- LocalDB instance with sample data for testing

## Deliverables
- Test execution report with pass/fail status
- Defect report (if any issues found)
- Updated Story 4 status and QA results
- Recommendations for production deployment

## Notes
- This schema migration is a prerequisite for Story 5 (data migration)
- Entity Framework compatibility is critical for application functionality
- Connection resilience patterns must be thoroughly tested
- Security configuration validation is mandatory before production deployment