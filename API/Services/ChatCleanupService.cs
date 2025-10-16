using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;

namespace PropertyFlipperAPI.Services
{
    /// <summary>
    /// Background service that runs daily to delete chat messages older than 30 days
    /// </summary>
    public class ChatCleanupService : BackgroundService
    {
        private readonly ILogger<ChatCleanupService> _logger;
        private readonly IServiceProvider _serviceProvider;
        private readonly TimeSpan _cleanupInterval = TimeSpan.FromHours(24); // Run daily

        public ChatCleanupService(
            ILogger<ChatCleanupService> logger,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🧹 Chat Cleanup Service started");

            // Wait for initial delay (run at midnight)
            var now = DateTime.UtcNow;
            var midnight = now.Date.AddDays(1); // Next midnight
            var initialDelay = midnight - now;

            try
            {
                await Task.Delay(initialDelay, stoppingToken);
            }
            catch (TaskCanceledException)
            {
                return;
            }

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CleanupExpiredMessagesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error during chat cleanup");
                }

                try
                {
                    await Task.Delay(_cleanupInterval, stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("🧹 Chat Cleanup Service stopped");
        }

        private async Task CleanupExpiredMessagesAsync()
        {
            _logger.LogInformation("🧹 Starting chat message cleanup...");

            using (var scope = _serviceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var firestoreService = scope.ServiceProvider.GetRequiredService<FirestoreService>();

                var now = DateTime.UtcNow;
                var expiredMessages = await dbContext.ChatMessages
                    .Where(m => m.ExpiresAt <= now)
                    .ToListAsync();

                if (expiredMessages.Count > 0)
                {
                    dbContext.ChatMessages.RemoveRange(expiredMessages);
                    await dbContext.SaveChangesAsync();

                    // Also delete from Firestore
                    await firestoreService.DeleteExpiredChatMessagesAsync();

                    _logger.LogInformation($"🧹 Deleted {expiredMessages.Count} expired chat messages");
                }
                else
                {
                    _logger.LogInformation("🧹 No expired chat messages to delete");
                }
            }
        }
    }
}

