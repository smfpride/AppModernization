# Starting Parameters

**Date:** October 3, 2025
**Project:** eShopLegacyMVC Modernization

## User Preferences

### 1. Deployment Approach
- **Selected:** Containerization (Docker containers)
- **Target:** Azure PaaS offerings with containerization support

### 2. Azure Services to Leverage
- Azure Key Vault (for secrets management)
- Azure SQL Database (database modernization)
- Azure Functions (potential microservices opportunities)
- Azure App Service (container hosting)

### 3. CI/CD Integration
- **Decision:** Skip for prototype phase
- **Rationale:** Focus on architecture and functionality first

### 4. Coding Standards
- **Decision:** Review current codebase to determine existing standards
- **Action:** Analyze current code patterns and maintain consistency

### 5. Modernization Approach
- **Selected:** Lift-and-shift approach
- **Goal:** Minimal code changes while ensuring Azure PaaS compatibility
- **Timeline:** 8 hours for prototype
- **Priority:** Get application running on Azure PaaS quickly

## Architecture Focus Areas
1. Containerization strategy
2. Database migration to Azure SQL
3. Configuration externalization to Azure Key Vault
4. Potential microservices identification for Azure Functions
5. Monitoring and observability setup