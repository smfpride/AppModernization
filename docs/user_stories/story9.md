# Story 9: Modernize eShopLegacyMVC Application Code to .NET 8

## Status
Backlog

## Story

**As a** Developer  
**I want** to modernize the eShopLegacyMVC application and test project code from .NET Framework 4.7.2 to .NET 8  
**so that** the application can leverage modern .NET features, improved performance, and better development experience

## Acceptance Criteria

1. Create unit tests for all existing functionality
2. Main eShopLegacyMVC project converted from .NET Framework 4.7.2 to .NET 8
3. eShopLegacyMVC.Tests project converted from .NET Framework 4.7.2 to .NET 8 
4. ASP.NET MVC 5 controllers migrated to ASP.NET Core MVC 8
5. Entity Framework 6 migrated to Entity Framework Core 8
6. All NuGet packages updated to .NET 8 compatible versions
7. All existing functionality preserved and unit tests pass

## Dev Notes

### Major Framework Changes Required:
- **Web Framework**: ASP.NET MVC 5 → ASP.NET Core MVC 8
- **Dependency Injection**: Autofac → Built-in ASP.NET Core DI (or continue with Autofac)
- **Data Access**: Entity Framework 6 → Entity Framework Core 8
- **Configuration**: Web.config → appsettings.json + environment variables
- **Logging**: log4net → ASP.NET Core built-in logging (ILogger)
- **Testing**: MSTest → Continue with MSTest or migrate to xUnit

### Key Components to Modernize:
- Controllers (CatalogController, PicController, API controllers)
- Models and Entity Framework DbContext
- Dependency injection container setup
- Configuration management
- Authentication and authorization
- Static files and bundling
- Application startup (Global.asax.cs → Program.cs/Startup.cs)

### Estimated Effort: 
- **Time**: 4-5 hours for experienced .NET developer
- **Complexity**: High - requires significant code changes
- **Risk**: Medium - well-documented migration path exists

## QA Results


## Tasks / Subtasks

### Phase 1: Project Structure Migration (1.5 hours)
- [ ] Create unit tests for all existing functionality
- [ ] Create new .NET 8 Web application project structure
- [ ] Migrate project files to SDK-style format
- [ ] Update solution file

### Phase 2: Framework Migration (2.5 hours)
- [ ] Migrate ASP.NET MVC 5 controllers to ASP.NET Core MVC
- [ ] Convert Entity Framework 6 to Entity Framework Core 8
- [ ] Update dependency injection from Autofac to ASP.NET Core DI
- [ ] Migrate configuration from Web.config to appsettings.json
- [ ] Convert Global.asax.cs to Program.cs

### Phase 3: Package Updates (1 hour)
- [ ] Update all NuGet packages to .NET 8 compatible versions
- [ ] Replace deprecated packages with modern equivalents
- [ ] Update Application Insights SDK to latest version
- [ ] Update Azure SDK packages for Key Vault integration

## Definition of Done
- [ ] Application builds successfully on .NET 8
- [ ] All existing web functionality works identically
- [ ] All unit tests pass with .NET 8 test framework
- [ ] Application Insights telemetry continues to work
- [ ] Azure Key Vault integration functions correctly
- [ ] Local development environment fully functional