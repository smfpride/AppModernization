using eShopLegacyMVC.Services;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eShopLegacyMVC.Controllers
{
    public class PicController : Controller
    {
        private readonly ILogger<PicController> _logger;
        private readonly ICatalogService _service;
        private readonly IBlobStorageService _blobStorageService;

        public const string GetPicRouteName = "GetPicRouteTemplate";

        public PicController(ICatalogService service, ILogger<PicController> logger, IBlobStorageService blobStorageService)
        {
            _service = service;
            _logger = logger;
            _blobStorageService = blobStorageService;
        }

        /// <summary>
        /// Serves product images from Azure Blob Storage by redirecting to blob URLs
        /// </summary>
        /// <param name="catalogItemId">The catalog item ID</param>
        /// <returns>Redirect to Azure Blob Storage URL or NotFound if image doesn't exist</returns>
        [HttpGet]
        [Route("items/{catalogItemId:int}/pic", Name = GetPicRouteName)]
        public async Task<IActionResult> Index(int catalogItemId)
        {
            _logger.LogInformation("Requesting product image for catalog item {CatalogItemId}", catalogItemId);

            if (catalogItemId <= 0)
            {
                return BadRequest();
            }

            var item = _service.FindCatalogItem(catalogItemId);

            if (item != null)
            {
                // Get the blob storage URL for the product image
                var blobUrl = await _blobStorageService.GetImageUrlAsync(item.PictureFileName);
                if (!string.IsNullOrEmpty(blobUrl))
                {
                    // Verify the image exists in blob storage before redirecting
                    var imageExists = await _blobStorageService.ImageExistsAsync(item.PictureFileName);
                    if (imageExists)
                    {
                        // Redirect client to Azure Blob Storage URL
                        return Redirect(blobUrl);
                    }
                }

                // Image not found in blob storage
                _logger.LogWarning("Product image {PictureFileName} not found in blob storage for item {CatalogItemId}", item.PictureFileName, catalogItemId);
                return NotFound();
            }

            // Catalog item not found
            return NotFound();
        }

        private string GetImageMimeTypeFromImageFileExtension(string extension)
        {
            string mimetype;

            switch (extension)
            {
                case ".png":
                    mimetype = "image/png";
                    break;
                case ".gif":
                    mimetype = "image/gif";
                    break;
                case ".jpg":
                case ".jpeg":
                    mimetype = "image/jpeg";
                    break;
                case ".bmp":
                    mimetype = "image/bmp";
                    break;
                case ".tiff":
                    mimetype = "image/tiff";
                    break;
                case ".wmf":
                    mimetype = "image/wmf";
                    break;
                case ".jp2":
                    mimetype = "image/jp2";
                    break;
                case ".svg":
                    mimetype = "image/svg+xml";
                    break;
                default:
                    mimetype = "application/octet-stream";
                    break;
            }

            return mimetype;
        }
    }
}
