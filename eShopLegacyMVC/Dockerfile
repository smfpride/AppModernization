# PRODUCTION DOCKERFILE FOR WINDOWS CONTAINERS
# This Dockerfile is designed for Windows container environments
# For development on Linux Docker Desktop, see Dockerfile.dev

# Use Windows Server Core with IIS as the base image for .NET Framework 4.7.2
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2-windowsservercore-ltsc2022

# Set the working directory in the container
WORKDIR /inetpub/wwwroot

# Configure PowerShell execution policy and error handling
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Remove default IIS site and create new application
RUN Remove-WebSite -Name 'Default Web Site'; \
    New-Website -Name 'eShopLegacyMVC' -Port 80 -PhysicalPath 'C:\inetpub\wwwroot'

# Set environment variables for configuration
ENV ASPNET_ENVIRONMENT=Production
ENV CatalogDBContext=""

# Copy the application files to the container
COPY . .

# Restore NuGet packages and build application
RUN if (Test-Path 'packages.config') { \
        Write-Host 'Restoring NuGet packages...'; \
        nuget restore; \
    } else { \
        Write-Host 'No packages.config found, skipping package restore'; \
    }

# Build the application in Release mode
RUN Write-Host 'Building application...'; \
    msbuild eShopLegacyMVC.csproj /p:Configuration=Release /p:Platform=AnyCPU /p:OutputPath=bin\

# Set proper permissions for IIS application pool
RUN icacls 'C:\inetpub\wwwroot' /grant 'IIS_IUSRS:(OI)(CI)F' /T; \
    icacls 'C:\inetpub\wwwroot' /grant 'IUSR:(OI)(CI)RX' /T

# Configure health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD powershell -command "try { $response = Invoke-WebRequest -Uri http://localhost -UseBasicParsing -TimeoutSec 10; if ($response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start IIS services
ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]