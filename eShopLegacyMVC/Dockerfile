# PRODUCTION DOCKERFILE FOR LINUX CONTAINERS - .NET 8
# Optimized for Azure App Service on Linux with .NET 8

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore
COPY eShopLegacyMVC.csproj .
RUN dotnet restore eShopLegacyMVC.csproj

# Copy source and build
COPY . .
RUN dotnet build eShopLegacyMVC.csproj -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish eShopLegacyMVC.csproj -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

# Copy published app
COPY --from=publish /app/publish .

# Default to 8080 if PORT is not set (for local testing)
ENV PORT=8080

# Azure App Service will set PORT environment variable
# Configure ASP.NET Core to listen on that port
ENV ASPNETCORE_URLS=http://+:80

# Install curl for health checks
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose the port
EXPOSE 80

# Start the application
ENTRYPOINT ["dotnet", "eShopLegacyMVC.dll"]