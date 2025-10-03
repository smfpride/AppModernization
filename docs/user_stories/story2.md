# Story 2: Externalize Configuration for Cloud Deployment

## Status
Ready for QA

## Story

**As a** Developer  
**I want** to externalize application configuration from Web.config  
**so that** the application can retrieve settings from Azure Key Vault and environment variables

## Acceptance Criteria

1. Connection strings moved from Web.config to environment variable support
2. Application Insights instrumentation key externalized
3. Configuration provider updated to read from environment variables first
4. Web.config updated to support transformation for cloud deployment
5. Local development still works with existing configuration fallback
6. No hardcoded sensitive values remain in configuration files

## Dev Notes

- Update Global.asax.cs or create configuration provider
- Maintain backward compatibility for local development
- Reference ADR001 for configuration management approach
- Estimated time: 1 hour from 8-hour roadmap

## QA Results

**Status**: Ready for QA  
**QA Engineer**: Taylor  
**Test Plan**: [Master Test Plan](../test_plans/plan1.md)  
**Test Cases**: [Configuration Stories Test Cases](../test_cases/case2.md) - TC011 through TC015  
**Priority**: High - Critical for cloud configuration management  

### Test Coverage
- Web.config analysis and baseline establishment
- Environment variable configuration loading
- Configuration fallback mechanisms
- Configuration transformation testing
- Local development environment compatibility

### Notes
- Must ensure backward compatibility with existing development workflows
- Critical that no sensitive data remains in configuration files
- Fallback mechanisms must be thoroughly tested


## Tasks / Subtasks

- [ ] Identify all configuration values that need externalization
- [ ] Update configuration loading logic
- [ ] Create environment variable mapping
- [ ] Test with local environment variables
- [ ] Validate fallback to Web.config works
- [ ] Update Web.config transformations

## Definition of Done
- [ ] Application reads connection strings from environment variables
- [ ] Application starts successfully with externalized config
- [ ] Local development environment still functional
- [ ] No sensitive data hardcoded in source control