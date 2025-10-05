using eShopLegacyMVC.Models;
using eShopLegacyMVC.Models.Infrastructure;
using eShopLegacyMVC.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

var builder = WebApplication.CreateBuilder(args);

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// Configure Key Vault if endpoint is provided
var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
if (!string.IsNullOrEmpty(keyVaultEndpoint))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultEndpoint),
        new Azure.Identity.DefaultAzureCredential());
}

// Add services to the container
builder.Services.AddControllersWithViews();

// Configure Entity Framework Core
var useMockData = builder.Configuration.GetValue<bool>("CatalogSettings:UseMockData", false);
if (!useMockData)
{
    var connectionString = builder.Configuration.GetConnectionString("CatalogDBContext") 
        ?? "Data Source=(localdb)\\MSSQLLocalDB;Initial Catalog=Microsoft.eShopOnContainers.Services.CatalogDb;Integrated Security=True;MultipleActiveResultSets=True;";
    
    builder.Services.AddDbContext<CatalogDBContext>(options =>
        options.UseSqlServer(connectionString));
}

// Register application services
if (useMockData)
{
    builder.Services.AddSingleton<ICatalogService, CatalogServiceMock>();
}
else
{
    builder.Services.AddScoped<ICatalogService, CatalogService>();
}

builder.Services.AddSingleton<CatalogItemHiLoGenerator>();

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add session support
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();
app.UseSession();

// Configure routes
app.MapControllerRoute(
    name: "GetPicRoute",
    pattern: "items/{catalogItemId:int}/pic",
    defaults: new { controller = "Pic", action = "Index" });

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Catalog}/{action=Index}/{id?}");

// Initialize database if needed
if (!useMockData)
{
    using (var scope = app.Services.CreateScope())
    {
        var services = scope.ServiceProvider;
        try
        {
            var context = services.GetRequiredService<CatalogDBContext>();
            // Ensure database is created and migrations are applied
            context.Database.Migrate();
            
            // Seed data if needed
            if (!context.CatalogItems.Any())
            {
                var initializer = new CatalogDBInitializer();
                initializer.SeedAsync(context).Wait();
            }
        }
        catch (Exception ex)
        {
            var logger = services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "An error occurred while migrating or seeding the database.");
        }
    }
}

app.Run();
