# Story 10: Containerize and Deploy .NET 8 Application to Azure

## Status
Backlog

## Story

**As a** DevOps Engineer  
**I want** to containerize the modernized .NET 8 eShopLegacyMVC application and deploy it to Azure PaaS services  
**so that** the application can run efficiently in a cloud-native Linux container environment

## Acceptance Criteria

1. New Dockerfile created for .NET 8 Linux-based container
2. Container image builds successfully and runs locally
3. Azure Container Registry configured for image storage
4. Azure App Service updated to support .NET 8 Linux containers
5. Application deployed successfully to Azure App Service
6. All existing Azure integrations (SQL Database, Key Vault) working with new container

## Dev Notes

### Container Platform Changes:
- **Base Image**: Windows Server Core → Linux (mcr.microsoft.com/dotnet/aspnet:8.0)
- **Container Size**: Significantly smaller Linux containers (~200MB vs ~2GB)
- **Performance**: Better startup time and resource utilization
- **Hosting**: Azure App Service Linux plan

### Azure Service Updates Required:
- **App Service Plan**: Windows → Linux App Service Plan
- **Container Registry**: Store .NET 8 Linux container images
- **Application Settings**: Environment variables for .NET 8 configuration
- **Health Checks**: Update for ASP.NET Core health check endpoints

### Dependencies:
- **Prerequisite**: Story 9 must be completed (.NET 8 code migration)
- **Integration**: Azure SQL Database and Key Vault connections must work with Linux containers

### Estimated Effort: 
- **Time**: 2-3 hours for experienced DevOps engineer
- **Complexity**: Medium - standard containerization patterns
- **Risk**: Low - well-established .NET 8 container practices

## QA Results


## Tasks / Subtasks

### Phase 1: Container Development (1 hour)
- [ ] Create new Dockerfile for .NET 8 Linux application
- [ ] Update .dockerignore for .NET 8 project structure
- [ ] Build and test container locally
- [ ] Optimize container image size and layers

### Phase 2: Azure Infrastructure Updates (1 hour)
- [ ] Create or update Azure Container Registry
- [ ] Create Linux App Service Plan (or update existing)
- [ ] Update App Service configuration for Linux containers
- [ ] Configure environment variables for .NET 8 application

### Phase 3: Deployment and Integration (1 hour)  
- [ ] Push container image to Azure Container Registry
- [ ] Deploy container to Azure App Service
- [ ] Validate Azure SQL Database connectivity from Linux container
- [ ] Test Azure Key Vault integration with Managed Identity
- [ ] Verify Application Insights telemetry collection

## Definition of Done
- [ ] .NET 8 application runs successfully in Linux container locally
- [ ] Container image successfully pushed to Azure Container Registry
- [ ] Application deployed and accessible via Azure App Service URL
- [ ] All Azure service integrations working (SQL, Key Vault, App Insights)
- [ ] Container startup time improved compared to Windows container
- [ ] Health check endpoints responding correctly