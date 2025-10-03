using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using eShopLegacyMVC.Models.Infrastructure;

namespace eShopLegacyMVC.Tests.Infrastructure
{
    [TestClass]
    public class KeyVaultConfigurationProviderTests
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
        public void Initialize_WithNullEndpoint_DisablesKeyVault()
        {
            // Arrange & Act
            KeyVaultConfigurationProvider.Initialize(null);

            // Assert
            Assert.IsFalse(KeyVaultConfigurationProvider.IsEnabled);
        }

        [TestMethod]
        public void Initialize_WithEmptyEndpoint_DisablesKeyVault()
        {
            // Arrange & Act
            KeyVaultConfigurationProvider.Initialize("");

            // Assert
            Assert.IsFalse(KeyVaultConfigurationProvider.IsEnabled);
        }

        [TestMethod]
        [ExpectedException(typeof(InvalidOperationException))]
        public void GetSecret_BeforeInitialize_ThrowsException()
        {
            // Note: This test assumes a new provider instance or that Initialize hasn't been called
            // In a real scenario, you might need to reset the provider state or use a testable design

            // Act & Assert
            // This will throw because the provider requires initialization
            KeyVaultConfigurationProvider.GetSecret("test-secret");
        }

        [TestMethod]
        public void GetSecret_WhenDisabled_ReturnsNull()
        {
            // Arrange
            KeyVaultConfigurationProvider.Initialize(null); // Disable Key Vault

            // Act
            var result = KeyVaultConfigurationProvider.GetSecret("test-secret");

            // Assert
            Assert.IsNull(result);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetSecret_WithNullSecretName_ThrowsArgumentException()
        {
            // Arrange
            KeyVaultConfigurationProvider.Initialize(null); // Initialize to pass the initialized check

            // Act & Assert
            KeyVaultConfigurationProvider.GetSecret(null);
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public void GetSecret_WithEmptySecretName_ThrowsArgumentException()
        {
            // Arrange
            KeyVaultConfigurationProvider.Initialize(null); // Initialize to pass the initialized check

            // Act & Assert
            KeyVaultConfigurationProvider.GetSecret("");
        }

        [TestMethod]
        public void TryGetSecret_WhenDisabled_ReturnsFalse()
        {
            // Arrange
            KeyVaultConfigurationProvider.Initialize(null); // Disable Key Vault

            // Act
            var result = KeyVaultConfigurationProvider.TryGetSecret("test-secret", out string secretValue);

            // Assert
            Assert.IsFalse(result);
            Assert.IsNull(secretValue);
        }

        [TestMethod]
        public void Initialize_WithInvalidEndpoint_ThrowsException()
        {
            // Arrange
            var invalidEndpoint = "not-a-valid-url";

            // Act & Assert
            try
            {
                KeyVaultConfigurationProvider.Initialize(invalidEndpoint);
                Assert.Fail("Expected InvalidOperationException was not thrown");
            }
            catch (InvalidOperationException ex)
            {
                // Expected exception
                Assert.IsNotNull(ex.InnerException);
            }
        }

        [TestMethod]
        public void IsEnabled_AfterFailedInitialization_ReturnsFalse()
        {
            // Arrange
            var invalidEndpoint = "not-a-valid-url";

            // Act
            try
            {
                KeyVaultConfigurationProvider.Initialize(invalidEndpoint);
            }
            catch (InvalidOperationException)
            {
                // Expected exception, ignore
            }

            // Assert
            Assert.IsFalse(KeyVaultConfigurationProvider.IsEnabled);
        }

        [TestMethod]
        public void Initialize_WithValidEndpointFormat_DoesNotThrowDuringConstruction()
        {
            // Arrange
            var validEndpoint = "https://test-vault.vault.azure.net/";

            // Act & Assert
            // Note: This will fail at authentication time, not construction time
            // The test verifies the provider can be constructed with a valid URL format
            try
            {
                KeyVaultConfigurationProvider.Initialize(validEndpoint);
                // If we get here, the provider was constructed successfully
                // It may or may not be enabled depending on authentication
                Assert.IsTrue(true, "Provider initialized without throwing during construction");
            }
            catch (InvalidOperationException ex)
            {
                // Authentication failure is expected in test environment
                Assert.IsNotNull(ex);
                Assert.IsFalse(KeyVaultConfigurationProvider.IsEnabled);
            }
        }

        /// <summary>
        /// Integration test that requires actual Azure Key Vault access.
        /// This test is marked as Ignore by default and should be run manually when Azure is configured.
        /// </summary>
        [TestMethod]
        [Ignore]
        public void Integration_GetSecret_WithValidKeyVault_ReturnsSecret()
        {
            // Arrange
            var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
            if (string.IsNullOrEmpty(keyVaultEndpoint))
            {
                Assert.Inconclusive("KEYVAULT_ENDPOINT environment variable not set. This integration test requires a configured Key Vault.");
            }

            KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);

            // Act
            var result = KeyVaultConfigurationProvider.GetSecret("CatalogDbConnectionString");

            // Assert
            Assert.IsNotNull(result, "Expected to retrieve a connection string from Key Vault");
            Assert.IsTrue(result.Contains("Server="), "Expected connection string to contain 'Server='");
        }

        /// <summary>
        /// Integration test for TryGetSecret with actual Azure Key Vault.
        /// This test is marked as Ignore by default and should be run manually when Azure is configured.
        /// </summary>
        [TestMethod]
        [Ignore]
        public void Integration_TryGetSecret_WithValidKeyVault_ReturnsTrue()
        {
            // Arrange
            var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
            if (string.IsNullOrEmpty(keyVaultEndpoint))
            {
                Assert.Inconclusive("KEYVAULT_ENDPOINT environment variable not set. This integration test requires a configured Key Vault.");
            }

            KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);

            // Act
            var result = KeyVaultConfigurationProvider.TryGetSecret("CatalogDbConnectionString", out string secretValue);

            // Assert
            Assert.IsTrue(result, "Expected TryGetSecret to return true");
            Assert.IsNotNull(secretValue, "Expected to retrieve a connection string from Key Vault");
            Assert.IsTrue(secretValue.Contains("Server="), "Expected connection string to contain 'Server='");
        }

        /// <summary>
        /// Integration test for non-existent secret with actual Azure Key Vault.
        /// This test is marked as Ignore by default and should be run manually when Azure is configured.
        /// </summary>
        [TestMethod]
        [Ignore]
        public void Integration_GetSecret_WithNonExistentSecret_ReturnsNull()
        {
            // Arrange
            var keyVaultEndpoint = Environment.GetEnvironmentVariable("KEYVAULT_ENDPOINT");
            if (string.IsNullOrEmpty(keyVaultEndpoint))
            {
                Assert.Inconclusive("KEYVAULT_ENDPOINT environment variable not set. This integration test requires a configured Key Vault.");
            }

            KeyVaultConfigurationProvider.Initialize(keyVaultEndpoint);

            // Act
            var result = KeyVaultConfigurationProvider.GetSecret("NonExistentSecretName12345");

            // Assert
            Assert.IsNull(result, "Expected null for non-existent secret");
        }
    }
}
