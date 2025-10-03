# Story 4: Migrate Database Schema to Azure SQL Database

## Status
Ready for QA

## Story

**As a** Database Developer  
**I want** to migrate the eShopLegacyMVC database schema from LocalDB to Azure SQL Database  
**so that** the application can connect to a cloud-hosted database

## Acceptance Criteria

1. Database schema exported from LocalDB and analyzed for compatibility
2. Schema created successfully in Azure SQL Database
3. All tables, indexes, and constraints migrated correctly
4. Entity Framework Code First migrations work against Azure SQL Database
5. Database connection string updated for Azure SQL Database format
6. Basic connectivity test from development environment successful

## Dev Notes

- Use SQL Server Management Studio or Azure Data Studio for migration
- Test Entity Framework migrations against Azure SQL Database
- Update connection string format for Azure SQL Database
- Estimated time: 1.5 hours from 8-hour roadmap

## QA Results

**Status**: Ready for QA  
**QA Engineer**: Taylor  
**Test Plan**: [Master Test Plan](../test_plans/plan1.md)  
**Test Cases**: [Database Migration Test Cases](../test_cases/case3.md) - TC023 through TC027  
**Priority**: Critical - Data integrity is paramount  

### Test Coverage
- LocalDB schema analysis and export
- Azure SQL Database compatibility validation
- Schema creation in Azure SQL Database
- Entity Framework connection testing
- Database security and access validation

### Notes
- Schema migration must be completed before data migration (Story 5)
- Data integrity and Entity Framework compatibility are critical success factors
- Thorough security testing required for database access


## Tasks / Subtasks

- [ ] Export LocalDB schema using SSMS
- [ ] Analyze schema for Azure SQL Database compatibility
- [ ] Create database schema in Azure SQL Database
- [ ] Test Entity Framework migrations
- [ ] Update connection string format
- [ ] Validate database connectivity

## Definition of Done
- [ ] Database schema successfully created in Azure SQL Database
- [ ] Entity Framework can connect and perform CRUD operations
- [ ] All original tables and relationships preserved
- [ ] Connection resilience patterns implemented