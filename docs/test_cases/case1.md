# Test Case 1: Docker Container Creation and Deployment Testing

## Overview
Test cases for validating Docker containerization (Story 1) and Azure App Service deployment (Story 7) of the eShopLegacyMVC application.

## Test Environment Setup
- **Local Environment**: Windows 10/11 with Docker Desktop
- **Azure Environment**: Azure App Service for Containers (Windows)
- **Tools Required**: Docker CLI, Azure CLI, Browser for testing

---

## Story 1: Docker Container Creation Test Cases

### TC001: Dockerfile Creation and Structure Validation
**Objective**: Validate that the Dockerfile is created with proper Windows container configuration

**Prerequisites**: 
- eShopLegacyMVC source code available
- Docker Desktop installed and running

**Test Steps**:
1. Navigate to eShopLegacyMVC project root directory
2. Verify Dockerfile exists in the root directory
3. Open Dockerfile and validate the following components:
   - Uses Windows Server Core base image
   - Installs IIS and ASP.NET Framework 4.7.2
   - Copies application files correctly
   - Exposes port 80
   - Sets proper ENTRYPOINT for IIS

**Expected Results**:
- Dockerfile exists and contains all required components
- Base image is appropriate for .NET Framework 4.7.2
- Port 80 is exposed for HTTP traffic

**Pass/Fail Criteria**: All components present and properly configured

---

### TC002: Docker Image Build Process
**Objective**: Validate that the Docker image builds successfully without errors

**Prerequisites**: 
- Valid Dockerfile in place
- All application dependencies available

**Test Steps**:
1. Open command prompt in project root directory
2. Execute: `docker build -t eshoplegacymvc:test .`
3. Monitor build process for errors or warnings
4. Verify build completes successfully
5. Execute: `docker images` to confirm image exists

**Expected Results**:
- Build process completes without errors
- Image appears in local Docker registry
- Image size is reasonable (< 10GB)

**Pass/Fail Criteria**: Build succeeds and image is created

---

### TC003: Container Startup and Health Check
**Objective**: Validate that the container starts successfully and application is accessible

**Prerequisites**: 
- Docker image built successfully
- Port 80 available on host machine

**Test Steps**:
1. Execute: `docker run -d -p 8080:80 --name eshop-test eshoplegacymvc:test`
2. Wait 2 minutes for container startup
3. Execute: `docker ps` to verify container is running
4. Execute: `docker logs eshop-test` to check for startup errors
5. Open browser and navigate to `http://localhost:8080`
6. Verify application loads and displays catalog page

**Expected Results**:
- Container starts within 2 minutes
- No critical errors in container logs
- Application accessible via localhost:8080
- Catalog page displays correctly

**Pass/Fail Criteria**: Container runs and application is accessible

---

### TC004: .dockerignore Configuration Validation
**Objective**: Ensure unnecessary files are excluded from Docker build context

**Prerequisites**: 
- .dockerignore file created
- Build context understanding established

**Test Steps**:
1. Verify .dockerignore file exists in project root
2. Validate exclusion patterns include:
   - `bin/` and `obj/` directories
   - `.vs/` Visual Studio directory
   - `packages/` NuGet packages directory
   - `*.log` log files
   - `.git/` source control directory
3. Execute build with verbose output to verify excluded files
4. Check final image size is optimized

**Expected Results**:
- .dockerignore file properly configured
- Build excludes unnecessary files
- Image size is optimized

**Pass/Fail Criteria**: Unnecessary files excluded from build context

---

## Story 7: Azure App Service Deployment Test Cases

### TC005: Container Registry Push Process
**Objective**: Validate container image can be pushed to Azure Container Registry

**Prerequisites**: 
- Azure Container Registry created
- Azure CLI authenticated
- Docker image built locally

**Test Steps**:
1. Execute: `az acr login --name <registry-name>`
2. Tag image: `docker tag eshoplegacymvc:test <registry-name>.azurecr.io/eshoplegacymvc:latest`
3. Push image: `docker push <registry-name>.azurecr.io/eshoplegacymvc:latest`
4. Verify push completes successfully
5. Confirm image appears in Azure Container Registry

**Expected Results**:
- Image pushes without errors
- Image visible in Azure Container Registry
- Latest tag properly applied

**Pass/Fail Criteria**: Image successfully pushed to ACR

---

### TC006: App Service Container Configuration
**Objective**: Validate Azure App Service is properly configured for container deployment

**Prerequisites**: 
- Azure App Service created
- Container image available in ACR
- App Service Plan supports Windows containers

**Test Steps**:
1. Navigate to Azure Portal > App Service
2. Verify Container settings:
   - Image Source: Azure Container Registry
   - Registry: Correct ACR selected
   - Image: eshoplegacymvc
   - Tag: latest
3. Verify Configuration settings:
   - Platform: Windows
   - Continuous Deployment: Enabled (optional)
4. Check Application Settings for environment variables
5. Save configuration changes

**Expected Results**:
- Container settings properly configured
- App Service recognizes ACR image
- Platform set to Windows

**Pass/Fail Criteria**: All container settings correctly configured

---

### TC007: Azure App Service Deployment Validation
**Objective**: Validate successful deployment and startup of container in App Service

**Prerequisites**: 
- App Service configured with container settings
- Environment variables configured
- Database connection available

**Test Steps**:
1. Monitor deployment in Azure Portal > App Service > Deployment Center
2. Check deployment logs for successful container pull
3. Monitor Application Logs for startup messages
4. Verify application starts without critical errors
5. Check App Service URL accessibility
6. Validate HTTP response code (200 OK)

**Expected Results**:
- Container deploys successfully
- Application starts without critical errors
- App Service URL returns 200 OK
- Startup time < 5 minutes

**Pass/Fail Criteria**: Application successfully deployed and accessible

---

### TC008: Public URL Functionality Test
**Objective**: Validate complete application functionality through Azure public URL

**Prerequisites**: 
- Application deployed to App Service
- Database connection established
- All services healthy

**Test Steps**:
1. Navigate to App Service public URL
2. Verify home page loads completely
3. Test catalog page displays products
4. Validate product images load correctly
5. Test brand and type filtering functionality
6. Verify Web API endpoints respond correctly
7. Check browser console for JavaScript errors

**Expected Results**:
- All pages load without errors
- Product catalog displays correctly
- Filtering functionality works
- No critical JavaScript errors

**Pass/Fail Criteria**: All core functionality accessible via public URL

---

### TC009: Container Performance and Resource Utilization
**Objective**: Validate container performance meets acceptable thresholds

**Prerequisites**: 
- Application running in App Service
- Application Insights configured (if available)

**Test Steps**:
1. Monitor App Service Metrics for:
   - CPU utilization
   - Memory usage
   - Response times
   - Request rates
2. Load test with 10 concurrent users for 5 minutes
3. Check container restart frequency
4. Monitor application logs for performance warnings
5. Validate memory usage remains stable

**Expected Results**:
- CPU usage < 80% under normal load
- Memory usage stable without leaks
- Response times < 3 seconds
- No frequent container restarts

**Pass/Fail Criteria**: Performance metrics within acceptable ranges

---

### TC010: Environment Variable Configuration Test
**Objective**: Validate environment variables are properly configured and accessible

**Prerequisites**: 
- App Service configured with environment variables
- Application code updated to read environment variables

**Test Steps**:
1. Configure test environment variables in App Service settings
2. Restart App Service to apply changes
3. Use Kudu console to verify environment variables are set
4. Test application configuration loading
5. Verify fallback to default values works when needed
6. Check application logs for configuration-related messages

**Expected Results**:
- Environment variables properly set in App Service
- Application reads variables correctly
- Fallback mechanism works for missing variables

**Pass/Fail Criteria**: Configuration system works as expected

---

## Test Execution Summary Template

| Test Case | Status | Pass/Fail | Notes | Date Executed |
|-----------|--------|-----------|-------|---------------|
| TC001 | Pending | - | - | - |
| TC002 | Pending | - | - | - |
| TC003 | Pending | - | - | - |
| TC004 | Pending | - | - | - |
| TC005 | Pending | - | - | - |
| TC006 | Pending | - | - | - |
| TC007 | Pending | - | - | - |
| TC008 | Pending | - | - | - |
| TC009 | Pending | - | - | - |
| TC010 | Pending | - | - | - |

---

**Document Version**: 1.0  
**Created By**: Taylor (QA Engineer)  
**Date**: October 3, 2025  
**Related Stories**: Story 1 (Docker Containerization), Story 7 (Azure App Service Deployment)