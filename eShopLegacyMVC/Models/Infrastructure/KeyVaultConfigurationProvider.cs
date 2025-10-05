using Azure.Core;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System;

namespace eShopLegacyMVC.Models.Infrastructure
{
    /// <summary>
    /// Provides access to configuration secrets stored in Azure Key Vault.
    /// Uses DefaultAzureCredential for authentication, which supports:
    /// - Managed Identity (in Azure)
    /// - Azure CLI (local development)
    /// - Visual Studio (local development)
    /// - Environment variables
    /// </summary>
    public class KeyVaultConfigurationProvider
    {
        private static SecretClient? _client;
        private static bool _isInitialized = false;
        private static bool _isEnabled = false;
        private static readonly object _lock = new object();

        /// <summary>
        /// Initializes the Key Vault client with the specified endpoint.
        /// This should be called during application startup.
        /// </summary>
        /// <param name="keyVaultEndpoint">The Key Vault endpoint URL (e.g., https://myvault.vault.azure.net/)</param>
        public static void Initialize(string keyVaultEndpoint)
        {
            lock (_lock)
            {
                if (_isInitialized)
                {
                    Console.WriteLine("Key Vault provider already initialized");
                    return;
                }

                if (string.IsNullOrEmpty(keyVaultEndpoint))
                {
                    Console.WriteLine("Key Vault endpoint not configured. Key Vault integration disabled.");
                    _isInitialized = true;
                    _isEnabled = false;
                    return;
                }

                try
                {
                    Console.WriteLine($"Initializing Key Vault client for endpoint: {keyVaultEndpoint}");

                    // Create DefaultAzureCredential with options
                    var credentialOptions = new DefaultAzureCredentialOptions
                    {
                        // Exclude interactive browser credential for server environments
                        ExcludeInteractiveBrowserCredential = true,
                        // Try these in order: Environment, Managed Identity, Azure CLI, Visual Studio
                        ExcludeManagedIdentityCredential = false,
                        ExcludeAzureCliCredential = false,
                        ExcludeVisualStudioCredential = false
                    };

                    var credential = new DefaultAzureCredential(credentialOptions);
                    _client = new SecretClient(new Uri(keyVaultEndpoint), credential);

                    _isEnabled = true;
                    _isInitialized = true;
                    Console.WriteLine("Key Vault client initialized successfully");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to initialize Key Vault client: {ex.Message}");
                    _isInitialized = true;
                    _isEnabled = false;
                    throw new InvalidOperationException("Failed to initialize Key Vault client", ex);
                }
            }
        }

        /// <summary>
        /// Gets whether the Key Vault provider is enabled and ready to use
        /// </summary>
        public static bool IsEnabled => _isEnabled;

        /// <summary>
        /// Gets a secret from Key Vault by name.
        /// Returns null if Key Vault is not enabled or the secret is not found.
        /// </summary>
        /// <param name="secretName">The name of the secret in Key Vault</param>
        /// <returns>The secret value or null if not found</returns>
        public static string? GetSecret(string secretName)
        {
            if (!_isInitialized)
            {
                throw new InvalidOperationException("Key Vault provider has not been initialized. Call Initialize() first.");
            }

            if (string.IsNullOrEmpty(secretName))
            {
                throw new ArgumentException("Secret name cannot be null or empty", nameof(secretName));
            }

            if (!_isEnabled || _client == null)
            {
                Console.WriteLine($"Key Vault disabled, cannot retrieve secret: {secretName}");
                return null;
            }

            try
            {
                Console.WriteLine($"Retrieving secret from Key Vault: {secretName}");
                
                var secret = _client.GetSecret(secretName);
                
                if (secret?.Value != null)
                {
                    Console.WriteLine($"Successfully retrieved secret: {secretName}");
                    return secret.Value.Value;
                }

                Console.WriteLine($"Secret not found in Key Vault: {secretName}");
                return null;
            }
            catch (Azure.RequestFailedException ex) when (ex.Status == 404)
            {
                Console.WriteLine($"Secret not found in Key Vault: {secretName}");
                return null;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error retrieving secret '{secretName}' from Key Vault: {ex.Message}");
                return null;
            }
        }

        /// <summary>
        /// Attempts to get a secret from Key Vault.
        /// </summary>
        /// <param name="secretName">The name of the secret in Key Vault</param>
        /// <param name="secretValue">The secret value if found</param>
        /// <returns>True if the secret was retrieved successfully, false otherwise</returns>
        public static bool TryGetSecret(string secretName, out string? secretValue)
        {
            secretValue = GetSecret(secretName);
            return !string.IsNullOrEmpty(secretValue);
        }

#if DEBUG
        /// <summary>
        /// Resets the Key Vault provider state for testing purposes.
        /// This method is only available in DEBUG builds.
        /// </summary>
        public static void ResetForTesting()
        {
            lock (_lock)
            {
                _client = null;
                _isInitialized = false;
                _isEnabled = false;
                Console.WriteLine("Key Vault provider state reset for testing");
            }
        }
#endif
    }
}
