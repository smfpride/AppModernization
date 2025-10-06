using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

namespace eShopLegacyMVC.Services
{
    public class ImageUploadService
    {
        private readonly IBlobStorageService _blobStorageService;
        private readonly ILogger<ImageUploadService> _logger;
        private readonly string _webRootPath;

        public ImageUploadService(IBlobStorageService blobStorageService, ILogger<ImageUploadService> logger, string webRootPath)
        {
            _blobStorageService = blobStorageService;
            _logger = logger;
            _webRootPath = webRootPath;
        }

        public async Task UploadAllImagesAsync()
        {
            try
            {
                // Upload from original Pics folder first if it exists
                var picsPath = Path.Combine(Directory.GetCurrentDirectory(), "Pics");
                if (Directory.Exists(picsPath))
                {
                    await UploadImagesFromDirectory(picsPath, "Pics");
                }

                // Also upload from wwwroot/pics if it exists
                var wwwrootPicsPath = Path.Combine(_webRootPath, "pics");
                if (Directory.Exists(wwwrootPicsPath))
                {
                    await UploadImagesFromDirectory(wwwrootPicsPath, "wwwroot/pics");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during image upload initialization");
            }
        }

        private async Task UploadImagesFromDirectory(string directoryPath, string source)
        {
            _logger.LogInformation("Uploading images from {Source} directory: {Path}", source, directoryPath);

            var imageFiles = Directory.GetFiles(directoryPath, "*.png");
            _logger.LogInformation("Found {Count} PNG files in {Source}", imageFiles.Length, source);

            foreach (var imageFile in imageFiles)
            {
                try
                {
                    var fileName = Path.GetFileName(imageFile);
                    var imageExists = await _blobStorageService.ImageExistsAsync(fileName);
                    
                    if (!imageExists)
                    {
                        var imageData = await File.ReadAllBytesAsync(imageFile);
                        var uploaded = await _blobStorageService.UploadImageAsync(fileName, imageData);
                        
                        if (uploaded)
                        {
                            _logger.LogInformation("Successfully uploaded {FileName} from {Source}", fileName, source);
                        }
                        else
                        {
                            _logger.LogWarning("Failed to upload {FileName} from {Source}", fileName, source);
                        }
                    }
                    else
                    {
                        _logger.LogInformation("Image {FileName} already exists in blob storage", fileName);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error uploading {ImageFile}", imageFile);
                }
            }
        }
    }
}