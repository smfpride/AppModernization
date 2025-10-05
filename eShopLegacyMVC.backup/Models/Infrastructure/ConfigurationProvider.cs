using System;
using System.Configuration;

namespace eShopLegacyMVC.Models.Infrastructure
{
    /// <summary>
    /// Configuration provider that reads settings from environment variables first,
    /// then falls back to Web.config for local development compatibility.
    /// Follows Azure best practices for externalized configuration.
    /// 
    /// <para>
    /// <b>Environment Variable Naming Convention:</b><br/>
    /// This provider uses double underscores (<c>__</c>) in environment variable names to match .NET Core conventions.
    /// For example, a connection string named <c>CatalogDBContext</c> should be set as <c>ConnectionStrings__CatalogDBContext</c>.
    /// </para>
    /// </summary>
    public static class ConfigurationProvider
    {
        /// <summary>
        /// Gets a connection string by name, checking Key Vault first (if enabled),
        /// then environment variables, and finally falling back to Web.config.
        /// 
        /// <para>
        /// Environment variable names use double underscores (<c>__</c>) as separators, e.g. <c>ConnectionStrings__CatalogDBContext</c>.
        /// </para>
        /// </summary>
        /// <param name="name">The name of the connection string</param>
        /// <returns>The connection string value</returns>
        /// <exception cref="InvalidOperationException">Thrown when connection string is not found</exception>
        public static string GetConnectionString(string name)
        {
            if (string.IsNullOrEmpty(name))
                throw new ArgumentException("Connection string name cannot be null or empty", nameof(name));

            // Check Key Vault first (if enabled)
            if (KeyVaultConfigurationProvider.IsEnabled)
            {
                // Try common Key Vault secret names for connection strings
                // Azure convention: CatalogDbConnectionString
                var keyVaultSecretName = $"{name}ConnectionString";
                if (KeyVaultConfigurationProvider.TryGetSecret(keyVaultSecretName, out string kvConnectionString))
                {
                    return kvConnectionString;
                }

                // Also try the exact name
                if (KeyVaultConfigurationProvider.TryGetSecret(name, out kvConnectionString))
                {
                    return kvConnectionString;
                }
            }

            // Check environment variable (Azure-friendly approach)
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

            throw new InvalidOperationException($"Connection string '{name}' not found in Key Vault, environment variables, or Web.config");
        }

        /// <summary>
        /// Gets an application setting by key, checking environment variables first,
        /// then falling back to AppSettings section in Web.config.
        /// 
        /// <para>
        /// Environment variable names use double underscores (<c>__</c>) as separators, e.g. <c>AppSettings__MySetting</c>.
        /// </para>
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
        /// Gets the Application Insights instrumentation key from Key Vault (if enabled),
        /// then environment variables, and finally falls back to Web.config appSettings
        /// </summary>
        /// <returns>The instrumentation key or null if not configured</returns>
        public static string GetApplicationInsightsInstrumentationKey()
        {
            // Check Key Vault first (if enabled)
            if (KeyVaultConfigurationProvider.IsEnabled)
            {
                // Try common Key Vault secret names
                if (KeyVaultConfigurationProvider.TryGetSecret("ApplicationInsights--InstrumentationKey", out string kvKey))
                {
                    return kvKey;
                }
                if (KeyVaultConfigurationProvider.TryGetSecret("ApplicationInsightsInstrumentationKey", out kvKey))
                {
                    return kvKey;
                }
            }

            // Check for Azure standard environment variable
            var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
            
            if (!string.IsNullOrEmpty(connectionString))
            {
                return connectionString;
            }

            // Check for legacy instrumentation key format
            connectionString = Environment.GetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY");
            
            if (!string.IsNullOrEmpty(connectionString))
            {
                return connectionString;
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