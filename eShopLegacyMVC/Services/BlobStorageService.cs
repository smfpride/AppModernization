using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

namespace eShopLegacyMVC.Services
{
    /// <summary>
    /// Service for managing product images in Azure Blob Storage
    /// </summary>
    public class BlobStorageService : IBlobStorageService
    {
        private readonly BlobServiceClient _blobServiceClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<BlobStorageService> _logger;
        private readonly string _containerName = "productimages";

        public BlobStorageService(IConfiguration configuration, ILogger<BlobStorageService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            var storageAccountName = _configuration["Azure:StorageAccount:Name"] ?? "steshopprototype";
            var storageConnectionString = _configuration.GetConnectionString("StorageAccount-ConnectionString") ??
                                           _configuration["StorageAccount-ConnectionString"] ??
                                           _configuration["ConnectionStrings:StorageAccount-ConnectionString"];

            if (!string.IsNullOrEmpty(storageConnectionString))
            {
                _blobServiceClient = new BlobServiceClient(storageConnectionString);
            }
            else
            {
                // Use Managed Identity in production
                var blobUri = new Uri($"https://{storageAccountName}.blob.core.windows.net");
                _blobServiceClient = new BlobServiceClient(blobUri, new DefaultAzureCredential());
            }
        }

        public Task<string> GetImageUrlAsync(string fileName)
        {
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                
                // Container already exists, no need to create it
                var blobClient = containerClient.GetBlobClient(fileName);
                
                // Return the blob URL
                return Task.FromResult(blobClient.Uri.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting image URL for {FileName}", fileName);
                return Task.FromResult(string.Empty);
            }
        }

        public async Task<bool> UploadImageAsync(string fileName, byte[] imageData)
        {
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                
                // Ensure container exists with public blob access
                await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);
                
                var blobClient = containerClient.GetBlobClient(fileName);
                
                using var stream = new MemoryStream(imageData);
                await blobClient.UploadAsync(stream, overwrite: true);
                
                _logger.LogInformation("Successfully uploaded {FileName} to blob storage", fileName);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading {FileName} to blob storage", fileName);
                return false;
            }
        }

        public async Task<bool> ImageExistsAsync(string fileName)
        {
            try
            {
                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                var blobClient = containerClient.GetBlobClient(fileName);
                
                var response = await blobClient.ExistsAsync();
                return response.Value;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if {FileName} exists in blob storage", fileName);
                return false;
            }
        }
    }
}