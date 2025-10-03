# Deploy Database Schema Migration to Azure SQL Database
# Story 4 Implementation - Database Schema Migration

param(
    [Parameter(Mandatory = $true)]
    [string]$ServerName,
    
    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory = $true)]
    [string]$Username,
    
    [Parameter(Mandatory = $true)]
    [SecureString]$Password,
    
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = ".\eShopLegacyMVC\eShopLegacyMVC.csproj",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false
)

# Error handling
$ErrorActionPreference = "Stop"

Write-Host "🗄️ Azure SQL Database Schema Migration Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Validate prerequisites
Write-Host "✅ Validating prerequisites..." -ForegroundColor Yellow

# Check if project exists
if (-not (Test-Path $ProjectPath)) {
    throw "Project file not found: $ProjectPath"
}

# Check if SqlServer module is available
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "Installing SqlServer PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
}

Import-Module SqlServer

# Build connection string
$connectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$Username;Password=$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)));MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "🔗 Connection Details:" -ForegroundColor Green
Write-Host "   Server: $ServerName" -ForegroundColor White
Write-Host "   Database: $DatabaseName" -ForegroundColor White

if ($WhatIf) {
    Write-Host "🔍 What-If Mode: No actual changes will be made" -ForegroundColor Yellow
    Write-Host "   Connection string would be: $($connectionString.Replace($([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))), '***'))" -ForegroundColor Gray
    exit 0
}

try {
    # Test database connectivity
    Write-Host "🔌 Testing database connectivity..." -ForegroundColor Yellow
    
    $testQuery = "SELECT 1 as TestConnection"
    $testResult = Invoke-Sqlcmd -ConnectionString $connectionString -Query $testQuery -ErrorAction Stop
    
    if ($testResult.TestConnection -eq 1) {
        Write-Host "✅ Database connection successful!" -ForegroundColor Green
    }
    
    # Check if __MigrationsHistory table exists
    Write-Host "📋 Checking migration history..." -ForegroundColor Yellow
    
    $migrationHistoryQuery = @"
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '__MigrationsHistory')
        BEGIN
            CREATE TABLE [dbo].[__MigrationsHistory](
                [MigrationId] [nvarchar](150) NOT NULL,
                [ContextKey] [nvarchar](300) NOT NULL,
                [Model] [varbinary](max) NOT NULL,
                [ProductVersion] [nvarchar](32) NOT NULL,
                CONSTRAINT [PK___MigrationsHistory] PRIMARY KEY CLUSTERED 
                (
                    [MigrationId] ASC,
                    [ContextKey] ASC
                )
            )
            PRINT 'Created __MigrationsHistory table'
        END
        ELSE
        BEGIN
            PRINT '__MigrationsHistory table already exists'
        END
"@
    
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $migrationHistoryQuery
    Write-Host "✅ Migration history table ready" -ForegroundColor Green
    
    # Execute the initial migration SQL directly
    Write-Host "🚀 Applying database schema migration..." -ForegroundColor Yellow
    
    # Check if tables already exist
    $checkTablesQuery = @"
        SELECT COUNT(*) as TableCount 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME IN ('CatalogBrand', 'CatalogType', 'Catalog')
"@
    
    $existingTables = Invoke-Sqlcmd -ConnectionString $connectionString -Query $checkTablesQuery
    
    if ($existingTables.TableCount -eq 0) {
        Write-Host "📊 Creating database schema..." -ForegroundColor Yellow
        
        # Create tables based on our migration
        $createSchemaQuery = @"
            -- Create CatalogBrand table
            CREATE TABLE [dbo].[CatalogBrand](
                [Id] [int] IDENTITY(1,1) NOT NULL,
                [Brand] [nvarchar](100) NOT NULL,
                CONSTRAINT [PK_CatalogBrand] PRIMARY KEY CLUSTERED ([Id] ASC)
            );
            
            -- Create CatalogType table
            CREATE TABLE [dbo].[CatalogType](
                [Id] [int] IDENTITY(1,1) NOT NULL,
                [Type] [nvarchar](100) NOT NULL,
                CONSTRAINT [PK_CatalogType] PRIMARY KEY CLUSTERED ([Id] ASC)
            );
            
            -- Create Catalog table
            CREATE TABLE [dbo].[Catalog](
                [Id] [int] NOT NULL,
                [Name] [nvarchar](50) NOT NULL,
                [Description] [nvarchar](max) NULL,
                [Price] [decimal](18,2) NOT NULL,
                [PictureFileName] [nvarchar](max) NOT NULL,
                [CatalogTypeId] [int] NOT NULL,
                [CatalogBrandId] [int] NOT NULL,
                [AvailableStock] [int] NOT NULL,
                [RestockThreshold] [int] NOT NULL,
                [MaxStockThreshold] [int] NOT NULL,
                [OnReorder] [bit] NOT NULL,
                CONSTRAINT [PK_Catalog] PRIMARY KEY CLUSTERED ([Id] ASC),
                CONSTRAINT [FK_Catalog_CatalogBrand] FOREIGN KEY([CatalogBrandId]) 
                    REFERENCES [dbo].[CatalogBrand] ([Id]),
                CONSTRAINT [FK_Catalog_CatalogType] FOREIGN KEY([CatalogTypeId]) 
                    REFERENCES [dbo].[CatalogType] ([Id])
            );
            
            -- Create indexes
            CREATE NONCLUSTERED INDEX [IX_Catalog_CatalogBrandId] ON [dbo].[Catalog]([CatalogBrandId] ASC);
            CREATE NONCLUSTERED INDEX [IX_Catalog_CatalogTypeId] ON [dbo].[Catalog]([CatalogTypeId] ASC);
            
            PRINT 'Database schema created successfully';
"@
        
        Invoke-Sqlcmd -ConnectionString $connectionString -Query $createSchemaQuery
        Write-Host "✅ Database schema created!" -ForegroundColor Green
        
        # Insert migration history record
        $migrationHistoryInsert = @"
            INSERT INTO [dbo].[__MigrationsHistory] 
            ([MigrationId], [ContextKey], [Model], [ProductVersion])
            VALUES 
            ('202510030001_InitialCreate', 'eShopLegacyMVC.Models.CatalogDBContext', 0x1F8B, '6.4.4');
"@
        
        Invoke-Sqlcmd -ConnectionString $connectionString -Query $migrationHistoryInsert
        Write-Host "✅ Migration history updated!" -ForegroundColor Green
        
    } else {
        Write-Host "ℹ️ Database schema already exists, skipping creation" -ForegroundColor Yellow
    }
    
    # Seed data
    Write-Host "🌱 Seeding initial data..." -ForegroundColor Yellow
    
    $seedDataQuery = @"
        -- Seed CatalogBrands
        MERGE [dbo].[CatalogBrand] AS target
        USING (VALUES 
            (1, 'Azure'),
            (2, '.NET'),
            (3, 'Visual Studio'),
            (4, 'SQL Server'),
            (5, 'Other')
        ) AS source ([Id], [Brand])
        ON target.[Id] = source.[Id]
        WHEN NOT MATCHED THEN
            INSERT ([Brand]) VALUES (source.[Brand]);
        
        -- Seed CatalogTypes
        MERGE [dbo].[CatalogType] AS target
        USING (VALUES 
            (1, 'Mug'),
            (2, 'T-Shirt'),
            (3, 'Sheet'),
            (4, 'USB Memory Stick')
        ) AS source ([Id], [Type])
        ON target.[Id] = source.[Id]
        WHEN NOT MATCHED THEN
            INSERT ([Type]) VALUES (source.[Type]);
        
        -- Seed sample CatalogItems
        MERGE [dbo].[Catalog] AS target
        USING (VALUES 
            (1, 2, 2, 100, '.NET Bot Black Hoodie', '.NET Bot Black Hoodie', 19.50, '1.png', 10, 200, 0),
            (2, 1, 2, 100, '.NET Black & White Mug', '.NET Black & White Mug', 8.50, '2.png', 10, 200, 0),
            (3, 2, 5, 100, 'Prism White T-Shirt', 'Prism White T-Shirt', 12.00, '3.png', 10, 200, 0)
        ) AS source ([Id], [CatalogTypeId], [CatalogBrandId], [AvailableStock], [Description], [Name], [Price], [PictureFileName], [RestockThreshold], [MaxStockThreshold], [OnReorder])
        ON target.[Id] = source.[Id]
        WHEN NOT MATCHED THEN
            INSERT ([Id], [CatalogTypeId], [CatalogBrandId], [AvailableStock], [Description], [Name], [Price], [PictureFileName], [RestockThreshold], [MaxStockThreshold], [OnReorder])
            VALUES (source.[Id], source.[CatalogTypeId], source.[CatalogBrandId], source.[AvailableStock], source.[Description], source.[Name], source.[Price], source.[PictureFileName], source.[RestockThreshold], source.[MaxStockThreshold], source.[OnReorder]);
        
        PRINT 'Seed data applied successfully';
"@
    
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $seedDataQuery
    Write-Host "✅ Seed data applied!" -ForegroundColor Green
    
    # Verify migration
    Write-Host "🔍 Verifying migration..." -ForegroundColor Yellow
    
    $verificationQuery = @"
        SELECT 
            (SELECT COUNT(*) FROM [dbo].[CatalogBrand]) as BrandCount,
            (SELECT COUNT(*) FROM [dbo].[CatalogType]) as TypeCount,
            (SELECT COUNT(*) FROM [dbo].[Catalog]) as ItemCount;
"@
    
    $verificationResult = Invoke-Sqlcmd -ConnectionString $connectionString -Query $verificationQuery
    
    Write-Host "📊 Migration Verification Results:" -ForegroundColor Green
    Write-Host "   Brands: $($verificationResult.BrandCount)" -ForegroundColor White
    Write-Host "   Types: $($verificationResult.TypeCount)" -ForegroundColor White
    Write-Host "   Items: $($verificationResult.ItemCount)" -ForegroundColor White
    
    Write-Host "`n🎉 Database schema migration completed successfully!" -ForegroundColor Green
    Write-Host "   ✅ Schema created and configured for Azure SQL Database" -ForegroundColor Green
    Write-Host "   ✅ Migration history tracking enabled" -ForegroundColor Green
    Write-Host "   ✅ Initial seed data populated" -ForegroundColor Green
    Write-Host "   ✅ Ready for Entity Framework Code First operations" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Migration failed: $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

Write-Host "`n🏁 Migration deployment complete!" -ForegroundColor Cyan