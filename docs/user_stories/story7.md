# Story 7: Deploy Container to Azure App Service

## Status
DevOps Complete

## Story

**As a** DevOps Engineer  
**I want** to deploy the containerized eShopLegacyMVC application to Azure App Service  
**so that** the application is accessible via a public URL in Azure

## Acceptance Criteria

1. Container image pushed to Azure Container Registry or Docker Hub
2. App Service configured to pull and run the container image
3. Environment variables configured for Azure SQL Database connection
4. Application starts successfully in Azure App Service
5. Health check endpoint responds successfully
6. Basic functionality accessible via public Azure URL

## Dev Notes

- Use Azure Container Registry for hosting container images
- Configure App Service container settings
- Test deployment and startup process
- Estimated time: 1 hour from 8-hour roadmap

## QA Results

**Status**: DevOps Complete ✅  
**DevOps Engineer**: Alex  
**Deployment Date**: October 5, 2025  
**Application URL**: https://app-eshop-prototype-eastus2.azurewebsites.net  
**QA Engineer**: Taylor (Ready for handoff)  
**Test Plan**: [Master Test Plan](../test_plans/plan1.md)  
**Test Cases**: [Container Stories Test Cases](../test_cases/case1.md) - TC005 through TC010  
**Priority**: High - Final deployment validation

### ✅ DevOps Implementation Completed
- **Container Registry**: acreshopprototype.azurecr.io ✅
- **App Service Deployment**: app-eshop-prototype-eastus2 ✅
- **Database Integration**: Key Vault references configured ✅
- **Security**: Managed Identity authentication ✅
- **Public URL**: HTTPS endpoint active ✅
- **Status**: HTTP 200 OK responses ✅  

### Test Coverage
- Container Registry push process
- App Service container configuration
- Azure App Service deployment validation
- Public URL functionality testing
- Container performance and resource utilization
- Environment variable configuration

### Notes
- Dependent on successful completion of Story 1 (containerization)
- Public URL accessibility is critical success factor
- Performance under load must meet requirements
- Environment variable configuration is critical for cloud operation


## Tasks / Subtasks

- [ ] Push container image to Azure Container Registry
- [ ] Configure App Service container deployment settings
- [ ] Set up environment variables for cloud configuration
- [ ] Deploy container to App Service
- [ ] Monitor deployment logs for successful startup
- [ ] Test application accessibility via public URL

## Definition of Done
- [ ] Application successfully deployed to Azure App Service
- [ ] Container starts without errors
- [ ] Application accessible via Azure-provided URL
- [ ] Basic catalog functionality works in cloud environment