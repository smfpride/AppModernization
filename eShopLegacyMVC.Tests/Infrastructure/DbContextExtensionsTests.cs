using System;
using System.Data.Entity;
using eShopLegacyMVC.Models;
using eShopLegacyMVC.Models.Infrastructure;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace eShopLegacyMVC.Tests.Infrastructure
{
    [TestClass]
    public class DbContextResilientExtensionsTests
    {
        private TestDbContext _context;
        private const string TestConnectionString = "Data Source=(localdb)\\MSSQLLocalDB; Initial Catalog=eShopResilienceTest; Integrated Security=True; MultipleActiveResultSets=True;";

        [TestInitialize]
        public void TestInitialize()
        {
            _context = new TestDbContext(TestConnectionString);
            
            if (_context.Database.Exists())
            {
                _context.Database.Delete();
            }
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
        public void CreateDatabaseWithRetry_ShouldCreateDatabase_WhenCalled()
        {
            // Arrange
            Assert.IsFalse(_context.Database.Exists(), "Database should not exist initially");

            // Act
            var created = _context.CreateDatabaseWithRetry();

            // Assert
            Assert.IsTrue(created, "CreateDatabaseWithRetry should return true when database is created");
            Assert.IsTrue(_context.Database.Exists(), "Database should exist after CreateDatabaseWithRetry");
        }

        [TestMethod]
        public void CreateDatabaseWithRetry_ShouldReturnFalse_WhenDatabaseAlreadyExists()
        {
            // Arrange
            _context.Database.CreateIfNotExists();
            Assert.IsTrue(_context.Database.Exists(), "Database should exist before test");

            // Act
            var created = _context.CreateDatabaseWithRetry();

            // Assert
            Assert.IsFalse(created, "CreateDatabaseWithRetry should return false when database already exists");
        }

        [TestMethod]
        public void MigrateDatabaseWithRetry_ShouldInitializeDatabase_WhenCalled()
        {
            // Act & Assert - Should not throw exception
            _context.MigrateDatabaseWithRetry();
            
            // Verify database exists after migration
            Assert.IsTrue(_context.Database.Exists(), "Database should exist after MigrateDatabaseWithRetry");
        }

        [TestMethod]
        public void SaveChangesWithRetry_ShouldSaveChanges_WhenDataIsValid()
        {
            // Arrange
            _context.Database.CreateIfNotExists();
            var testEntity = new TestEntity { Name = "Test Entity", Value = 100 };
            _context.TestEntities.Add(testEntity);

            // Act
            var savedCount = _context.SaveChangesWithRetry();

            // Assert
            Assert.AreEqual(1, savedCount, "Should save exactly one entity");
            
            // Verify entity was saved
            var savedEntity = _context.TestEntities.Find(testEntity.Id);
            Assert.IsNotNull(savedEntity, "Entity should be saved and retrievable");
            Assert.AreEqual("Test Entity", savedEntity.Name, "Entity name should match");
        }

        [TestMethod]
        public void SaveChangesWithRetry_ShouldHandleMultipleEntities()
        {
            // Arrange
            _context.Database.CreateIfNotExists();
            _context.TestEntities.Add(new TestEntity { Name = "Entity 1", Value = 100 });
            _context.TestEntities.Add(new TestEntity { Name = "Entity 2", Value = 200 });
            _context.TestEntities.Add(new TestEntity { Name = "Entity 3", Value = 300 });

            // Act
            var savedCount = _context.SaveChangesWithRetry();

            // Assert
            Assert.AreEqual(3, savedCount, "Should save exactly three entities");
        }

        // Test helper classes
        public class TestDbContext : DbContext
        {
            public TestDbContext(string connectionString) : base(connectionString)
            {
                Database.SetInitializer(new CreateDatabaseIfNotExists<TestDbContext>());
            }

            public DbSet<TestEntity> TestEntities { get; set; }

            protected override void OnModelCreating(DbModelBuilder modelBuilder)
            {
                modelBuilder.Entity<TestEntity>()
                    .HasKey(e => e.Id)
                    .Property(e => e.Id)
                    .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

                modelBuilder.Entity<TestEntity>()
                    .Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100);

                base.OnModelCreating(modelBuilder);
            }
        }

        public class TestEntity
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public int Value { get; set; }
        }
    }
}