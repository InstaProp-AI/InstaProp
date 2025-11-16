using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Error tracking service that integrates with Sentry or Application Insights.
    /// Captures and logs exceptions with context for better debugging.
    /// </summary>
    public class ErrorTrackingService
    {
        private readonly ILogger<ErrorTrackingService> _logger;
        private readonly IConfiguration _configuration;
        private readonly bool _isEnabled;
        private readonly string? _sentryDsn;
        private readonly string? _environment;

        public ErrorTrackingService(
            ILogger<ErrorTrackingService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            // Read configuration
            _sentryDsn = configuration["Sentry:Dsn"];
            _environment = configuration["Sentry:Environment"] ?? "Production";
            _isEnabled = !string.IsNullOrEmpty(_sentryDsn);

            if (_isEnabled)
            {
                _logger.LogInformation($"✅ Error tracking enabled (Environment: {_environment})");
            }
            else
            {
                _logger.LogWarning("⚠️ Error tracking disabled - No Sentry DSN configured");
            }
        }

        /// <summary>
        /// Captures an exception and sends it to the error tracking service
        /// </summary>
        public async Task CaptureExceptionAsync(
            Exception exception, 
            string? userId = null,
            Dictionary<string, object>? context = null)
        {
            if (!_isEnabled)
            {
                _logger.LogError(exception, "Exception occurred (Error tracking disabled)");
                return;
            }

            try
            {
                // Log locally first
                _logger.LogError(exception, $"Exception captured for tracking: {exception.Message}");

                // Build error payload
                var errorEvent = new
                {
                    timestamp = DateTime.UtcNow,
                    level = "error",
                    platform = "csharp",
                    environment = _environment,
                    exception = new
                    {
                        type = exception.GetType().Name,
                        value = exception.Message,
                        stacktrace = exception.StackTrace,
                        innerException = exception.InnerException != null ? new
                        {
                            type = exception.InnerException.GetType().Name,
                            value = exception.InnerException.Message,
                            stacktrace = exception.InnerException.StackTrace
                        } : null
                    },
                    user = userId != null ? new { id = userId } : null,
                    tags = new
                    {
                        server_name = Environment.MachineName,
                        runtime = Environment.Version.ToString()
                    },
                    extra = context
                };

                // In production, this would send to Sentry
                // For now, we'll log the structured error
                _logger.LogInformation($"📊 Error tracked: {JsonSerializer.Serialize(errorEvent)}");

                // TODO: Uncomment when Sentry package is installed
                // SentrySdk.CaptureException(exception, scope =>
                // {
                //     if (userId != null)
                //         scope.User = new User { Id = userId };
                //     
                //     if (context != null)
                //     {
                //         foreach (var kvp in context)
                //             scope.SetExtra(kvp.Key, kvp.Value);
                //     }
                // });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to capture exception in error tracking service");
            }
        }

        /// <summary>
        /// Captures a custom message/event
        /// </summary>
        public async Task CaptureMessageAsync(
            string message, 
            ErrorLevel level = ErrorLevel.Info,
            string? userId = null,
            Dictionary<string, object>? context = null)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"Message: {message} (Level: {level})");
                return;
            }

            try
            {
                var messageEvent = new
                {
                    timestamp = DateTime.UtcNow,
                    level = level.ToString().ToLower(),
                    message = message,
                    platform = "csharp",
                    environment = _environment,
                    user = userId != null ? new { id = userId } : null,
                    extra = context
                };

                _logger.LogInformation($"📊 Message tracked: {JsonSerializer.Serialize(messageEvent)}");

                // TODO: Uncomment when Sentry package is installed
                // SentrySdk.CaptureMessage(message, (SentryLevel)level);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to capture message in error tracking service");
            }
        }

        /// <summary>
        /// Sets the user context for subsequent error tracking
        /// </summary>
        public void SetUser(string userId, string? email = null, string? username = null)
        {
            if (!_isEnabled) return;

            try
            {
                // TODO: Uncomment when Sentry package is installed
                // SentrySdk.ConfigureScope(scope =>
                // {
                //     scope.User = new User
                //     {
                //         Id = userId,
                //         Email = email,
                //         Username = username
                //     };
                // });
                
                _logger.LogDebug($"User context set: {userId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to set user context");
            }
        }

        /// <summary>
        /// Adds a breadcrumb for tracking user actions leading to an error
        /// </summary>
        public void AddBreadcrumb(string message, string category = "default", ErrorLevel level = ErrorLevel.Info)
        {
            if (!_isEnabled) return;

            try
            {
                // TODO: Uncomment when Sentry package is installed
                // SentrySdk.AddBreadcrumb(message, category, level: (BreadcrumbLevel)level);
                
                _logger.LogDebug($"Breadcrumb: [{category}] {message}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to add breadcrumb");
            }
        }
    }

    public enum ErrorLevel
    {
        Debug = 0,
        Info = 1,
        Warning = 2,
        Error = 3,
        Fatal = 4
    }
}

