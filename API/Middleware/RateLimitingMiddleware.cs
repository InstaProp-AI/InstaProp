using System.Collections.Concurrent;
using System.Net;

namespace PropertyFlipperAPI.Middleware
{
    /// <summary>
    /// Rate limiting middleware to protect API from DDoS and abuse.
    /// Implements a sliding window algorithm with configurable limits per IP address.
    /// </summary>
    public class RateLimitingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<RateLimitingMiddleware> _logger;
        
        // Store request timestamps per IP address
        private static readonly ConcurrentDictionary<string, Queue<DateTime>> _requestHistory = new();
        
        // Configuration
        private readonly int _maxRequestsPerWindow;
        private readonly TimeSpan _timeWindow;
        
        public RateLimitingMiddleware(
            RequestDelegate next, 
            ILogger<RateLimitingMiddleware> logger,
            int maxRequestsPerWindow = 100,  // Default: 100 requests
            int timeWindowSeconds = 60)       // Default: per 60 seconds (1 minute)
        {
            _next = next;
            _logger = logger;
            _maxRequestsPerWindow = maxRequestsPerWindow;
            _timeWindow = TimeSpan.FromSeconds(timeWindowSeconds);
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Get client IP address
            var ipAddress = GetClientIpAddress(context);
            
            // Skip rate limiting for health check endpoints
            if (context.Request.Path.StartsWithSegments("/health") || 
                context.Request.Path.StartsWithSegments("/api/health"))
            {
                await _next(context);
                return;
            }

            // Get or create request history for this IP
            var requestTimestamps = _requestHistory.GetOrAdd(ipAddress, _ => new Queue<DateTime>());

            bool isRateLimited = false;
            double retryAfterSeconds = 0;
            int remainingRequests = 0;
            DateTime now = DateTime.UtcNow;

            lock (requestTimestamps)
            {
                // Remove old requests outside the time window
                while (requestTimestamps.Count > 0 && 
                       now - requestTimestamps.Peek() > _timeWindow)
                {
                    requestTimestamps.Dequeue();
                }

                // Check if rate limit exceeded
                if (requestTimestamps.Count >= _maxRequestsPerWindow)
                {
                    isRateLimited = true;
                    retryAfterSeconds = (_timeWindow - (now - requestTimestamps.Peek())).TotalSeconds;
                }
                else
                {
                    // Add current request timestamp
                    requestTimestamps.Enqueue(now);
                    remainingRequests = Math.Max(0, _maxRequestsPerWindow - requestTimestamps.Count);
                }
            }

            // Handle rate limit outside of lock (async operation)
            if (isRateLimited)
            {
                _logger.LogWarning($"🚫 Rate limit exceeded for IP: {ipAddress}. " +
                                 $"Requests: {_maxRequestsPerWindow}/{_maxRequestsPerWindow} " +
                                 $"in {_timeWindow.TotalSeconds}s window");

                context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
                context.Response.ContentType = "application/json";
                
                context.Response.Headers["Retry-After"] = ((int)Math.Ceiling(retryAfterSeconds)).ToString();
                context.Response.Headers["X-RateLimit-Limit"] = _maxRequestsPerWindow.ToString();
                context.Response.Headers["X-RateLimit-Remaining"] = "0";
                context.Response.Headers["X-RateLimit-Reset"] = ((DateTimeOffset)now.Add(_timeWindow)).ToUnixTimeSeconds().ToString();

                await context.Response.WriteAsJsonAsync(new
                {
                    error = "Rate limit exceeded",
                    message = $"Too many requests. Please try again in {Math.Ceiling(retryAfterSeconds)} seconds.",
                    retryAfter = Math.Ceiling(retryAfterSeconds)
                });
                return;
            }

            // Add rate limit headers to response
            context.Response.OnStarting(() =>
            {
                context.Response.Headers["X-RateLimit-Limit"] = _maxRequestsPerWindow.ToString();
                context.Response.Headers["X-RateLimit-Remaining"] = remainingRequests.ToString();
                context.Response.Headers["X-RateLimit-Reset"] = 
                    ((DateTimeOffset)now.Add(_timeWindow)).ToUnixTimeSeconds().ToString();
                return Task.CompletedTask;
            });

            // Cleanup old entries periodically (every 1000 requests)
            if (_requestHistory.Count > 1000)
            {
                CleanupOldEntries();
            }

            await _next(context);
        }

        private string GetClientIpAddress(HttpContext context)
        {
            // Try to get real IP from headers (for proxies/load balancers)
            var forwardedFor = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
            if (!string.IsNullOrEmpty(forwardedFor))
            {
                var ips = forwardedFor.Split(',', StringSplitOptions.RemoveEmptyEntries);
                if (ips.Length > 0)
                {
                    return ips[0].Trim();
                }
            }

            var realIp = context.Request.Headers["X-Real-IP"].FirstOrDefault();
            if (!string.IsNullOrEmpty(realIp))
            {
                return realIp;
            }

            return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        }

        private void CleanupOldEntries()
        {
            try
            {
                var now = DateTime.UtcNow;
                var keysToRemove = new List<string>();

                foreach (var kvp in _requestHistory)
                {
                    if (kvp.Value.Count == 0 || 
                        now - kvp.Value.Peek() > _timeWindow.Add(TimeSpan.FromMinutes(5)))
                    {
                        keysToRemove.Add(kvp.Key);
                    }
                }

                foreach (var key in keysToRemove)
                {
                    _requestHistory.TryRemove(key, out _);
                }

                if (keysToRemove.Count > 0)
                {
                    _logger.LogInformation($"🧹 Cleaned up {keysToRemove.Count} old IP entries from rate limiter");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during rate limiter cleanup");
            }
        }
    }

    public static class RateLimitingMiddlewareExtensions
    {
        public static IApplicationBuilder UseRateLimiting(
            this IApplicationBuilder builder,
            int maxRequestsPerWindow = 100,
            int timeWindowSeconds = 60)
        {
            return builder.UseMiddleware<RateLimitingMiddleware>(maxRequestsPerWindow, timeWindowSeconds);
        }
    }
}

