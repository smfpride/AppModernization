using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace eShopLegacyMVC.Models.Infrastructure
{
    public class CatalogDBInitializer
    {
        private CatalogItemHiLoGenerator? indexGenerator;
        private bool useCustomizationData;

        public CatalogDBInitializer()
        {
            useCustomizationData = false;
        }

        public async Task SeedAsync(CatalogDBContext context)
        {
            if (!context.CatalogTypes.Any())
            {
                AddCatalogTypes(context);
            }

            if (!context.CatalogBrands.Any())
            {
                AddCatalogBrands(context);
            }

            if (!context.CatalogItems.Any())
            {
                AddCatalogItems(context);
            }

            await context.SaveChangesAsync();
        }

        private void AddCatalogTypes(CatalogDBContext context)
        {
            var preconfiguredTypes = PreconfiguredData.GetPreconfiguredCatalogTypes();

            int sequenceId = 1;
            foreach (var type in preconfiguredTypes)
            {
                type.Id = sequenceId;
                context.CatalogTypes.Add(type);
                sequenceId++;
            }
        }

        private void AddCatalogBrands(CatalogDBContext context)
        {
            var preconfiguredBrands = PreconfiguredData.GetPreconfiguredCatalogBrands();

            int sequenceId = 1;
            foreach (var brand in preconfiguredBrands)
            {
                brand.Id = sequenceId;
                context.CatalogBrands.Add(brand);
                sequenceId++;
            }
        }

        private void AddCatalogItems(CatalogDBContext context)
        {
            var preconfiguredItems = PreconfiguredData.GetPreconfiguredCatalogItems();

            int sequenceId = 1;
            foreach (var item in preconfiguredItems)
            {
                item.Id = sequenceId;
                context.CatalogItems.Add(item);
                sequenceId++;
            }
        }
    }
}
