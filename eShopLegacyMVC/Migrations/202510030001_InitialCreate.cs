using System.Data.Entity.Migrations;

namespace eShopLegacyMVC.Migrations
{
    public partial class InitialCreate : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.CatalogBrand",
                c => new
                    {
                        Id = c.Int(nullable: false, identity: true),
                        Brand = c.String(nullable: false, maxLength: 100),
                    })
                .PrimaryKey(t => t.Id);
            
            CreateTable(
                "dbo.CatalogType",
                c => new
                    {
                        Id = c.Int(nullable: false, identity: true),
                        Type = c.String(nullable: false, maxLength: 100),
                    })
                .PrimaryKey(t => t.Id);
            
            CreateTable(
                "dbo.Catalog",
                c => new
                    {
                        Id = c.Int(nullable: false),
                        Name = c.String(nullable: false, maxLength: 50),
                        Description = c.String(),
                        Price = c.Decimal(nullable: false, precision: 18, scale: 2),
                        PictureFileName = c.String(nullable: false),
                        CatalogTypeId = c.Int(nullable: false),
                        CatalogBrandId = c.Int(nullable: false),
                        AvailableStock = c.Int(nullable: false),
                        RestockThreshold = c.Int(nullable: false),
                        MaxStockThreshold = c.Int(nullable: false),
                        OnReorder = c.Boolean(nullable: false),
                    })
                .PrimaryKey(t => t.Id)
                .ForeignKey("dbo.CatalogBrand", t => t.CatalogBrandId, cascadeDelete: false)
                .ForeignKey("dbo.CatalogType", t => t.CatalogTypeId, cascadeDelete: false)
                .Index(t => t.CatalogTypeId)
                .Index(t => t.CatalogBrandId);
        }
        
        public override void Down()
        {
            DropForeignKey("dbo.Catalog", "CatalogTypeId", "dbo.CatalogType");
            DropForeignKey("dbo.Catalog", "CatalogBrandId", "dbo.CatalogBrand");
            DropIndex("dbo.Catalog", new[] { "CatalogBrandId" });
            DropIndex("dbo.Catalog", new[] { "CatalogTypeId" });
            DropTable("dbo.Catalog");
            DropTable("dbo.CatalogType");
            DropTable("dbo.CatalogBrand");
        }
    }
}