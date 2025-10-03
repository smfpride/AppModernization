# eShopLegacyMVC Azure PaaS Modernization Architecture Plan

**Date:** October 3, 2025  
**Architect:** Riley  
**Project:** eShopLegacyMVC to Azure PaaS Migration  
**Timeline:** 8-Hour Prototype  

## Executive Summary

This architecture plan outlines the modernization of the eShopLegacyMVC application to run on Azure Platform-as-a-Service (PaaS) offerings. The approach prioritizes a lift-and-shift strategy with containerization to achieve rapid deployment within the 8-hour prototype constraint while establishing a foundation for future modernization.

## Current State Architecture

### Application Profile
- **Framework:** .NET Framework 4.7.2
- **Architecture:** ASP.NET MVC 5 with Web API 2
- **Database:** Entity Framework 6 with SQL Server LocalDB
- **Dependency Injection:** Autofac IoC container
- **Logging:** log4net with Application Insights integration
- **Authentication:** Forms-based (ready for modernization)

### Key Components Identified
1. **Web Layer:** MVC Controllers (CatalogController, PicController)
2. **API Layer:** Web API Controllers (BrandsController, FilesController)  
3. **Service Layer:** ICatalogService interface with concrete implementations
4. **Data Layer:** Entity Framework DbContext with Code First migrations
5. **Domain Models:** CatalogItem, CatalogBrand, CatalogType entities

## Target Azure Architecture

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                              │
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐                  │
│  │   Azure Front   │    │   Azure App      │                  │
│  │   Door / CDN    │───▶│   Service        │                  │
│  │   (Optional)    │    │   (Container)    │                  │
│  └─────────────────┘    └──────────┬───────┘                  │
│                                    │                          │
│  ┌─────────────────┐              │                          │
│  │   Azure Key     │◀─────────────┘                          │
│  │   Vault         │               │                          │
│  └─────────────────┘               │                          │
│                                    │                          │
│  ┌─────────────────┐               │                          │
│  │   Azure SQL     │◀──────────────┘                          │
│  │   Database      │                                          │
│  └─────────────────┘                                          │
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐                  │
│  │   Azure Blob    │    │  Application     │                  │
│  │   Storage       │    │  Insights        │                  │
│  │   (Images)      │    │  (Monitoring)    │                  │
│  └─────────────────┘    └──────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Core Azure Services

#### 1. Azure App Service for Containers
- **Purpose:** Host the containerized .NET Framework application
- **Configuration:** 
  - Windows Container on App Service Plan (S1 Standard)
  - Auto-scaling enabled (1-3 instances for prototype)
  - Application Insights integration
  - Managed Identity enabled

#### 2. Azure SQL Database  
- **Purpose:** Modernized database platform
- **Configuration:**
  - Single Database, S2 Standard tier (prototype)
  - Connection resilience and retry policies
  - Automated backups with 7-day retention
  - Transparent Data Encryption enabled

#### 3. Azure Key Vault
- **Purpose:** Centralized secrets and configuration management
- **Configuration:**
  - Standard tier with soft-delete enabled
  - Access via Managed Identity from App Service
  - Store connection strings, API keys, certificates

#### 4. Application Insights
- **Purpose:** Enhanced monitoring and observability (existing integration)
- **Enhancements:**
  - Custom telemetry for business metrics
  - Dependency tracking
  - Performance monitoring
  - Health check endpoints

#### 5. Azure Blob Storage (Phase 2)
- **Purpose:** Scalable storage for product images
- **Configuration:**
  - Hot tier for frequently accessed images
  - CDN integration for global distribution
  - SAS token-based access

## Migration Strategy

### Phase 1: Containerization (Hours 1-3)
1. **Create Dockerfile**
   - Base image: `mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019`
   - Copy application files and configure IIS
   - Set environment variables for configuration

2. **Update Configuration**
   - Externalize connection strings
   - Configure for Azure environment variables
   - Update Application Insights configuration

3. **Build and Test Container**
   - Local container testing
   - Verify application functionality
   - Performance baseline establishment

### Phase 2: Database Migration (Hours 3-5)
1. **Azure SQL Database Setup**
   - Create database server and database
   - Configure firewall rules and networking
   - Set up Managed Identity access

2. **Data Migration**
   - Export schema and data from LocalDB
   - Import to Azure SQL Database
   - Validate data integrity

3. **Connection String Updates**
   - Update configuration for Azure SQL
   - Implement connection resilience
   - Test database connectivity

### Phase 3: Security & Configuration (Hours 5-7)
1. **Azure Key Vault Integration**
   - Create Key Vault resource
   - Store sensitive configuration
   - Update application to use Key Vault

2. **Managed Identity Configuration**
   - Enable system-assigned managed identity
   - Configure Key Vault access policies
   - Update database connection to use managed identity

3. **Security Hardening**
   - Configure HTTPS-only access
   - Set up network restrictions
   - Enable security headers

### Phase 4: Deployment & Monitoring (Hours 7-8)
1. **Azure App Service Deployment**
   - Create App Service and App Service Plan
   - Deploy container image
   - Configure environment variables

2. **Monitoring Setup**
   - Verify Application Insights integration
   - Set up alerts and dashboards
   - Configure health check endpoints

3. **Testing & Validation**
   - End-to-end functionality testing
   - Performance validation
   - Security configuration verification

## Technical Implementation Details

### Dockerfile Structure
```dockerfile
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019

# Copy application files
COPY eShopLegacyMVC/ C:/inetpub/wwwroot/

# Configure IIS
RUN powershell -Command \
    Import-module IISAdministration; \
    New-IISSite -Name "eShopLegacyMVC" -PhysicalPath C:\inetpub\wwwroot -Port 80

EXPOSE 80
```

### Configuration Updates Required
1. **Web.config modifications**
   - Replace connection strings with environment variables
   - Update Application Insights configuration
   - Configure for Azure environment

2. **Dependency injection updates**
   - Add Azure SDK packages
   - Configure Key Vault client
   - Update service registrations

### Key Vault Integration Pattern
```csharp
// Add to Startup/Global.asax
public void ConfigureKeyVault()
{
    var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
    var credential = new DefaultAzureCredential();
    var client = new SecretClient(new Uri(keyVaultEndpoint), credential);
    
    // Update connection strings from Key Vault
    var connectionString = client.GetSecret("database-connection-string").Value.Value;
    // Update configuration
}
```

## Risk Mitigation

### Technical Risks
1. **Container compatibility issues**
   - **Mitigation:** Thorough local testing before deployment
   - **Contingency:** Fallback to direct App Service deployment

2. **Database connection failures**
   - **Mitigation:** Implement connection resilience patterns
   - **Monitoring:** Application Insights dependency tracking

3. **Performance degradation**
   - **Mitigation:** Performance baseline and monitoring
   - **Scaling:** Auto-scaling configuration

### Operational Risks
1. **Deployment failures**
   - **Mitigation:** Staged deployment with blue-green slots
   - **Rollback:** Immediate rollback capability

2. **Security misconfigurations**
   - **Mitigation:** Security checklist and peer review
   - **Monitoring:** Azure Security Center integration

## Success Criteria

### Functional Requirements ✅
- All existing application functionality preserved
- Database operations working correctly
- API endpoints responding appropriately
- Static content (images, CSS, JS) loading properly

### Performance Requirements ✅
- Application response time < 2 seconds for catalog pages
- Database query performance maintained or improved
- Container startup time < 60 seconds

### Security Requirements ✅
- All sensitive data stored in Key Vault
- HTTPS-only access enforced
- Managed Identity authentication implemented
- No hardcoded credentials in code or configuration

### Operational Requirements ✅
- Application Insights monitoring functional
- Health check endpoints implemented
- Auto-scaling configured and tested
- Backup and recovery procedures documented

## Cost Analysis

### Monthly Operating Costs (Prototype)
- **Azure App Service (S1 Standard):** ~$73
- **Azure SQL Database (S2 Standard):** ~$75
- **Azure Key Vault (Standard):** ~$3
- **Application Insights:** ~$10 (5GB included)
- **Azure Blob Storage:** ~$5 (100GB)
- **Total Monthly Cost:** ~$166

### Cost Optimization Opportunities
- Reserved instances for long-term usage (30-60% savings)
- Auto-scaling to reduce costs during low usage
- Database tier optimization based on usage patterns

## Future Modernization Roadmap

### Phase 2 Enhancements (Future)
1. **Microservices Decomposition**
   - Extract catalog service to Azure Functions
   - Implement API Gateway pattern
   - Event-driven architecture with Service Bus

2. **Frontend Modernization**
   - React/Angular SPA with .NET Core Web API
   - Progressive Web App capabilities
   - Mobile-responsive design improvements

3. **Data Platform Enhancement**
   - Implement CQRS with Azure Cosmos DB
   - Event sourcing for audit trails
   - Data analytics with Azure Synapse

### Technology Upgrade Path
1. **Container Platform Migration**
   - Move to Azure Container Apps
   - Implement container orchestration
   - Linux containers with .NET 8

2. **Cloud-Native Services**
   - Azure Service Bus for messaging
   - Azure Redis Cache for session state
   - Azure CDN for global content delivery

## Conclusion

This architecture plan provides a comprehensive approach to modernizing the eShopLegacyMVC application for Azure PaaS within the 8-hour prototype constraint. The lift-and-shift approach with containerization ensures rapid deployment while establishing a solid foundation for future modernization efforts.

The proposed solution leverages Azure's managed services to improve security, scalability, and operational efficiency while maintaining application functionality and minimizing risk during the migration process.

**Next Steps:**
1. Review and approve this architecture plan
2. Provision Azure resources according to specifications
3. Begin implementation following the defined phases
4. Establish monitoring and alerting for the production environment

---

**Document Version:** 1.0  
**Last Updated:** October 3, 2025  
**Approved By:** [Pending Program Manager Review]