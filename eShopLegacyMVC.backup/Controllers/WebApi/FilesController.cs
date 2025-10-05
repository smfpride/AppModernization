// using eShopLegacy.Utilities; // Commented out - missing dependency
using eShopLegacyMVC.Services;
using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.IO;

namespace eShopLegacyMVC.Controllers.WebApi
{
    public class FilesController : ApiController
    {
        private ICatalogService _service;

        public FilesController(ICatalogService service)
        {
            _service = service;
        }

        // GET api/<controller>
        public HttpResponseMessage Get()
        {
            var brands = _service.GetCatalogBrands()
                .Select(b => new BrandDTO
                {
                    Id = b.Id,
                    Brand = b.Brand
                }).ToList();
            
            // Return JSON response instead of binary serialization
            var response = Request.CreateResponse(HttpStatusCode.OK, brands);
            return response;
        }

        [Serializable]
        public class BrandDTO
        {
            public int Id { get; set; }
            public string Brand { get; set; }
        }
    }
}