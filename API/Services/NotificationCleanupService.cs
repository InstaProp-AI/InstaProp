using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;

namespace PropertyFlipperAPI.Services
{
    public class NotificationCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationCleanupService> _logger;

        public NotificationCleanupService(
            IServiceProvider serviceProvider,
            ILogger<NotificationCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🧹 Notification Cleanup Service started");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CleanupOldNotifications(stoppingToken);

                    // Run cleanup once per day (every 24 hours)
                    await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    // Service is stopping
                    _logger.LogInformation("🧹 Notification Cleanup Service stopping");
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error in notification cleanup service");
                    // Wait 1 hour before retrying on error
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
            }
        }

        private async Task CleanupOldNotifications(CancellationToken stoppingToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Delete notifications older than 14 days
            var cutoffDate = DateTime.UtcNow.AddDays(-14);

            var oldNotifications = await context.Notifications
                .Where(n => n.CreatedAt < cutoffDate)
                .ToListAsync(stoppingToken);

            if (oldNotifications.Any())
            {
                context.Notifications.RemoveRange(oldNotifications);
                await context.SaveChangesAsync(stoppingToken);

                _logger.LogInformation(
                    $"🧹 Cleaned up {oldNotifications.Count} notifications older than 14 days"
                );
            }
            else
            {
                _logger.LogInformation("✅ No old notifications to clean up");
            }
        }
    }
}

