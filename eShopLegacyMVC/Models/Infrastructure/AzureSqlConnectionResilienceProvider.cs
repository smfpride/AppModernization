using System;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Threading;
using System.Threading.Tasks;

namespace eShopLegacyMVC.Models.Infrastructure
{
    /// <summary>
    /// Connection resilience provider for Azure SQL Database.
    /// Implements retry policies and transient error handling for cloud database operations.
    /// Follows Azure best practices for connection reliability.
    /// </summary>
    public class AzureSqlConnectionResilienceProvider
    {
        private const int MaxRetryAttempts = 3;
        private const int BaseDelayMs = 1000; // 1 second base delay
        private const int MaxDelayMs = 30000; // 30 seconds max delay

        /// <summary>
        /// SQL error numbers that indicate transient errors that should be retried
        /// Based on Azure SQL Database transient error guidance
        /// </summary>
        private static readonly int[] TransientErrorNumbers = new[]
        {
            4060,   // Database unavailable
            40197,  // Service error processing request
            40501,  // Service currently busy
            40613,  // Database unavailable
            49918,  // Cannot process request, not enough resources
            49919,  // Cannot process create or update request
            49920,  // Cannot process request, too many operations
            20,     // Instance failure
            64,     // Table or view does not exist
            233,    // Connection failure
            10053,  // Connection forcibly closed
            10054,  // Connection reset
            10060,  // Connection timeout
            40143,  // Connection terminated
            40166   // Connection failure during transaction
        };

        /// <summary>
        /// Executes a database operation with retry logic for transient errors
        /// </summary>
        /// <typeparam name="T">Return type of the operation</typeparam>
        /// <param name="operation">The database operation to execute</param>
        /// <param name="operationName">Name of the operation for logging</param>
        /// <returns>Result of the operation</returns>
        public static T ExecuteWithRetry<T>(Func<T> operation, string operationName = "DatabaseOperation")
        {
            Exception lastException = null;
            
            for (int attempt = 0; attempt < MaxRetryAttempts; attempt++)
            {
                try
                {
                    return operation();
                }
                catch (Exception ex) when (IsTransientError(ex))
                {
                    lastException = ex;
                    
                    if (attempt == MaxRetryAttempts - 1)
                    {
                        // Final attempt failed, throw the exception
                        break;
                    }
                    
                    // Calculate delay using exponential backoff with jitter
                    var delay = CalculateDelay(attempt);
                    
                    // Log retry attempt (in production, use proper logging framework)
                    System.Diagnostics.Debug.WriteLine(
                        $"Transient error in {operationName} (attempt {attempt + 1}): {ex.Message}. Retrying in {delay}ms...");
                    
                    Thread.Sleep(delay);
                }
                catch (Exception ex)
                {
                    // Non-transient error, don't retry
                    throw;
                }
            }
            
            // All retry attempts failed
            throw new InvalidOperationException(
                $"Operation {operationName} failed after {MaxRetryAttempts} attempts.", 
                lastException);
        }

        /// <summary>
        /// Executes an async database operation with retry logic for transient errors
        /// </summary>
        /// <typeparam name="T">Return type of the operation</typeparam>
        /// <param name="operation">The async database operation to execute</param>
        /// <param name="operationName">Name of the operation for logging</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Result of the operation</returns>
        public static async Task<T> ExecuteWithRetryAsync<T>(
            Func<Task<T>> operation, 
            string operationName = "DatabaseOperation",
            CancellationToken cancellationToken = default(CancellationToken))
        {
            Exception lastException = null;
            
            for (int attempt = 0; attempt < MaxRetryAttempts; attempt++)
            {
                try
                {
                    return await operation().ConfigureAwait(false);
                }
                catch (Exception ex) when (IsTransientError(ex))
                {
                    lastException = ex;
                    
                    if (attempt == MaxRetryAttempts - 1)
                    {
                        // Final attempt failed, throw the exception
                        break;
                    }
                    
                    // Calculate delay using exponential backoff with jitter
                    var delay = CalculateDelay(attempt);
                    
                    // Log retry attempt (in production, use proper logging framework)
                    System.Diagnostics.Debug.WriteLine(
                        $"Transient error in {operationName} (attempt {attempt + 1}): {ex.Message}. Retrying in {delay}ms...");
                    
                    await Task.Delay(delay, cancellationToken).ConfigureAwait(false);
                }
                catch (Exception ex)
                {
                    // Non-transient error, don't retry
                    throw;
                }
            }
            
            // All retry attempts failed
            throw new InvalidOperationException(
                $"Operation {operationName} failed after {MaxRetryAttempts} attempts.", 
                lastException);
        }

        /// <summary>
        /// Executes a void database operation with retry logic for transient errors
        /// </summary>
        /// <param name="operation">The database operation to execute</param>
        /// <param name="operationName">Name of the operation for logging</param>
        public static void ExecuteWithRetry(Action operation, string operationName = "DatabaseOperation")
        {
            ExecuteWithRetry(() =>
            {
                operation();
                return true; // Return dummy value for the generic method
            }, operationName);
        }

        /// <summary>
        /// Determines if an exception represents a transient error that should be retried
        /// </summary>
        /// <param name="exception">Exception to check</param>
        /// <returns>True if the error is transient and should be retried</returns>
        private static bool IsTransientError(Exception exception)
        {
            // Check for SQL exceptions
            if (exception is SqlException sqlEx)
            {
                foreach (SqlError error in sqlEx.Errors)
                {
                    if (Array.IndexOf(TransientErrorNumbers, error.Number) >= 0)
                    {
                        return true;
                    }
                }
            }

            // Check for Entity Framework exceptions that wrap SQL exceptions
            if (exception is System.Data.Entity.Core.EntityException entityEx && 
                entityEx.InnerException is SqlException innerSqlEx)
            {
                return IsTransientError(innerSqlEx);
            }

            // Check for timeout exceptions
            if (exception is TimeoutException || 
                exception.Message.ToLowerInvariant().Contains("timeout"))
            {
                return true;
            }

            // Check for connection-related exceptions
            var message = exception.Message.ToLowerInvariant();
            if (message.Contains("connection") ||
                message.Contains("network") ||
                message.Contains("transport"))
            {
                return true;
            }

            return false;
        }

        /// <summary>
        /// Calculates retry delay using exponential backoff with jitter
        /// </summary>
        /// <param name="attemptNumber">Current attempt number (0-based)</param>
        /// <returns>Delay in milliseconds</returns>
        private static int CalculateDelay(int attemptNumber)
        {
            // Exponential backoff: base_delay * 2^attempt_number
            var exponentialDelay = BaseDelayMs * Math.Pow(2, attemptNumber);
            
            // Add jitter to prevent thundering herd effect
            var random = new Random();
            var jitter = random.NextDouble() * 0.1; // 10% jitter
            var delayWithJitter = exponentialDelay * (1 + jitter);
            
            // Ensure delay doesn't exceed maximum
            return (int)Math.Min(delayWithJitter, MaxDelayMs);
        }
    }

    /// <summary>
    /// Extension methods for DbContext to add resilient operations
    /// </summary>
    public static class DbContextResilientExtensions
    {
        /// <summary>
        /// Saves changes to the database with retry logic for transient errors
        /// </summary>
        /// <param name="context">The DbContext instance</param>
        /// <returns>Number of state entries written to the database</returns>
        public static int SaveChangesWithRetry(this DbContext context)
        {
            return AzureSqlConnectionResilienceProvider.ExecuteWithRetry(
                () => context.SaveChanges(), 
                "SaveChanges");
        }

        /// <summary>
        /// Asynchronously saves changes to the database with retry logic for transient errors
        /// </summary>
        /// <param name="context">The DbContext instance</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Number of state entries written to the database</returns>
        public static Task<int> SaveChangesWithRetryAsync(this DbContext context, CancellationToken cancellationToken = default(CancellationToken))
        {
            return AzureSqlConnectionResilienceProvider.ExecuteWithRetryAsync(
                () => context.SaveChangesAsync(cancellationToken), 
                "SaveChangesAsync",
                cancellationToken);
        }

        /// <summary>
        /// Opens the database connection with retry logic for transient errors
        /// </summary>
        /// <param name="context">The DbContext instance</param>
        public static void OpenConnectionWithRetry(this DbContext context)
        {
            AzureSqlConnectionResilienceProvider.ExecuteWithRetry(
                () => context.Database.Connection.Open(), 
                "OpenConnection");
        }

        /// <summary>
        /// Ensures the database is created with retry logic for transient errors
        /// </summary>
        /// <param name="context">The DbContext instance</param>
        /// <returns>True if the database was created, false if it already existed</returns>
        public static bool CreateDatabaseWithRetry(this DbContext context)
        {
            return AzureSqlConnectionResilienceProvider.ExecuteWithRetry(
                () => context.Database.CreateIfNotExists(), 
                "CreateDatabase");
        }

        /// <summary>
        /// Migrates the database to the latest version with retry logic for transient errors
        /// </summary>
        /// <param name="context">The DbContext instance</param>
        public static void MigrateDatabaseWithRetry(this DbContext context)
        {
            AzureSqlConnectionResilienceProvider.ExecuteWithRetry(
                () => context.Database.Initialize(force: false), 
                "MigrateDatabase");
        }
    }
}