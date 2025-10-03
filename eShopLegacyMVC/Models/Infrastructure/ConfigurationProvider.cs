using System;
using System.Configuration;

namespace eShopLegacyMVC.Models.Infrastructure
{
    /// <summary>
    /// Configuration provider that reads settings from environment variables first,
    /// then falls back to Web.config for local development compatibility.
    /// Follows Azure best practices for externalized configuration.
    /// </summary>
    public static class ConfigurationProvider
    {
        /// <summary>
        /// Gets a connection string by name, checking environment variables first,
        /// then falling back to ConnectionStrings section in Web.config
        /// </summary>
        /// <param name="name">The name of the connection string</param>
        /// <returns>The connection string value</returns>
        /// <exception cref="InvalidOperationException">Thrown when connection string is not found</exception>
        public static string GetConnectionString(string name)
        {
            if (string.IsNullOrEmpty(name))
                throw new ArgumentException("Connection string name cannot be null or empty", nameof(name));

            // Check environment variable first (Azure-friendly approach)
            var envVarName = $"ConnectionStrings__{name}";
            var connectionString = Environment.GetEnvironmentVariable(envVarName);
            
            if (!string.IsNullOrEmpty(connectionString))
            {
                return connectionString;
            }

            // Fallback to Web.config for local development
            var configConnectionString = ConfigurationManager.ConnectionStrings[name];
            if (configConnectionString != null && !string.IsNullOrEmpty(configConnectionString.ConnectionString))
            {
                return configConnectionString.ConnectionString;
            }

            throw new InvalidOperationException($"Connection string '{name}' not found in environment variables or Web.config");
        }

        /// <summary>
        /// Gets an application setting by key, checking environment variables first,
        /// then falling back to AppSettings section in Web.config
        /// </summary>
        /// <param name="key">The setting key</param>
        /// <returns>The setting value or null if not found</returns>
        public static string GetAppSetting(string key)
        {
            if (string.IsNullOrEmpty(key))
                throw new ArgumentException("App setting key cannot be null or empty", nameof(key));

            // Check environment variable first (Azure-friendly approach)
            var envVarName = $"AppSettings__{key}";
            var envValue = Environment.GetEnvironmentVariable(envVarName);
            
            if (!string.IsNullOrEmpty(envValue))
            {
                return envValue;
            }

            // Fallback to Web.config for local development
            return ConfigurationManager.AppSettings[key];
        }

        /// <summary>
        /// Gets an application setting as a boolean value
        /// </summary>
        /// <param name="key">The setting key</param>
        /// <param name="defaultValue">Default value if setting is not found or cannot be parsed</param>
        /// <returns>The boolean value</returns>
        public static bool GetAppSettingAsBool(string key, bool defaultValue = false)
        {
            var value = GetAppSetting(key);
            
            if (string.IsNullOrEmpty(value))
                return defaultValue;

            if (bool.TryParse(value, out bool result))
                return result;

            return defaultValue;
        }

        /// <summary>
        /// Gets the Application Insights instrumentation key from environment variables first,
        /// then falls back to Web.config appSettings
        /// </summary>
        /// <returns>The instrumentation key or null if not configured</returns>
        public static string GetApplicationInsightsInstrumentationKey()
        {
            // Check for Azure standard environment variable
            var instrumentationKey = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
            
            if (!string.IsNullOrEmpty(instrumentationKey))
            {
                return instrumentationKey;
            }

            // Check for legacy instrumentation key format
            instrumentationKey = Environment.GetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY");
            
            if (!string.IsNullOrEmpty(instrumentationKey))
            {
                return instrumentationKey;
            }

            // Fallback to app settings
            return GetAppSetting("ApplicationInsights.InstrumentationKey");
        }

        /// <summary>
        /// Checks if the application is running in a cloud environment
        /// </summary>
        /// <returns>True if running in cloud, false otherwise</returns>
        public static bool IsRunningInCloud()
        {
            // Check for Azure-specific environment variables
            return !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("WEBSITE_SITE_NAME")) ||
                   !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("AZURE_CLIENT_ID"));
        }

        /// <summary>
        /// Gets configuration summary for debugging purposes (without exposing sensitive values)
        /// </summary>
        /// <returns>Configuration summary string</returns>
        public static string GetConfigurationSummary()
        {
            var isCloud = IsRunningInCloud();
            var hasConnectionString = !string.IsNullOrEmpty(GetConnectionString("CatalogDBContext"));
            var hasAppInsights = !string.IsNullOrEmpty(GetApplicationInsightsInstrumentationKey());
            
            return $"Environment: {(isCloud ? "Cloud" : "Local")}, " +
                   $"ConnectionString: {(hasConnectionString ? "Configured" : "Missing")}, " +
                   $"AppInsights: {(hasAppInsights ? "Configured" : "Missing")}";
        }
    }
}