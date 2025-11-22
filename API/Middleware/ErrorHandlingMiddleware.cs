using System.Net;
using System.Text.Json;
using InstapropAPI.Services;

namespace InstapropAPI.Middleware
{
    /// <summary>
    /// Global error handling middleware that catches all unhandled exceptions
    /// and sends them to the error tracking service.
    /// </summary>
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context, ErrorTrackingService errorTracking)
        {
            // Skip error handling for Swagger endpoints to allow Swagger to show its own errors
            if (context.Request.Path.StartsWithSegments("/swagger"))
            {
                await _next(context);
                return;
            }
            
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"🔥 Unhandled exception: {ex.Message}");

                // Get user ID from claims if authenticated
                string? userId = null;
                if (context.User?.Identity?.IsAuthenticated == true)
                {
                    var uidClaim = context.User.FindFirst("uid");
                    userId = uidClaim?.Value;
                }

                // Capture exception with context
                var errorContext = new Dictionary<string, object>
                {
                    ["request_path"] = context.Request.Path.ToString(),
                    ["request_method"] = context.Request.Method,
                    ["query_string"] = context.Request.QueryString.ToString(),
                    ["user_agent"] = context.Request.Headers["User-Agent"].ToString(),
                    ["ip_address"] = context.Connection.RemoteIpAddress?.ToString() ?? "unknown"
                };

                await errorTracking.CaptureExceptionAsync(ex, userId, errorContext);

                // Return error response
                await HandleExceptionAsync(context, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            var code = HttpStatusCode.InternalServerError;
            
            // Get inner exception message for database errors
            var innerMessage = exception.InnerException?.Message ?? exception.Message;
            var isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";
            
            var result = JsonSerializer.Serialize(new
            {
                error = "An error occurred while processing your request",
                message = innerMessage, // Show inner exception message
                type = exception.GetType().Name,
                innerType = exception.InnerException?.GetType().Name,
                // Include inner exception details for database errors
                innerException = exception.InnerException != null ? new
                {
                    message = exception.InnerException.Message,
                    type = exception.InnerException.GetType().Name
                } : null,
                // Only include stack trace in development
                stackTrace = isDevelopment ? exception.StackTrace : null
            });

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)code;

            return context.Response.WriteAsync(result);
        }
    }

    public static class ErrorHandlingMiddlewareExtensions
    {
        public static IApplicationBuilder UseErrorHandling(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<ErrorHandlingMiddleware>();
        }
    }
}

