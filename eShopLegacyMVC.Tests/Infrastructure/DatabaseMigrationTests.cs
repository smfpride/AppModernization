using System;
using System.Data.Entity;
using System.Linq;
using eShopLegacyMVC.Models;
using eShopLegacyMVC.Models.Infrastructure;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace eShopLegacyMVC.Tests.Infrastructure
{
    [TestClass]
    public class DatabaseMigrationTests
    {
        private CatalogDBContext _context;
        private const string TestConnectionString = "Data Source=(localdb)\\MSSQLLocalDB; Initial Catalog=eShopTest; Integrated Security=True; MultipleActiveResultSets=True;";

        [TestInitialize]
        public void TestInitialize()
        {
            // Use a test database connection string
            _context = new CatalogDBContext(TestConnectionString);
            
            // Ensure clean database state for each test
            if (_context.Database.Exists())
            {
                _context.Database.Delete();
            }
            
            // Create the database and apply migrations
            _context.Database.CreateIfNotExists();
        }

        [TestCleanup]
        public void TestCleanup()
        {
            if (_context != null)
            {
                // Clean up test database
                if (_context.Database.Exists())
                {
                    _context.Database.Delete();
                }
                _context.Dispose();
            }
        }

        [TestMethod]
        public void Database_ShouldBeCreated_WhenContextIsInitialized()
        {
            // Arrange & Act
            var exists = _context.Database.Exists();

            // Assert
            Assert.IsTrue(exists, "Database should be created when context is initialized");
        }

        [TestMethod]
        public void Database_ShouldHaveCorrectTables_WhenMigrationIsApplied()
        {
            // Arrange
            var expectedTables = new[] { "CatalogBrand", "CatalogType", "Catalog" };

            // Act
            var actualTables = _context.Database.SqlQuery<string>(
                @"SELECT TABLE_NAME 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME != '__MigrationsHistory'
                  ORDER BY TABLE_NAME").ToList();

            // Assert
            CollectionAssert.AreEqual(expectedTables.OrderBy(t => t).ToArray(), 
                                    actualTables.OrderBy(t => t).ToArray(),
                                    "Database should contain the expected tables after migration");
        }

        [TestMethod]
        public void CatalogBrand_ShouldHaveCorrectSchema_WhenTableIsCreated()
        {
            // Act
            var columns = _context.Database.SqlQuery<string>(
                @"SELECT COLUMN_NAME 
                  FROM INFORMATION_SCHEMA.COLUMNS 
                  WHERE TABLE_NAME = 'CatalogBrand' 
                  ORDER BY ORDINAL_POSITION").ToList();

            // Assert
            var expectedColumns = new[] { "Id", "Brand" };
            CollectionAssert.AreEqual(expectedColumns, columns, 
                "CatalogBrand table should have the correct columns");
        }

        [TestMethod]
        public void CatalogType_ShouldHaveCorrectSchema_WhenTableIsCreated()
        {
            // Act
            var columns = _context.Database.SqlQuery<string>(
                @"SELECT COLUMN_NAME 
                  FROM INFORMATION_SCHEMA.COLUMNS 
                  WHERE TABLE_NAME = 'CatalogType' 
                  ORDER BY ORDINAL_POSITION").ToList();

            // Assert
            var expectedColumns = new[] { "Id", "Type" };
            CollectionAssert.AreEqual(expectedColumns, columns, 
                "CatalogType table should have the correct columns");
        }

        [TestMethod]
        public void Catalog_ShouldHaveCorrectSchema_WhenTableIsCreated()
        {
            // Act
            var columns = _context.Database.SqlQuery<string>(
                @"SELECT COLUMN_NAME 
                  FROM INFORMATION_SCHEMA.COLUMNS 
                  WHERE TABLE_NAME = 'Catalog' 
                  ORDER BY ORDINAL_POSITION").ToList();

            // Assert
            var expectedColumns = new[] { 
                "Id", "Name", "Description", "Price", "PictureFileName", 
                "CatalogTypeId", "CatalogBrandId", "AvailableStock", 
                "RestockThreshold", "MaxStockThreshold", "OnReorder" 
            };
            CollectionAssert.AreEqual(expectedColumns, columns, 
                "Catalog table should have the correct columns");
        }

        [TestMethod]
        public void ForeignKeys_ShouldExist_WhenTablesAreCreated()
        {
            // Act
            var foreignKeys = _context.Database.SqlQuery<string>(
                @"SELECT 
                    CONCAT(fk.name, ': ', tp.name, '.', cp.name, ' -> ', tr.name, '.', cr.name) as ForeignKey
                  FROM sys.foreign_keys fk
                  INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
                  INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
                  INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
                  INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
                  INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
                  ORDER BY fk.name").ToList();

            // Assert
            Assert.IsTrue(foreignKeys.Count >= 2, "Should have at least 2 foreign key constraints");
            Assert.IsTrue(foreignKeys.Any(fk => fk.Contains("CatalogBrand")), 
                "Should have foreign key to CatalogBrand");
            Assert.IsTrue(foreignKeys.Any(fk => fk.Contains("CatalogType")), 
                "Should have foreign key to CatalogType");
        }
    }

    [TestClass]
    public class CatalogDBContextCrudTests
    {
        private CatalogDBContext _context;
        private const string TestConnectionString = "Data Source=(localdb)\\MSSQLLocalDB; Initial Catalog=eShopCrudTest; Integrated Security=True; MultipleActiveResultSets=True;";

        [TestInitialize]
        public void TestInitialize()
        {
            _context = new CatalogDBContext(TestConnectionString);
            
            if (_context.Database.Exists())
            {
                _context.Database.Delete();
            }
            
            _context.Database.CreateIfNotExists();
        }

        [TestCleanup]
        public void TestCleanup()
        {
            if (_context != null)
            {
                if (_context.Database.Exists())
                {
                    _context.Database.Delete();
                }
                _context.Dispose();
            }
        }

        [TestMethod]
        public void CatalogBrand_CanBeCreatedAndRetrieved()
        {
            // Arrange
            var brand = new CatalogBrand { Brand = "Test Brand" };

            // Act
            _context.CatalogBrands.Add(brand);
            _context.SaveChanges();

            var retrievedBrand = _context.CatalogBrands.FirstOrDefault(b => b.Brand == "Test Brand");

            // Assert
            Assert.IsNotNull(retrievedBrand, "Brand should be retrievable after saving");
            Assert.AreEqual("Test Brand", retrievedBrand.Brand, "Brand name should match");
            Assert.IsTrue(retrievedBrand.Id > 0, "Brand should have an ID assigned");
        }

        [TestMethod]
        public void CatalogType_CanBeCreatedAndRetrieved()
        {
            // Arrange
            var catalogType = new CatalogType { Type = "Test Type" };

            // Act
            _context.CatalogTypes.Add(catalogType);
            _context.SaveChanges();

            var retrievedType = _context.CatalogTypes.FirstOrDefault(t => t.Type == "Test Type");

            // Assert
            Assert.IsNotNull(retrievedType, "Type should be retrievable after saving");
            Assert.AreEqual("Test Type", retrievedType.Type, "Type name should match");
            Assert.IsTrue(retrievedType.Id > 0, "Type should have an ID assigned");
        }

        [TestMethod]
        public void CatalogItem_CanBeCreatedWithForeignKeys()
        {
            // Arrange
            var brand = new CatalogBrand { Brand = "Test Brand" };
            var type = new CatalogType { Type = "Test Type" };
            
            _context.CatalogBrands.Add(brand);
            _context.CatalogTypes.Add(type);
            _context.SaveChanges();

            var item = new CatalogItem
            {
                Id = 1,
                Name = "Test Item",
                Description = "Test Description",
                Price = 29.99m,
                PictureFileName = "test.png",
                CatalogBrandId = brand.Id,
                CatalogTypeId = type.Id,
                AvailableStock = 100,
                RestockThreshold = 10,
                MaxStockThreshold = 200,
                OnReorder = false
            };

            // Act
            _context.CatalogItems.Add(item);
            _context.SaveChanges();

            var retrievedItem = _context.CatalogItems
                .Include(i => i.CatalogBrand)
                .Include(i => i.CatalogType)
                .FirstOrDefault(i => i.Name == "Test Item");

            // Assert
            Assert.IsNotNull(retrievedItem, "Item should be retrievable after saving");
            Assert.AreEqual("Test Item", retrievedItem.Name, "Item name should match");
            Assert.AreEqual(29.99m, retrievedItem.Price, "Item price should match");
            Assert.IsNotNull(retrievedItem.CatalogBrand, "Item should have associated brand");
            Assert.IsNotNull(retrievedItem.CatalogType, "Item should have associated type");
            Assert.AreEqual("Test Brand", retrievedItem.CatalogBrand.Brand, "Associated brand should match");
            Assert.AreEqual("Test Type", retrievedItem.CatalogType.Type, "Associated type should match");
        }

        [TestMethod]
        public void CatalogItem_CanBeUpdated()
        {
            // Arrange
            var brand = new CatalogBrand { Brand = "Test Brand" };
            var type = new CatalogType { Type = "Test Type" };
            
            _context.CatalogBrands.Add(brand);
            _context.CatalogTypes.Add(type);
            _context.SaveChanges();

            var item = new CatalogItem
            {
                Id = 1,
                Name = "Original Name",
                Description = "Original Description",
                Price = 19.99m,
                PictureFileName = "original.png",
                CatalogBrandId = brand.Id,
                CatalogTypeId = type.Id,
                AvailableStock = 50,
                RestockThreshold = 5,
                MaxStockThreshold = 100,
                OnReorder = false
            };

            _context.CatalogItems.Add(item);
            _context.SaveChanges();

            // Act
            var retrievedItem = _context.CatalogItems.First(i => i.Id == 1);
            retrievedItem.Name = "Updated Name";
            retrievedItem.Price = 24.99m;
            retrievedItem.AvailableStock = 75;
            _context.SaveChanges();

            var updatedItem = _context.CatalogItems.First(i => i.Id == 1);

            // Assert
            Assert.AreEqual("Updated Name", updatedItem.Name, "Item name should be updated");
            Assert.AreEqual(24.99m, updatedItem.Price, "Item price should be updated");
            Assert.AreEqual(75, updatedItem.AvailableStock, "Item stock should be updated");
        }

        [TestMethod]
        public void CatalogItem_CanBeDeleted()
        {
            // Arrange
            var brand = new CatalogBrand { Brand = "Test Brand" };
            var type = new CatalogType { Type = "Test Type" };
            
            _context.CatalogBrands.Add(brand);
            _context.CatalogTypes.Add(type);
            _context.SaveChanges();

            var item = new CatalogItem
            {
                Id = 1,
                Name = "Test Item",
                Description = "Test Description",
                Price = 29.99m,
                PictureFileName = "test.png",
                CatalogBrandId = brand.Id,
                CatalogTypeId = type.Id,
                AvailableStock = 100,
                RestockThreshold = 10,
                MaxStockThreshold = 200,
                OnReorder = false
            };

            _context.CatalogItems.Add(item);
            _context.SaveChanges();

            // Act
            var itemToDelete = _context.CatalogItems.First(i => i.Id == 1);
            _context.CatalogItems.Remove(itemToDelete);
            _context.SaveChanges();

            var deletedItem = _context.CatalogItems.FirstOrDefault(i => i.Id == 1);

            // Assert
            Assert.IsNull(deletedItem, "Item should be deleted and not retrievable");
        }
    }
}