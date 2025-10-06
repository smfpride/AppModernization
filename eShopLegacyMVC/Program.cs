using System;
using eShopLegacyMVC.Models;
using eShopLegacyMVC.Models.Infrastructure;
using eShopLegacyMVC.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Linq;
using Microsoft.Extensions.Configuration;
using Azure.Identity;
using Microsoft.AspNetCore.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// Configure Key Vault if endpoint is provided
var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
if (!string.IsNullOrEmpty(keyVaultEndpoint))
{
    var uri = new Uri(keyVaultEndpoint);
    builder.Configuration.AddAzureKeyVault(
        uri,
        new DefaultAzureCredential());
}

// Add services to the container
builder.Services.AddControllersWithViews();

// Configure Entity Framework Core
var useMockData = builder.Configuration.GetValue<bool>("CatalogSettings:UseMockData", false);
if (!useMockData)
{
    var connectionString = builder.Configuration.GetConnectionString("CatalogDBContext");
    
    if (string.IsNullOrEmpty(connectionString))
    {
        throw new InvalidOperationException("Database connection string 'CatalogDBContext' not found. Please check Key Vault configuration.");
    }
    
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

// Add Blob Storage Service
builder.Services.AddScoped<IBlobStorageService, BlobStorageService>();

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

// Add health checks for container monitoring
builder.Services.AddHealthChecks();

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

// Add health check endpoint for container monitoring
app.MapHealthChecks("/health");

// Configure routes
app.MapControllerRoute(
    name: "GetPicRoute",
    pattern: "items/{catalogItemId:int}/pic",
    defaults: new { controller = "Pic", action = "Index" });

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Catalog}/{action=Index}/{id?}");

// Database is already migrated and seeded from Story 3
// No need to run migrations on startup
// Images are already uploaded to blob storage

app.Run();
