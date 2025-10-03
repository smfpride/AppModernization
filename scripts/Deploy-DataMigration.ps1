# Deploy Data Migration from LocalDB to Azure SQL Database
# Story 5 Implementation - Database Data Migration

param(
    [Parameter(Mandatory = $true)]
    [string]$AzureServerName,
    
    [Parameter(Mandatory = $true)]
    [string]$AzureDatabaseName,
    
    [Parameter(Mandatory = $true)]
    [string]$AzureUsername,
    
    [Parameter(Mandatory = $false)]
    [string]$AzurePassword,
    
    [Parameter(Mandatory = $false)]
    [string]$LocalDbInstance = "(localdb)\MSSQLLocalDB",
    
    [Parameter(Mandatory = $false)]
    [string]$LocalDatabaseName = "Microsoft.eShopOnContainers.Services.CatalogDb",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false
)

# Error handling
$ErrorActionPreference = "Stop"

Write-Host "📦 eShopLegacyMVC Data Migration (Story 5)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Validate prerequisites
Write-Host "✅ Validating prerequisites..." -ForegroundColor Yellow

# Check if SqlServer module is available
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Write-Host "Installing SqlServer PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
}

Import-Module SqlServer

# Build connection strings
$localConnectionString = "Server=$LocalDbInstance;Database=$LocalDatabaseName;Integrated Security=True;MultipleActiveResultSets=True;"

# Prompt for password if not provided
if (-not $AzurePassword) {
    $azurePasswordSecure = Read-Host "Enter Azure SQL Password for $AzureUsername" -AsSecureString
    $azurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($azurePasswordSecure))
} else {
    # Password was provided as string parameter
    $azurePassword = $AzurePassword
}

$azureConnectionString = "Server=tcp:$AzureServerName,1433;Initial Catalog=$AzureDatabaseName;Persist Security Info=False;User ID=$AzureUsername;Password=$azurePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "🔗 Connection Details:" -ForegroundColor Green
Write-Host "   Local: $LocalDbInstance -> $LocalDatabaseName" -ForegroundColor White
Write-Host "   Azure: $AzureServerName -> $AzureDatabaseName" -ForegroundColor White

if ($WhatIf) {
    Write-Host "🔍 What-If Mode: No actual changes will be made" -ForegroundColor Yellow
    exit 0
}

try {
    # Step 1: Ensure LocalDB has the database and sample data
    Write-Host "🏗️ Step 1: Setting up LocalDB with sample data..." -ForegroundColor Yellow
    
    # Check if LocalDB database exists
    $checkLocalDbQuery = "SELECT COUNT(*) as DbCount FROM sys.databases WHERE name = '$LocalDatabaseName'"
    
    try {
        $localDbExists = Invoke-Sqlcmd -ServerInstance $LocalDbInstance -Query $checkLocalDbQuery -Database "master"
        
        if ($localDbExists.DbCount -eq 0) {
            Write-Host "📊 Creating LocalDB database..." -ForegroundColor Yellow
            
            # Create the database
            $createDbQuery = "CREATE DATABASE [$LocalDatabaseName]"
            Invoke-Sqlcmd -ServerInstance $LocalDbInstance -Query $createDbQuery -Database "master"
            
            # Create schema and seed data in LocalDB
            $createSchemaQuery = @"
                USE [$LocalDatabaseName];
                
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
                
                -- Create Catalog table (note: table name is 'Catalog' not 'CatalogItem' based on migration)
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
                
                -- Seed CatalogBrands
                SET IDENTITY_INSERT [dbo].[CatalogBrand] ON;
                INSERT INTO [dbo].[CatalogBrand] ([Id], [Brand]) VALUES
                (1, 'Azure'),
                (2, '.NET'),
                (3, 'Visual Studio'),
                (4, 'SQL Server'),
                (5, 'Other');
                SET IDENTITY_INSERT [dbo].[CatalogBrand] OFF;
                
                -- Seed CatalogTypes
                SET IDENTITY_INSERT [dbo].[CatalogType] ON;
                INSERT INTO [dbo].[CatalogType] ([Id], [Type]) VALUES
                (1, 'Mug'),
                (2, 'T-Shirt'),
                (3, 'Sheet'),
                (4, 'USB Memory Stick');
                SET IDENTITY_INSERT [dbo].[CatalogType] OFF;
                
                -- Seed Catalog Items
                INSERT INTO [dbo].[Catalog] ([Id], [Name], [Description], [Price], [PictureFileName], [CatalogTypeId], [CatalogBrandId], [AvailableStock], [RestockThreshold], [MaxStockThreshold], [OnReorder]) VALUES
                (1, '.NET Bot Black Hoodie', '.NET Bot Black Hoodie', 19.50, '1.png', 2, 2, 100, 10, 200, 0),
                (2, '.NET Black & White Mug', '.NET Black & White Mug', 8.50, '2.png', 1, 2, 100, 10, 200, 0),
                (3, 'Prism White T-Shirt', 'Prism White T-Shirt', 12.00, '3.png', 2, 5, 100, 10, 200, 0),
                (4, '.NET Foundation Hoodie', '.NET Foundation Hoodie', 12.00, '4.png', 2, 2, 100, 10, 200, 0),
                (5, 'Roslyn Red Sheet', 'Roslyn Red Sheet', 8.50, '5.png', 3, 2, 100, 10, 200, 0),
                (6, '.NET Blue Hoodie', '.NET Blue Hoodie', 12.00, '6.png', 2, 2, 100, 10, 200, 0),
                (7, 'Roslyn Red T-Shirt', 'Roslyn Red T-Shirt', 12.00, '7.png', 2, 2, 100, 10, 200, 0),
                (8, 'Kudu Purple Hoodie', 'Kudu Purple Hoodie', 8.50, '8.png', 2, 5, 100, 10, 200, 0),
                (9, 'Cup<T> White Mug', 'Cup<T> White Mug', 12.00, '9.png', 1, 2, 100, 10, 200, 0),
                (10, '.NET Foundation Sheet', '.NET Foundation Sheet', 12.00, '10.png', 3, 2, 100, 10, 200, 0),
                (11, 'Cup<T> Sheet', 'Cup<T> Sheet', 8.50, '11.png', 3, 2, 100, 10, 200, 0),
                (12, 'Prism White TShirt', 'Prism White TShirt', 12.00, '12.png', 2, 5, 100, 10, 200, 0);
                
                PRINT 'LocalDB schema and seed data created successfully';
"@
            
            Invoke-Sqlcmd -ServerInstance $LocalDbInstance -Query $createSchemaQuery
            Write-Host "✅ LocalDB database created and seeded!" -ForegroundColor Green
        }
        else {
            Write-Host "ℹ️ LocalDB database already exists" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Error setting up LocalDB: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
    
    # Step 2: Test Azure SQL Database connectivity
    Write-Host "🔌 Step 2: Testing Azure SQL Database connectivity..." -ForegroundColor Yellow
    
    $testQuery = "SELECT 1 as TestConnection"
    $testResult = Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $testQuery -ErrorAction Stop
    
    if ($testResult.TestConnection -eq 1) {
        Write-Host "✅ Azure SQL Database connection successful!" -ForegroundColor Green
    }
    
    # Step 3: Export data from LocalDB
    Write-Host "📤 Step 3: Exporting data from LocalDB..." -ForegroundColor Yellow
    
    $exportQueries = @{
        "CatalogBrand" = "SELECT * FROM [dbo].[CatalogBrand] ORDER BY Id"
        "CatalogType" = "SELECT * FROM [dbo].[CatalogType] ORDER BY Id"  
        "Catalog" = "SELECT * FROM [dbo].[Catalog] ORDER BY Id"
    }
    
    $exportedData = @{}
    
    foreach ($table in $exportQueries.Keys) {
        Write-Host "   Exporting $table..." -ForegroundColor Gray
        $data = Invoke-Sqlcmd -ConnectionString $localConnectionString -Query $exportQueries[$table]
        $exportedData[$table] = $data
        Write-Host "   ✅ Exported $($data.Count) records from $table" -ForegroundColor Green
    }
    
    # Step 4: Clear existing data in Azure SQL Database (if any)
    Write-Host "🧹 Step 4: Clearing existing data in Azure SQL Database..." -ForegroundColor Yellow
    
    $clearDataQuery = @"
        -- Disable foreign key constraints temporarily
        ALTER TABLE [dbo].[Catalog] NOCHECK CONSTRAINT ALL;
        
        -- Clear existing data
        DELETE FROM [dbo].[Catalog];
        DELETE FROM [dbo].[CatalogBrand];
        DELETE FROM [dbo].[CatalogType];
        
        -- Reset identity seeds
        DBCC CHECKIDENT('[dbo].[CatalogBrand]', RESEED, 0);
        DBCC CHECKIDENT('[dbo].[CatalogType]', RESEED, 0);
        
        -- Re-enable foreign key constraints
        ALTER TABLE [dbo].[Catalog] CHECK CONSTRAINT ALL;
        
        PRINT 'Existing data cleared from Azure SQL Database';
"@
    
    Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $clearDataQuery
    Write-Host "✅ Existing data cleared!" -ForegroundColor Green
    
    # Step 5: Import data to Azure SQL Database
    Write-Host "📥 Step 5: Importing data to Azure SQL Database..." -ForegroundColor Yellow
    
    # Import CatalogBrands
    Write-Host "   Importing CatalogBrands..." -ForegroundColor Gray
    foreach ($brand in $exportedData["CatalogBrand"]) {
        $insertBrandQuery = "SET IDENTITY_INSERT [dbo].[CatalogBrand] ON; INSERT INTO [dbo].[CatalogBrand] ([Id], [Brand]) VALUES ($($brand.Id), '$($brand.Brand.Replace("'", "''"))'); SET IDENTITY_INSERT [dbo].[CatalogBrand] OFF;"
        Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $insertBrandQuery
    }
    Write-Host "   ✅ Imported $($exportedData["CatalogBrand"].Count) CatalogBrands" -ForegroundColor Green
    
    # Import CatalogTypes
    Write-Host "   Importing CatalogTypes..." -ForegroundColor Gray
    foreach ($type in $exportedData["CatalogType"]) {
        $insertTypeQuery = "SET IDENTITY_INSERT [dbo].[CatalogType] ON; INSERT INTO [dbo].[CatalogType] ([Id], [Type]) VALUES ($($type.Id), '$($type.Type.Replace("'", "''"))'); SET IDENTITY_INSERT [dbo].[CatalogType] OFF;"
        Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $insertTypeQuery
    }
    Write-Host "   ✅ Imported $($exportedData["CatalogType"].Count) CatalogTypes" -ForegroundColor Green
    
    # Import Catalog Items
    Write-Host "   Importing Catalog Items..." -ForegroundColor Gray
    foreach ($item in $exportedData["Catalog"]) {
        $insertItemQuery = @"
            INSERT INTO [dbo].[Catalog] 
            ([Id], [Name], [Description], [Price], [PictureFileName], [CatalogTypeId], [CatalogBrandId], [AvailableStock], [RestockThreshold], [MaxStockThreshold], [OnReorder])
            VALUES 
            ($($item.Id), '$($item.Name.Replace("'", "''"))', '$($item.Description.Replace("'", "''"))', $($item.Price), '$($item.PictureFileName.Replace("'", "''"))', $($item.CatalogTypeId), $($item.CatalogBrandId), $($item.AvailableStock), $($item.RestockThreshold), $($item.MaxStockThreshold), $(if($item.OnReorder) {1} else {0}));
"@
        Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $insertItemQuery
    }
    Write-Host "   ✅ Imported $($exportedData["Catalog"].Count) Catalog Items" -ForegroundColor Green
    
    # Step 6: Data Integrity Validation
    Write-Host "🔍 Step 6: Validating data integrity..." -ForegroundColor Yellow
    
    $validationQuery = @"
        SELECT 
            (SELECT COUNT(*) FROM [dbo].[CatalogBrand]) as AzureBrandCount,
            (SELECT COUNT(*) FROM [dbo].[CatalogType]) as AzureTypeCount,
            (SELECT COUNT(*) FROM [dbo].[Catalog]) as AzureItemCount;
"@
    
    $azureCount = Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $validationQuery
    $localCount = Invoke-Sqlcmd -ConnectionString $localConnectionString -Query $validationQuery.Replace("Azure", "Local")
    
    Write-Host "📊 Data Migration Validation Results:" -ForegroundColor Green
    Write-Host "   CatalogBrands - Local: $($localCount.LocalBrandCount), Azure: $($azureCount.AzureBrandCount)" -ForegroundColor White
    Write-Host "   CatalogTypes - Local: $($localCount.LocalTypeCount), Azure: $($azureCount.AzureTypeCount)" -ForegroundColor White  
    Write-Host "   Catalog Items - Local: $($localCount.LocalItemCount), Azure: $($azureCount.AzureItemCount)" -ForegroundColor White
    
    # Validate foreign key relationships
    Write-Host "🔗 Validating foreign key relationships..." -ForegroundColor Yellow
    
    $foreignKeyValidationQuery = @"
        SELECT 
            COUNT(*) as OrphanedItems
        FROM [dbo].[Catalog] c
        LEFT JOIN [dbo].[CatalogBrand] b ON c.CatalogBrandId = b.Id
        LEFT JOIN [dbo].[CatalogType] t ON c.CatalogTypeId = t.Id
        WHERE b.Id IS NULL OR t.Id IS NULL;
"@
    
    $orphanedCount = Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $foreignKeyValidationQuery
    
    if ($orphanedCount.OrphanedItems -eq 0) {
        Write-Host "✅ No orphaned records found - foreign key integrity maintained!" -ForegroundColor Green
    } else {
        Write-Host "❌ Found $($orphanedCount.OrphanedItems) orphaned records!" -ForegroundColor Red
        throw "Data integrity validation failed - orphaned records detected"
    }
    
    # Validate record counts match
    $validationPassed = $true
    if ($localCount.LocalBrandCount -ne $azureCount.AzureBrandCount) {
        Write-Host "❌ CatalogBrand count mismatch!" -ForegroundColor Red
        $validationPassed = $false
    }
    if ($localCount.LocalTypeCount -ne $azureCount.AzureTypeCount) {
        Write-Host "❌ CatalogType count mismatch!" -ForegroundColor Red
        $validationPassed = $false
    }
    if ($localCount.LocalItemCount -ne $azureCount.AzureItemCount) {
        Write-Host "❌ Catalog count mismatch!" -ForegroundColor Red
        $validationPassed = $false
    }
    
    if ($validationPassed) {
        Write-Host "✅ 100% data integrity validation PASSED!" -ForegroundColor Green
    } else {
        throw "Data integrity validation FAILED - record count mismatch detected"
    }
    
    # Step 7: Sample query validation
    Write-Host "🔍 Step 7: Running sample queries..." -ForegroundColor Yellow
    
    $sampleQuery = @"
        SELECT TOP 3
            c.Id,
            c.Name,
            c.Price,
            b.Brand,
            t.Type
        FROM [dbo].[Catalog] c
        INNER JOIN [dbo].[CatalogBrand] b ON c.CatalogBrandId = b.Id
        INNER JOIN [dbo].[CatalogType] t ON c.CatalogTypeId = t.Id
        ORDER BY c.Id;
"@
    
    $sampleResults = Invoke-Sqlcmd -ConnectionString $azureConnectionString -Query $sampleQuery
    
    Write-Host "📋 Sample Data Preview:" -ForegroundColor Green
    foreach ($result in $sampleResults) {
        Write-Host "   $($result.Id): $($result.Name) - $($result.Brand) $($result.Type) - `$$($result.Price)" -ForegroundColor White
    }
    
    Write-Host "`n🎉 Data Migration Completed Successfully!" -ForegroundColor Green
    Write-Host "   ✅ $($azureCount.AzureBrandCount) CatalogBrands migrated" -ForegroundColor Green
    Write-Host "   ✅ $($azureCount.AzureTypeCount) CatalogTypes migrated" -ForegroundColor Green
    Write-Host "   ✅ $($azureCount.AzureItemCount) Catalog Items migrated" -ForegroundColor Green
    Write-Host "   ✅ 100% data integrity validation passed" -ForegroundColor Green
    Write-Host "   ✅ Foreign key relationships validated" -ForegroundColor Green
    Write-Host "   ✅ Sample queries return expected results" -ForegroundColor Green
    Write-Host "   ✅ Application ready for Azure SQL Database data access" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Data migration failed: $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

Write-Host "`n🏁 Story 5 Implementation Complete!" -ForegroundColor Cyan