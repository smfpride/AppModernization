using System;
using System.Data.SqlClient;
using System.Threading.Tasks;
using eShopLegacyMVC.Models.Infrastructure;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace eShopLegacyMVC.Tests.Infrastructure
{
    [TestClass]
    public class AzureSqlConnectionResilienceProviderTests
    {
        [TestMethod]
        public void ExecuteWithRetry_ShouldReturnResult_WhenOperationSucceeds()
        {
            // Arrange
            var expectedResult = 42;
            Func<int> operation = () => expectedResult;

            // Act
            var result = AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TestOperation");

            // Assert
            Assert.AreEqual(expectedResult, result, "Should return the result of the successful operation");
        }

        [TestMethod]
        public void ExecuteWithRetry_ShouldExecuteVoidOperation_WhenOperationSucceeds()
        {
            // Arrange
            var executed = false;
            Action operation = () => executed = true;

            // Act
            AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TestVoidOperation");

            // Assert
            Assert.IsTrue(executed, "Should execute the void operation successfully");
        }

        [TestMethod]
        public void ExecuteWithRetry_ShouldThrowNonTransientException_Immediately()
        {
            // Arrange
            var nonTransientException = new ArgumentException("This is a non-transient error");
            Func<int> operation = () => throw nonTransientException;

            // Act & Assert
            var exception = Assert.ThrowsException<ArgumentException>(() =>
                AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TestOperation"));

            Assert.AreEqual("This is a non-transient error", exception.Message,
                "Should throw the non-transient exception immediately without retries");
        }

        [TestMethod]
        public void ExecuteWithRetry_ShouldRetryTransientErrors_AndEventuallyFail()
        {
            // Arrange
            var attemptCount = 0;
            var transientException = new SqlException(); // This will be detected as transient
            Func<int> operation = () =>
            {
                attemptCount++;
                throw transientException;
            };

            // Act & Assert
            var exception = Assert.ThrowsException<InvalidOperationException>(() =>
                AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TestOperation"));

            Assert.IsTrue(exception.Message.Contains("failed after 3 attempts"),
                "Should indicate that operation failed after max retry attempts");
            Assert.AreEqual(3, attemptCount, "Should attempt the operation 3 times before giving up");
        }

        [TestMethod]
        public void ExecuteWithRetry_ShouldSucceedAfterTransientFailures()
        {
            // Arrange
            var attemptCount = 0;
            var expectedResult = 100;
            var transientException = new TimeoutException("Connection timeout"); // Transient error
            
            Func<int> operation = () =>
            {
                attemptCount++;
                if (attemptCount < 3) // Fail first 2 attempts
                {
                    throw transientException;
                }
                return expectedResult; // Succeed on 3rd attempt
            };

            // Act
            var result = AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TestOperation");

            // Assert
            Assert.AreEqual(expectedResult, result, "Should return result after successful retry");
            Assert.AreEqual(3, attemptCount, "Should attempt operation 3 times before succeeding");
        }

        [TestMethod]
        public async Task ExecuteWithRetryAsync_ShouldReturnResult_WhenOperationSucceeds()
        {
            // Arrange
            var expectedResult = 42;
            Func<Task<int>> operation = () => Task.FromResult(expectedResult);

            // Act
            var result = await AzureSqlConnectionResilienceProvider.ExecuteWithRetryAsync(operation, "TestAsyncOperation");

            // Assert
            Assert.AreEqual(expectedResult, result, "Should return the result of the successful async operation");
        }

        [TestMethod]
        public async Task ExecuteWithRetryAsync_ShouldSucceedAfterTransientFailures()
        {
            // Arrange
            var attemptCount = 0;
            var expectedResult = 200;
            var transientException = new TimeoutException("Async connection timeout");
            
            Func<Task<int>> operation = () =>
            {
                attemptCount++;
                if (attemptCount < 2) // Fail first attempt
                {
                    throw transientException;
                }
                return Task.FromResult(expectedResult); // Succeed on 2nd attempt
            };

            // Act
            var result = await AzureSqlConnectionResilienceProvider.ExecuteWithRetryAsync(operation, "TestAsyncOperation");

            // Assert
            Assert.AreEqual(expectedResult, result, "Should return result after successful async retry");
            Assert.AreEqual(2, attemptCount, "Should attempt async operation 2 times before succeeding");
        }

        [TestMethod]
        [ExpectedException(typeof(ArgumentException))]
        public async Task ExecuteWithRetryAsync_ShouldThrowNonTransientException_Immediately()
        {
            // Arrange
            var nonTransientException = new ArgumentException("This is a non-transient async error");
            Func<Task<int>> operation = () => throw nonTransientException;

            // Act
            await AzureSqlConnectionResilienceProvider.ExecuteWithRetryAsync(operation, "TestAsyncOperation");

            // Assert is handled by ExpectedException
        }

        [TestMethod]
        public void IsTransientError_ShouldReturnTrue_ForKnownTransientSqlErrors()
        {
            // This test uses reflection to access the private IsTransientError method
            // In a real scenario, you might want to make this method internal and use InternalsVisibleTo
            
            // We can test indirectly by using operations that throw known transient errors
            var timeoutException = new TimeoutException("Database timeout");
            var attemptCount = 0;
            
            Func<int> operation = () =>
            {
                attemptCount++;
                if (attemptCount < 2)
                {
                    throw timeoutException;
                }
                return 1;
            };

            // Act
            var result = AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "TransientErrorTest");

            // Assert
            Assert.AreEqual(1, result, "Should succeed after timeout error retry");
            Assert.AreEqual(2, attemptCount, "Should retry timeout exceptions");
        }

        [TestMethod]
        public void IsTransientError_ShouldReturnTrue_ForConnectionRelatedErrors()
        {
            // Test connection-related error detection
            var connectionException = new Exception("A network-related or instance-specific error occurred");
            var attemptCount = 0;
            
            Func<int> operation = () =>
            {
                attemptCount++;
                if (attemptCount < 2)
                {
                    throw connectionException;
                }
                return 1;
            };

            // Act
            var result = AzureSqlConnectionResilienceProvider.ExecuteWithRetry(operation, "ConnectionErrorTest");

            // Assert
            Assert.AreEqual(1, result, "Should succeed after connection error retry");
            Assert.AreEqual(2, attemptCount, "Should retry connection exceptions");
        }
    }
}