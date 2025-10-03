# eShopLegacyMVC Azure PaaS Prototype - 8-Hour Implementation Roadmap

**Date:** October 3, 2025  
**Architect:** Riley  
**Project:** eShopLegacyMVC Azure Modernization Prototype  
**Total Duration:** 8 Hours  

## Executive Summary

This roadmap provides a detailed timeline for prototyping the eShopLegacyMVC application modernization to Azure PaaS within 8 hours. The approach prioritizes demonstrable functionality over perfection, focusing on proving the architectural concepts while maintaining application stability.

## Pre-Prerequisites (Pre-Work - 30 minutes)

### Environment Setup ✅
- [ ] Azure subscription with appropriate permissions
- [ ] Visual Studio 2019/2022 with Docker support
- [ ] Azure CLI installed and authenticated
- [ ] Docker Desktop running
- [ ] Source code accessible and buildable locally

### Resource Preparation ✅
- [ ] Resource group created: `rg-eshop-prototype-eastus2`
- [ ] Naming conventions established
- [ ] Cost alerts configured for prototype budget

---

## Phase 1: Containerization Foundation (Hours 0-2.5)

### Hour 0-1: Application Analysis & Docker Setup

**Objectives:**
- Understand application dependencies and build process  
- Create containerization strategy
- Set up local development environment

**Tasks:**
1. **Application Inventory** (20 min)
   - [ ] Review project dependencies in `eShopLegacyMVC.csproj`
   - [ ] Identify external dependencies (Entity Framework, Autofac, log4net)
   - [ ] Document current configuration patterns
   - [ ] Test local build and run

2. **Docker Environment Setup** (25 min)
   - [ ] Create `Dockerfile` for Windows containers
   - [ ] Create `.dockerignore` file
   - [ ] Set up Docker Compose for local testing
   - [ ] Configure development environment variables

3. **Initial Container Build** (15 min)
   - [ ] Build container image locally
   - [ ] Test container startup
   - [ ] Verify application loads in container

**Deliverables:**
- Working Dockerfile
- Local container running successfully
- Baseline performance metrics documented

---

### Hour 1-2.5: Configuration Externalization

**Objectives:**
- Prepare application for cloud deployment
- Externalize configuration for Azure environment
- Implement cloud-ready patterns

**Tasks:**
1. **Configuration Updates** (45 min)
   - [ ] Update `Web.config` for environment variables
   - [ ] Create environment-specific configurations
   - [ ] Update connection string handling
   - [ ] Configure Application Insights for Azure

2. **Dependency Updates** (30 min)
   - [ ] Add Azure SDK packages for Key Vault
   - [ ] Update Autofac configuration
   - [ ] Add configuration providers
   - [ ] Test configuration loading

3. **Local Testing & Validation** (15 min)
   - [ ] Test application with external configuration
   - [ ] Verify all features work in container
   - [ ] Document any compatibility issues

**Deliverables:**
- Cloud-ready application configuration
- Updated dependency injection setup
- Validated container functionality

---

## Phase 2: Azure Infrastructure & Database (Hours 2.5-5)

### Hour 2.5-3.5: Azure Resource Provisioning

**Objectives:**
- Create core Azure infrastructure
- Set up database environment
- Configure security foundations

**Tasks:**
1. **Core Infrastructure** (30 min)
   ```bash
   # Azure CLI commands for resource provisioning
   az group create --name rg-eshop-prototype-eastus2 --location eastus2
   az sql server create --name sql-eshop-prototype --resource-group rg-eshop-prototype-eastus2
   az sql db create --name db-catalog --server sql-eshop-prototype --resource-group rg-eshop-prototype-eastus2
   ```
   - [ ] Create resource group
   - [ ] Create Azure SQL Server and Database
   - [ ] Configure firewall rules
   - [ ] Set up server admin credentials

2. **Key Vault Setup** (20 min)
   - [ ] Create Azure Key Vault
   - [ ] Configure access policies
   - [ ] Store initial secrets (connection strings)
   - [ ] Test secret retrieval

3. **App Service Preparation** (10 min)
   - [ ] Create App Service Plan (S1 Standard)
   - [ ] Create App Service for containers
   - [ ] Enable Managed Identity
   - [ ] Configure basic settings

**Deliverables:**
- Azure SQL Database ready for data
- Key Vault configured with secrets
- App Service infrastructure prepared

---

### Hour 3.5-5: Database Migration & Integration

**Objectives:**
- Migrate database schema and data to Azure SQL
- Establish secure connectivity
- Validate data integrity

**Tasks:**
1. **Database Schema Migration** (45 min)
   - [ ] Export LocalDB schema using SQL Server Management Studio
   - [ ] Create migration scripts for Azure SQL Database
   - [ ] Execute schema creation in Azure SQL
   - [ ] Verify schema integrity and constraints

2. **Data Migration** (30 min)
   - [ ] Export data from LocalDB (BCP or SSMS)
   - [ ] Import data to Azure SQL Database
   - [ ] Validate data completeness and integrity
   - [ ] Update seed data as needed

3. **Connection Testing** (15 min)
   - [ ] Update connection strings in Key Vault
   - [ ] Test database connectivity from local container
   - [ ] Verify Entity Framework migrations work
   - [ ] Test CRUD operations

**Deliverables:**
- Fully migrated database in Azure SQL
- Validated connection from application
- Data integrity confirmed

---

## Phase 3: Security & Container Deployment (Hours 5-7)

### Hour 5-6: Security Implementation

**Objectives:**
- Implement Managed Identity authentication
- Secure all service connections
- Configure Key Vault integration

**Tasks:**
1. **Managed Identity Configuration** (30 min)
   - [ ] Enable system-assigned managed identity on App Service
   - [ ] Configure Key Vault access policies for managed identity
   - [ ] Update SQL Database to accept managed identity
   - [ ] Test managed identity authentication

2. **Application Security Updates** (25 min)
   - [ ] Update application to use DefaultAzureCredential
   - [ ] Implement Key Vault configuration provider
   - [ ] Remove hardcoded connection strings
   - [ ] Test secure configuration loading

3. **Network Security** (5 min)
   - [ ] Configure HTTPS-only access
   - [ ] Set up security headers
   - [ ] Configure IP restrictions if needed

**Deliverables:**
- Fully secured service-to-service authentication
- No hardcoded credentials in application
- Security best practices implemented

---

### Hour 6-7: Container Registry & Deployment

**Objectives:**
- Push container to Azure Container Registry
- Deploy application to App Service
- Configure runtime environment

**Tasks:**
1. **Container Registry Setup** (20 min)
   - [ ] Create Azure Container Registry
   - [ ] Configure authentication
   - [ ] Push application container image
   - [ ] Verify image in registry

2. **App Service Configuration** (25 min)
   - [ ] Configure App Service to use container from ACR
   - [ ] Set environment variables and application settings
   - [ ] Configure container settings (port, startup command)
   - [ ] Enable Application Insights integration

3. **Initial Deployment** (15 min)
   - [ ] Deploy container to App Service
   - [ ] Monitor deployment logs
   - [ ] Verify application startup
   - [ ] Test basic functionality

**Deliverables:**
- Application running in Azure App Service
- Container successfully deployed from ACR
- Basic functionality verified

---

## Phase 4: Testing, Monitoring & Documentation (Hours 7-8)

### Hour 7-8: Validation & Finalization

**Objectives:**
- Comprehensive testing of deployed application
- Set up monitoring and alerting
- Document deployment and provide handoff materials

**Tasks:**
1. **End-to-End Testing** (30 min)
   - [ ] Test all major application flows (catalog browsing, API endpoints)
   - [ ] Verify database operations (CRUD functionality)
   - [ ] Test image loading and static content
   - [ ] Validate Web API functionality
   - [ ] Performance baseline testing

2. **Monitoring Setup** (15 min)
   - [ ] Configure Application Insights dashboards
   - [ ] Set up basic alerts (errors, performance)
   - [ ] Create health check endpoint
   - [ ] Test monitoring and alerting

3. **Documentation & Handoff** (15 min)
   - [ ] Document deployment configuration
   - [ ] Create troubleshooting guide
   - [ ] Provide access credentials and resources
   - [ ] Compile lessons learned and next steps

**Deliverables:**
- Fully functional Azure-hosted application
- Monitoring and alerting configured
- Comprehensive handoff documentation

---

## Success Criteria & Validation Checklist

### Functional Validation ✅
- [ ] Application loads successfully at Azure URL
- [ ] Catalog pages display products correctly
- [ ] Product images load properly
- [ ] API endpoints return expected responses
- [ ] Database operations complete successfully
- [ ] No application errors in logs

### Security Validation ✅
- [ ] All connections use HTTPS
- [ ] No hardcoded credentials in code or config
- [ ] Managed Identity authentication working
- [ ] Key Vault integration functional
- [ ] SQL Database secured with proper authentication

### Performance Validation ✅
- [ ] Page load times < 3 seconds
- [ ] API response times < 1 second
- [ ] Database queries executing efficiently
- [ ] Container startup time < 90 seconds
- [ ] No memory leaks or performance degradation

### Operational Validation ✅
- [ ] Application Insights collecting telemetry
- [ ] Health check endpoint responding
- [ ] Logs available and readable
- [ ] Basic alerts configured and tested
- [ ] Access controls properly configured

---

## Risk Mitigation & Contingency Plans

### High-Risk Items & Mitigation
1. **Container Compatibility Issues**
   - **Risk:** .NET Framework application may not containerize cleanly
   - **Mitigation:** Test containerization early; fallback to direct App Service deployment
   - **Time Buffer:** 30 minutes allocated

2. **Database Migration Complexity**
   - **Risk:** Data migration may fail or take longer than expected
   - **Mitigation:** Use proven migration tools; start with schema-only if needed
   - **Time Buffer:** 45 minutes allocated

3. **Authentication Configuration**
   - **Risk:** Managed Identity setup may be complex
   - **Mitigation:** Use connection strings initially, implement Managed Identity if time permits
   - **Time Buffer:** Fallback plan ready

### Emergency Fallback Plan
If prototype timeline is at risk:
1. **Hour 6 Decision Point:** Assess progress and adjust scope
2. **Minimum Viable Prototype:** Application running in App Service with Azure SQL
3. **Nice-to-Have Features:** Key Vault, Managed Identity, comprehensive monitoring

---

## Resource Requirements

### Azure Resources Created
- Resource Group: `rg-eshop-prototype-eastus2`
- App Service Plan: `asp-eshop-prototype` (S1 Standard)
- App Service: `app-eshop-prototype`
- Azure SQL Server: `sql-eshop-prototype`
- Azure SQL Database: `db-catalog` (S2 Standard)
- Azure Key Vault: `kv-eshop-prototype`
- Azure Container Registry: `acreshopprototype`
- Application Insights: `ai-eshop-prototype`

### Estimated Costs (8-hour prototype)
- **Development/Testing:** ~$5-10 for prototype period
- **Monthly Running Cost:** ~$166/month if left running
- **Recommendation:** Delete resources after demonstration unless moving to next phase

---

## Post-Prototype Next Steps

### Immediate Actions (Week 1)
1. **Architecture Review:** Present results to stakeholders
2. **Feedback Incorporation:** Address any concerns or requirements
3. **Production Planning:** Scale architecture for production workloads
4. **Security Review:** Complete security assessment

### Short-term Enhancements (Month 1)
1. **CI/CD Pipeline:** Implement automated deployment
2. **Environment Strategy:** Create dev, staging, production environments
3. **Monitoring Enhancement:** Comprehensive observability setup
4. **Performance Optimization:** Based on prototype learnings

### Long-term Modernization (Months 2-6)
1. **Microservices Decomposition:** Break into smaller services
2. **Frontend Modernization:** Modern SPA with API backend
3. **Cloud-Native Services:** Leverage additional Azure services
4. **Data Platform Enhancement:** Advanced analytics and reporting

---

## Communication Plan

### Stakeholder Updates
- **Hour 2:** "Infrastructure provisioned, containerization complete"
- **Hour 4:** "Database migrated, security implemented"  
- **Hour 6:** "Application deployed to Azure, testing in progress"
- **Hour 8:** "Prototype complete, ready for demonstration"

### Final Deliverables for Program Manager
1. **Live Demo URL:** Functional application in Azure
2. **Architecture Documentation:** Comprehensive plan and decisions
3. **Cost Analysis:** Current and projected costs
4. **Next Steps Roadmap:** Recommendations for production implementation
5. **Risk Assessment:** Identified challenges and mitigation strategies

---

**Document Status:** Ready for Execution  
**Estimated Success Probability:** 85% (with contingency plans)  
**Critical Success Factors:** Pre-work completion, Azure environment access, team coordination

---

*This roadmap serves as both a planning document and execution checklist. Each phase builds upon the previous, with clear decision points and fallback options to ensure prototype delivery within the 8-hour constraint.*