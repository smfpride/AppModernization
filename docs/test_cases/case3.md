# Test Case 3: Database Migration Testing (Schema and Data)

## Overview
Test cases for validating database schema migration (Story 4) and data migration (Story 5) from LocalDB to Azure SQL Database for the eShopLegacyMVC application.

## Test Environment Setup
- **Local Environment**: SQL Server Management Studio, LocalDB instance
- **Azure Environment**: Azure SQL Database, Azure Data Studio
- **Tools Required**: SSMS, Azure Data Studio, BCP utility, Entity Framework tools

---

## Story 4: Database Schema Migration Test Cases

### TC023: LocalDB Schema Analysis and Export
**Objective**: Analyze and export the current LocalDB schema for migration planning

**Prerequisites**: 
- LocalDB instance running with eShopLegacyMVC database
- SQL Server Management Studio installed
- Database contains sample data

**Test Steps**:
1. Connect to LocalDB instance using SSMS
2. Generate database schema script:
   - Right-click database > Tasks > Generate Scripts
   - Select "Script entire database and all database objects"
   - Save script to file
3. Document current schema structure:
   - Tables: CatalogItems, CatalogBrands, CatalogTypes
   - Relationships and foreign keys
   - Indexes and constraints
   - Data types and sizes
4. Verify Entity Framework model matches database schema
5. Check for any custom database objects (triggers, stored procedures)

**Expected Results**:
- Complete schema script generated successfully
- All tables, relationships, and constraints documented
- Entity Framework model alignment confirmed

**Pass/Fail Criteria**: Schema successfully exported and documented

---

### TC024: Azure SQL Database Compatibility Analysis
**Objective**: Validate LocalDB schema compatibility with Azure SQL Database

**Prerequisites**: 
- LocalDB schema script available
- Azure SQL Database best practices understood

**Test Steps**:
1. Review schema script for Azure SQL Database compatibility:
   - Check for unsupported data types
   - Validate index configurations
   - Review constraint definitions
   - Check for deprecated features
2. Use SQL Server Data Tools (SSDT) for compatibility analysis if available
3. Identify any required schema modifications
4. Document compatibility issues and required changes
5. Create modified schema script for Azure SQL Database

**Expected Results**:
- All compatibility issues identified
- Required modifications documented
- Azure SQL Database compatible schema script created

**Pass/Fail Criteria**: Schema verified compatible with Azure SQL Database

---

### TC025: Azure SQL Database Schema Creation
**Objective**: Successfully create database schema in Azure SQL Database

**Prerequisites**: 
- Azure SQL Database provisioned
- Database connection established
- Compatible schema script prepared

**Test Steps**:
1. Connect to Azure SQL Database using SSMS or Azure Data Studio
2. Execute schema creation script
3. Monitor execution for errors or warnings
4. Verify all tables created successfully:
   - CatalogItems table with correct columns
   - CatalogBrands table structure
   - CatalogTypes table structure
5. Validate foreign key relationships created correctly
6. Check indexes and constraints applied properly
7. Verify database collation settings match requirements

**Expected Results**:
- Schema script executes without errors
- All tables, relationships, and constraints created
- Database structure matches LocalDB schema

**Pass/Fail Criteria**: Schema successfully created in Azure SQL Database

---

### TC026: Entity Framework Connection Testing
**Objective**: Validate Entity Framework can connect to Azure SQL Database

**Prerequisites**: 
- Azure SQL Database schema created
- Connection string configured
- eShopLegacyMVC application updated

**Test Steps**:
1. Update connection string in application to point to Azure SQL Database
2. Test database connection from application:
   - Run application locally
   - Check for connection errors in logs
   - Verify Entity Framework context initializes
3. Test Entity Framework operations:
   - Create test entity and save to database
   - Read entity back from database
   - Update entity and verify changes persist
   - Delete entity and confirm removal
4. Validate Code First migrations work against Azure SQL Database
5. Check connection resilience and retry policies

**Expected Results**:
- Application connects successfully to Azure SQL Database
- All CRUD operations work correctly
- Entity Framework migrations function properly

**Pass/Fail Criteria**: Entity Framework fully functional with Azure SQL Database

---

### TC027: Database Security and Access Validation
**Objective**: Validate database security configuration and access controls

**Prerequisites**: 
- Azure SQL Database configured
- Firewall rules established
- Authentication methods configured

**Test Steps**:
1. Test database connectivity from different sources:
   - Local development machine
   - Azure App Service (once deployed)
   - Azure Data Studio from local machine
2. Validate firewall rules:
   - Confirm application can connect
   - Verify unauthorized access is blocked
3. Test authentication methods:
   - SQL Server authentication
   - Azure Active Directory authentication (if configured)
   - Managed Identity authentication (if configured)
4. Verify connection encryption is enforced
5. Check audit logging configuration if enabled

**Expected Results**:
- Authorized connections succeed
- Unauthorized connections properly blocked
- Connection encryption working
- Authentication methods functioning correctly

**Pass/Fail Criteria**: Database security properly configured

---

## Story 5: Database Data Migration Test Cases

### TC028: LocalDB Data Export and Analysis
**Objective**: Export and analyze current data for migration planning

**Prerequisites**: 
- LocalDB contains sample catalog data
- Export tools available (SSMS, BCP)

**Test Steps**:
1. Connect to LocalDB and analyze current data:
   - Count records in each table
   - Check data quality and consistency
   - Identify any special characters or encoding issues
   - Document data relationships
2. Export data using multiple methods:
   - SSMS Export Data Wizard
   - BCP utility for bulk export
   - Generate INSERT scripts
3. Validate exported data files:
   - Check file sizes and record counts
   - Verify data integrity in export files
   - Test import process on test database
4. Create data migration plan with preferred method

**Expected Results**:
- All data successfully exported
- Data integrity maintained in export files
- Optimal migration method identified

**Pass/Fail Criteria**: Data export completed successfully with integrity checks passed

---

### TC029: Azure SQL Database Data Import Process
**Objective**: Import LocalDB data into Azure SQL Database

**Prerequisites**: 
- Azure SQL Database schema created
- Data export files prepared
- Import method selected

**Test Steps**:
1. Prepare Azure SQL Database for data import:
   - Ensure tables are empty
   - Disable constraints temporarily if needed
   - Set appropriate database performance tier for import
2. Import data using selected method:
   - Execute import process
   - Monitor import progress and performance
   - Check for import errors or warnings
3. Validate import completion:
   - Count records in each target table
   - Compare record counts with source database
   - Check for any truncated or malformed data
4. Re-enable constraints and validate relationships
5. Verify foreign key integrity

**Expected Results**:
- All data imported successfully
- Record counts match between source and target
- Data integrity and relationships maintained

**Pass/Fail Criteria**: 100% data migration with no data loss or corruption

---

### TC030: Data Integrity and Quality Validation
**Objective**: Comprehensive validation of migrated data quality and integrity

**Prerequisites**: 
- Data migration completed
- Original data export available for comparison

**Test Steps**:
1. Perform record count validation:
   - Compare record counts for each table
   - Verify no duplicate records created
   - Check for missing records
2. Data quality validation:
   - Sample and compare individual records
   - Verify special characters migrated correctly
   - Check date/time formats and values
   - Validate numeric precision and scale
3. Relationship integrity validation:
   - Test all foreign key relationships
   - Verify referential integrity constraints
   - Check for orphaned records
4. Business logic validation:
   - Test catalog item relationships to brands/types
   - Verify product image references are valid
   - Check business rules and constraints
5. Performance validation:
   - Execute common queries and compare performance
   - Check index effectiveness
   - Validate query execution plans

**Expected Results**:
- 100% record count match
- All data quality checks pass
- Referential integrity maintained
- Query performance acceptable

**Pass/Fail Criteria**: Complete data integrity with no quality issues

---

### TC031: Application Data Access Testing
**Objective**: Validate application can successfully access and display migrated data

**Prerequisites**: 
- Data migration completed
- Application configured for Azure SQL Database
- Application deployed and running

**Test Steps**:
1. Test catalog page functionality:
   - Load catalog page and verify products display
   - Check product images load correctly
   - Verify product names, descriptions, and prices
2. Test filtering functionality:
   - Filter by brand and verify correct products shown
   - Filter by type and verify correct products shown
   - Test combination filters
3. Test Web API endpoints:
   - Get all catalog items via API
   - Get specific catalog item by ID
   - Get brands and types lists
   - Verify JSON response format and content
4. Test data relationships:
   - Verify products correctly associated with brands
   - Verify products correctly associated with types
   - Check foreign key relationships work in queries
5. Perform user acceptance testing scenarios

**Expected Results**:
- All catalog functionality works correctly
- Data displays accurately on web pages
- API endpoints return correct data
- No data-related errors in application

**Pass/Fail Criteria**: Application fully functional with migrated data

---

### TC032: Database Performance and Optimization Testing
**Objective**: Validate database performance meets requirements after migration

**Prerequisites**: 
- Data migration completed
- Application load testing tools available
- Performance baseline established

**Test Steps**:
1. Establish performance baseline:
   - Measure query response times for common operations
   - Monitor database resource utilization
   - Document current performance metrics
2. Load testing scenarios:
   - Simulate 10 concurrent users browsing catalog
   - Execute high-volume data retrieval operations
   - Test concurrent read/write operations
3. Monitor Azure SQL Database metrics:
   - CPU utilization
   - Memory usage
   - I/O performance
   - Connection pool usage
4. Optimize as needed:
   - Review and optimize slow queries
   - Consider additional indexes if needed
   - Validate database tier sizing
5. Retest after optimizations

**Expected Results**:
- Query response times < 2 seconds for standard operations
- Database utilization within acceptable ranges
- No performance degradation under normal load

**Pass/Fail Criteria**: Database performance meets or exceeds requirements

---

### TC033: Backup and Recovery Validation
**Objective**: Validate Azure SQL Database backup and recovery capabilities

**Prerequisites**: 
- Azure SQL Database with migrated data
- Understanding of Azure SQL backup policies

**Test Steps**:
1. Verify automatic backup configuration:
   - Check backup retention policy
   - Verify backup schedule and frequency
   - Confirm geo-redundant backup settings
2. Test point-in-time restore capability:
   - Make test changes to database
   - Perform point-in-time restore to before changes
   - Verify data restored correctly
3. Test backup export/import:
   - Export database backup to storage account
   - Import backup to test database
   - Verify data integrity after import
4. Document recovery procedures:
   - Create step-by-step recovery documentation
   - Test documented procedures
   - Validate recovery time objectives (RTO)

**Expected Results**:
- Automatic backups properly configured
- Point-in-time restore works correctly
- Backup export/import processes functional
- Recovery procedures documented and tested

**Pass/Fail Criteria**: Backup and recovery capabilities fully validated

---

## Test Execution Summary Template

| Test Case | Status | Pass/Fail | Notes | Date Executed |
|-----------|--------|-----------|-------|---------------|
| TC023 | Pending | - | - | - |
| TC024 | Pending | - | - | - |
| TC025 | Pending | - | - | - |
| TC026 | Pending | - | - | - |
| TC027 | Pending | - | - | - |
| TC028 | Pending | - | - | - |
| TC029 | Pending | - | - | - |
| TC030 | Pending | - | - | - |
| TC031 | Pending | - | - | - |
| TC032 | Pending | - | - | - |
| TC033 | Pending | - | - | - |

---

**Document Version**: 1.0  
**Created By**: Taylor (QA Engineer)  
**Date**: October 3, 2025  
**Related Stories**: Story 4 (Database Schema Migration), Story 5 (Database Data Migration)