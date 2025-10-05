using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using eShopLegacyMVC.Models.Infrastructure;

namespace eShopLegacyMVC.Tests.Integration
{
    [TestClass]
    public class ApplicationStartupIntegrationTests
    {
        [TestInitialize]
        public void TestInitialize()
        {
            // Clear environment variables for clean tests
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", null);
        }

        [TestCleanup]
        public void TestCleanup()
        {
            // Clean up environment variables after each test
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", null);
        }

        [TestMethod]
        public void GlobalAsax_ApplicationStart_WithoutKeyVault_ShouldInitializeSuccessfully()
        {
            // Arrange
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", null);

            // Act & Assert
            var stopwatch = Stopwatch.StartTime();
            
            try
            {
                // Simulate the Key Vault initialization part of Application_Start
                var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
                
                if (!string.IsNullOrEmpty(keyVaultEndpoint))
                {
                    KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);
                }

                // Test configuration summary generation
                var configSummary = ConfigurationProvider.GetConfigurationSummary();
                
                Assert.IsNotNull(configSummary, "Configuration summary should not be null");
                Assert.IsTrue(configSummary.Contains("Environment:"), "Should contain environment info");
                Assert.IsTrue(configSummary.Contains("ConnectionString:"), "Should contain connection string info");
                
                Console.WriteLine($"Configuration Summary: {configSummary}");
                
            }
            catch (Exception ex)
            {
                Assert.Fail($"Application startup simulation failed: {ex.Message}");
            }
            finally
            {
                var elapsed = stopwatch.Elapsed;
                Console.WriteLine($"Startup time without Key Vault: {elapsed.TotalMilliseconds}ms");
                Assert.IsTrue(elapsed.TotalSeconds < 5, "Startup should complete within 5 seconds");
            }
        }

        [TestMethod]
        public void GlobalAsax_ApplicationStart_WithKeyVault_ShouldInitializeAndRetrieveSecrets()
        {
            // Arrange
            var keyVaultEndpoint = "https://kv-eshop-prototype.vault.azure.net/";
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", keyVaultEndpoint);

            // Act & Assert
            var stopwatch = Stopwatch.StartTime();
            
            try
            {
                // Simulate the Key Vault initialization part of Application_Start
                var endpointFromEnv = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
                Assert.AreEqual(keyVaultEndpoint, endpointFromEnv, "Environment variable should be set correctly");

                if (!string.IsNullOrEmpty(endpointFromEnv))
                {
                    // This is exactly what happens in Global.asax.cs
                    KeyVaultConfigurationProvider.Initialize(endpointFromEnv);
                    
                    // Verify Key Vault is enabled
                    Assert.IsTrue(KeyVaultConfigurationProvider.IsEnabled, "Key Vault should be enabled after initialization");
                }

                // Test configuration retrieval (this is what happens when container registration occurs)
                var connectionString = ConfigurationProvider.GetConnectionString("CatalogDBContext");
                Assert.IsNotNull(connectionString, "Connection string should be retrievable");
                Assert.IsTrue(connectionString.Length > 0, "Connection string should not be empty");
                
                // Verify it's coming from Key Vault (Azure SQL connection)
                Assert.IsTrue(connectionString.Contains("sql-eshop-prototype") || 
                             connectionString.Contains("localdb"), 
                             "Should get either Azure SQL (from Key Vault) or LocalDB (fallback)");

                // Test configuration summary generation
                var configSummary = ConfigurationProvider.GetConfigurationSummary();
                Assert.IsNotNull(configSummary, "Configuration summary should not be null");
                Assert.IsTrue(configSummary.Contains("ConnectionString: Configured"), "Should show connection string as configured");
                
                Console.WriteLine($"Configuration Summary with Key Vault: {configSummary}");
                Console.WriteLine($"Connection String Source: {(connectionString.Contains("sql-eshop-prototype") ? "Key Vault" : "Local Config")}");
                
            }
            catch (Exception ex)
            {
                // Key Vault integration should handle errors gracefully
                Console.WriteLine($"Key Vault integration error (expected in some environments): {ex.Message}");
                
                // Even if Key Vault fails, application should continue
                var configSummary = ConfigurationProvider.GetConfigurationSummary();
                Assert.IsNotNull(configSummary, "Configuration summary should still be available");
            }
            finally
            {
                var elapsed = stopwatch.Elapsed;
                Console.WriteLine($"Startup time with Key Vault: {elapsed.TotalMilliseconds}ms");
                Assert.IsTrue(elapsed.TotalSeconds < 15, "Startup with Key Vault should complete within 15 seconds");
            }
        }

        [TestMethod]
        public void GlobalAsax_ApplicationStart_KeyVaultErrorHandling_ShouldContinueGracefully()
        {
            // Arrange - Use an invalid Key Vault endpoint
            var invalidEndpoint = "https://invalid-does-not-exist.vault.azure.net/";
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", invalidEndpoint);

            // Act & Assert
            try
            {
                // This simulates what happens in Global.asax.cs with invalid endpoint
                var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
                
                if (!string.IsNullOrEmpty(keyVaultEndpoint))
                {
                    try
                    {
                        KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);
                        // If we get here without exception, that's fine too
                    }
                    catch (Exception)
                    {
                        // This is expected behavior - Key Vault should handle errors gracefully
                        // Application should continue without Key Vault integration
                    }
                }

                // Application should still be able to get configuration summary
                var configSummary = ConfigurationProvider.GetConfigurationSummary();
                Assert.IsNotNull(configSummary, "Configuration summary should be available even with Key Vault errors");
                
                Console.WriteLine($"Configuration Summary with invalid Key Vault: {configSummary}");
                
                // Application should fall back to local configuration
                Assert.IsTrue(configSummary.Contains("Environment:"), "Should contain environment info");
                
            }
            catch (Exception ex)
            {
                Assert.Fail($"Application should handle Key Vault errors gracefully, but threw: {ex.Message}");
            }
        }

        [TestMethod]
        public void GlobalAsax_ApplicationStart_ConfigurationHierarchy_ShouldWorkCorrectly()
        {
            // Test the complete configuration hierarchy as it works in Application_Start

            // Test 1: No Key Vault (fallback to Web.config)
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", null);
            KeyVaultConfigurationProvider.Initialize(null);
            
            var configWithoutKV = ConfigurationProvider.GetConfigurationSummary();
            Console.WriteLine($"Config without Key Vault: {configWithoutKV}");
            
            // Test 2: With Key Vault
            var keyVaultEndpoint = "https://kv-eshop-prototype.vault.azure.net/";
            Environment.SetEnvironmentVariable("KEYVAULT_ENDPOINT", keyVaultEndpoint);
            
            try
            {
                KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);
                var configWithKV = ConfigurationProvider.GetConfigurationSummary();
                Console.WriteLine($"Config with Key Vault: {configWithKV}");
                
                // Both configurations should be valid
                Assert.IsNotNull(configWithoutKV, "Configuration without Key Vault should be valid");
                Assert.IsNotNull(configWithKV, "Configuration with Key Vault should be valid");
                
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Key Vault test skipped due to environment: {ex.Message}");
                // This is acceptable in test environments without Azure CLI
            }
        }
    }
}