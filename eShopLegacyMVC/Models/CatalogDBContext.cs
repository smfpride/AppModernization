﻿using eShopLegacyMVC.Models.Infrastructure;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;
using System.Data.Entity.Migrations;
using System.Data.Entity.ModelConfiguration;
using System.Data.Entity.SqlServer;

namespace eShopLegacyMVC.Models
{
    public class CatalogDBContext : DbContext
    {
        public CatalogDBContext() : base(GetConnectionString())
        {
            ConfigureAzureResilience();
        }

        public CatalogDBContext(string connectionString) : base(connectionString)
        {
            ConfigureAzureResilience();
        }

        /// <summary>
        /// Configures Azure SQL Database resilience patterns and connection strategies
        /// </summary>
        private void ConfigureAzureResilience()
        {
            // Set command timeout for long-running operations (default is 30 seconds)
            Database.CommandTimeout = 60;
            
            // Configure connection resiliency for Azure SQL Database
            // This will be handled by our custom resilience provider
        }

        private static string GetConnectionString()
        {
            return Infrastructure.ConfigurationProvider.GetConnectionString("CatalogDBContext");
        }

        public DbSet<CatalogItem> CatalogItems { get; set; }

        public DbSet<CatalogBrand> CatalogBrands { get; set; }

        public DbSet<CatalogType> CatalogTypes { get; set; }

        protected override void OnModelCreating(DbModelBuilder builder)
        {
            ConfigureCatalogType(builder.Entity<CatalogType>());
            ConfigureCatalogBrand(builder.Entity<CatalogBrand>());
            ConfigureCatalogItem(builder.Entity<CatalogItem>());

            base.OnModelCreating(builder);
        }

        void ConfigureCatalogType(EntityTypeConfiguration<CatalogType> builder)
        {
            builder.ToTable("CatalogType");

            builder.HasKey(ci => ci.Id);

            builder.Property(ci => ci.Id)
               .IsRequired();

            builder.Property(cb => cb.Type)
                .IsRequired()
                .HasMaxLength(100);
        }

        void ConfigureCatalogBrand(EntityTypeConfiguration<CatalogBrand> builder)
        {
            builder.ToTable("CatalogBrand");

            builder.HasKey(ci => ci.Id);

            builder.Property(ci => ci.Id)
               .IsRequired();

            builder.Property(cb => cb.Brand)
                .IsRequired()
                .HasMaxLength(100);
        }

        void ConfigureCatalogItem(EntityTypeConfiguration<CatalogItem> builder)
        {
            builder.ToTable("Catalog");

            builder.HasKey(ci => ci.Id);

            builder.Property(ci => ci.Id)
                .HasDatabaseGeneratedOption(DatabaseGeneratedOption.None)
                .IsRequired();

            builder.Property(ci => ci.Name)
                .IsRequired()
                .HasMaxLength(50);

            builder.Property(ci => ci.Price)
                .IsRequired();

            builder.Property(ci => ci.PictureFileName)
                .IsRequired();

            builder.Ignore(ci => ci.PictureUri);

            builder.HasRequired<CatalogBrand>(ci => ci.CatalogBrand)
                .WithMany()
                .HasForeignKey(ci => ci.CatalogBrandId);

            builder.HasRequired<CatalogType>(ci => ci.CatalogType)
                .WithMany()
                .HasForeignKey(ci => ci.CatalogTypeId);
        }
    }
}
