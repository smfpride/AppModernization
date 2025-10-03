# Story 1: Create Docker Container for eShopLegacyMVC

## Status
Ready for QA

## Story

**As a** DevOps Engineer  
**I want** to containerize the eShopLegacyMVC application using Windows containers  
**so that** the application can be deployed to Azure App Service for Containers

## Acceptance Criteria

1. Dockerfile created for .NET Framework 4.7.2 Windows container
2. .dockerignore file configured to exclude unnecessary files
3. Container builds successfully with all dependencies included
4. Application starts and runs within the container locally
5. Container exposes port 80 for HTTP traffic
6. Basic environment variable support configured for future Azure deployment

## Dev Notes

- Use Windows Server Core base image
- Include IIS and ASP.NET runtime
- Reference Architecture Decision ADR001 for containerization strategy
- Estimated time: 1-1.5 hours from 8-hour roadmap

## QA Results

**Status**: Ready for QA  
**QA Engineer**: Taylor  
**Test Plan**: [Master Test Plan](../test_plans/plan1.md)  
**Test Cases**: [Container Stories Test Cases](../test_cases/case1.md) - TC001 through TC004  
**Priority**: High - Critical for containerization foundation  

### Test Coverage
- Dockerfile creation and validation
- Docker image build process
- Container startup and health checks
- .dockerignore configuration
- Windows container compatibility

### Notes
- This story is fundamental to the modernization approach
- All containerization tests must pass before proceeding to deployment (Story 7)
- Special attention needed for Windows container startup times and resource usage


## Tasks / Subtasks

- [ ] Create Dockerfile with Windows base image
- [ ] Configure IIS and ASP.NET in container
- [ ] Create .dockerignore file
- [ ] Test local container build
- [ ] Validate application startup in container
- [ ] Document container configuration

## Definition of Done
- [ ] Container builds without errors
- [ ] Application accessible via localhost when container is running
- [ ] Dockerfile follows Windows container best practices
- [ ] Container startup time is reasonable (< 2 minutes)