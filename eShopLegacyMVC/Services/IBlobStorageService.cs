using System.Threading.Tasks;

namespace eShopLegacyMVC.Services
{
    public interface IBlobStorageService
    {
        Task<string> GetImageUrlAsync(string fileName);
        Task<bool> UploadImageAsync(string fileName, byte[] imageData);
        Task<bool> ImageExistsAsync(string fileName);
    }
}