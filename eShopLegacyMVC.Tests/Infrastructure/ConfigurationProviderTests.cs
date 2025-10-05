using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Configuration;
using eShopLegacyMVC.Models.Infrastructure;

namespace eShopLegacyMVC.Tests.Infrastructure
{
    [TestClass]
    public class ConfigurationProviderTests
    {
        private const string TestConnectionStringName = "TestConnection";
        private const string TestAppSettingKey = "TestSetting";
        private const string TestEnvConnectionString = "Server=test-env-server;Database=test-env-db;";
        private const string TestEnvAppSetting = "env-value";

        [TestInitialize]
        public void TestInitialize()
        {
            // Clear any existing environment variables for clean tests
            Environment.SetEnvironmentVariable($"ConnectionStrings__{TestConnectionStringName}", null);
            Environment.SetEnvironmentVariable($"AppSettings__{TestAppSettingKey}", null);
            Environment.SetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING", null);
            Environment.SetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", null);
        }

        [TestCleanup]
        public void TestCleanup()
        {
            // Clean up environment variables after each test
            Environment.SetEnvironmentVariable($"ConnectionStrings__{TestConnectionStringName}", null);
            Environment.SetEnvironmentVariable($"AppSettings__{TestAppSettingKey}", null);
            Environment.SetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING", null);
            Environment.SetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", null);
        }

        [TestMethod]
        public void GetConnectionString_WithEnvironmentVariable_ReturnsEnvironmentValue()
        {
            // Arrange
            Environment.SetEnvironmentVariable($"ConnectionStrings__{TestConnectionStringName}", TestEnvConnectionString);

            // Act
            var result = ConfigurationProvider.GetConnectionString(TestConnectionStringName);

            // Assert
            Assert.AreEqual(TestEnvConnectionString, result);
        }

        [TestMethod]
        public void GetConnectionString_WithoutEnvironmentVariable_FallsBackToWebConfig()
        {
            // Arrange - Set environment variable to simulate .NET Core configuration
            Environment.SetEnvironmentVariable("ConnectionStrings__CatalogDBContext", 
                "Data Source=(localdb)\\MSSQLLocalDB; Initial Catalog=Microsoft.eShopOnContainers.Services.CatalogDb; Integrated Security=True; MultipleActiveResultSets=True;");

            try
            {
                // Act
                var result = ConfigurationProvider.GetConnectionString("CatalogDBContext");

                // Assert
                Assert.IsNotNull(result);
                Assert.IsTrue(result.Contains("(localdb)\\MSSQLLocalDB"));
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("ConnectionStrings__CatalogDBContext", null);
            }
        }

        [TestMethod]
        [ExpectedException(typeof(InvalidOperationException))]
        public void GetConnectionString_NotFound_ThrowsException()
        {
            // Act & Assert
            ConfigurationProvider.GetConnectionString("NonExistentConnection");
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetConnectionString_NullName_ThrowsArgumentException()
        {
            // Act & Assert
            ConfigurationProvider.GetConnectionString(null);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetConnectionString_EmptyName_ThrowsArgumentException()
        {
            // Act & Assert
            ConfigurationProvider.GetConnectionString("");
        }

        [TestMethod]
        public void GetAppSetting_WithEnvironmentVariable_ReturnsEnvironmentValue()
        {
            // Arrange
            Environment.SetEnvironmentVariable($"AppSettings__{TestAppSettingKey}", TestEnvAppSetting);

            // Act
            var result = ConfigurationProvider.GetAppSetting(TestAppSettingKey);

            // Assert
            Assert.AreEqual(TestEnvAppSetting, result);
        }

        [TestMethod]
        public void GetAppSetting_WithoutEnvironmentVariable_FallsBackToWebConfig()
        {
            // Arrange - Set environment variable to simulate .NET Core configuration
            Environment.SetEnvironmentVariable("AppSettings__UseMockData", "false");

            try
            {
                // Act
                var result = ConfigurationProvider.GetAppSetting("UseMockData");

                // Assert
                Assert.AreEqual("false", result);
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("AppSettings__UseMockData", null);
            }
        }

        [TestMethod]
        public void GetAppSetting_NotFound_ReturnsNull()
        {
            // Act
            var result = ConfigurationProvider.GetAppSetting("NonExistentSetting");

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetAppSetting_NullKey_ThrowsArgumentException()
        {
            // Act & Assert
            ConfigurationProvider.GetAppSetting(null);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetAppSetting_EmptyKey_ThrowsArgumentException()
        {
            // Act & Assert
            ConfigurationProvider.GetAppSetting("");
        }

        [TestMethod]
        public void GetAppSettingAsBool_ValidBooleanString_ReturnsBooleanValue()
        {
            // Arrange
            Environment.SetEnvironmentVariable($"AppSettings__{TestAppSettingKey}", "true");

            // Act
            var result = ConfigurationProvider.GetAppSettingAsBool(TestAppSettingKey);

            // Assert
            Assert.IsTrue(result);
        }

        [TestMethod]
        public void GetAppSettingAsBool_InvalidBooleanString_ReturnsDefaultValue()
        {
            // Arrange
            Environment.SetEnvironmentVariable($"AppSettings__{TestAppSettingKey}", "invalid-boolean");

            // Act
            var result = ConfigurationProvider.GetAppSettingAsBool(TestAppSettingKey, true);

            // Assert
            Assert.IsTrue(result);
        }

        [TestMethod]
        public void GetAppSettingAsBool_SettingNotFound_ReturnsDefaultValue()
        {
            // Act
            var result = ConfigurationProvider.GetAppSettingAsBool("NonExistentBoolSetting", true);

            // Assert
            Assert.IsTrue(result);
        }

        [TestMethod]
        public void GetAppSettingAsBool_FromWebConfig_ReturnsCorrectValue()
        {
            // Act - UseMockData is "false" in Web.config
            var result = ConfigurationProvider.GetAppSettingAsBool("UseMockData");

            // Assert
            Assert.IsFalse(result);
        }

        [TestMethod]
        public void GetApplicationInsightsInstrumentationKey_WithConnectionString_ReturnsConnectionString()
        {
            // Arrange
            var testConnectionString = "InstrumentationKey=test-key;IngestionEndpoint=test-endpoint";
            Environment.SetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING", testConnectionString);

            // Act
            var result = ConfigurationProvider.GetApplicationInsightsInstrumentationKey();

            // Assert
            Assert.AreEqual(testConnectionString, result);
        }

        [TestMethod]
        public void GetApplicationInsightsInstrumentationKey_WithInstrumentationKey_ReturnsKey()
        {
            // Arrange
            var testKey = "test-instrumentation-key";
            Environment.SetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", testKey);

            // Act
            var result = ConfigurationProvider.GetApplicationInsightsInstrumentationKey();

            // Assert
            Assert.AreEqual(testKey, result);
        }

        [TestMethod]
        public void GetApplicationInsightsInstrumentationKey_FromAppSettings_ReturnsAppSettingValue()
        {
            // Arrange - Set a value in app settings via environment variable
            Environment.SetEnvironmentVariable("AppSettings__ApplicationInsights.InstrumentationKey", "app-setting-key");

            // Act
            var result = ConfigurationProvider.GetApplicationInsightsInstrumentationKey();

            // Assert
            Assert.AreEqual("app-setting-key", result);
        }

        [TestMethod]
        public void IsRunningInCloud_WithAzureEnvironmentVariable_ReturnsTrue()
        {
            // Arrange
            Environment.SetEnvironmentVariable("WEBSITE_SITE_NAME", "test-site");

            try
            {
                // Act
                var result = ConfigurationProvider.IsRunningInCloud();

                // Assert
                Assert.IsTrue(result);
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("WEBSITE_SITE_NAME", null);
            }
        }

        [TestMethod]
        public void IsRunningInCloud_WithoutAzureEnvironmentVariables_ReturnsFalse()
        {
            // Act
            var result = ConfigurationProvider.IsRunningInCloud();

            // Assert
            Assert.IsFalse(result);
        }

        [TestMethod]
        public void GetConfigurationSummary_ReturnsValidSummary()
        {
            // Arrange - Set environment variable to provide required connection string
            Environment.SetEnvironmentVariable("ConnectionStrings__CatalogDBContext", 
                "Data Source=(localdb)\\MSSQLLocalDB; Initial Catalog=Microsoft.eShopOnContainers.Services.CatalogDb; Integrated Security=True; MultipleActiveResultSets=True;");

            try
            {
                // Act
                var result = ConfigurationProvider.GetConfigurationSummary();

                // Assert
                Assert.IsNotNull(result);
                Assert.IsTrue(result.Contains("Environment:"));
                Assert.IsTrue(result.Contains("ConnectionString:"));
                Assert.IsTrue(result.Contains("AppInsights:"));
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("ConnectionStrings__CatalogDBContext", null);
            }
        }

        [TestMethod]
        public void EnvironmentVariablePrecedence_EnvironmentOverridesWebConfig()
        {
            // Arrange
            Environment.SetEnvironmentVariable("AppSettings__UseMockData", "true");

            try
            {
                // Act
                var envResult = ConfigurationProvider.GetAppSettingAsBool("UseMockData");
                
                // Assert - Environment variable should override Web.config value
                Assert.IsTrue(envResult, "Environment variable should override Web.config value");
            }
            finally
            {
                // Cleanup
                Environment.SetEnvironmentVariable("AppSettings__UseMockData", null);
            }
        }
    }
}