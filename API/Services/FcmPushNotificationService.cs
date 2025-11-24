using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Firebase Cloud Messaging (FCM) service for sending push notifications to mobile devices.
    /// This service handles sending notifications to both individual devices and topics.
    /// </summary>
    public class FcmPushNotificationService
    {
        private readonly ILogger<FcmPushNotificationService> _logger;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string? _fcmServerKey;
        private readonly string? _fcmSenderId;
        private readonly bool _isEnabled;

        public FcmPushNotificationService(
            ILogger<FcmPushNotificationService> logger,
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
            
            // Read FCM configuration
            _fcmServerKey = configuration["FCM:ServerKey"];
            _fcmSenderId = configuration["FCM:SenderId"];
            _isEnabled = !string.IsNullOrEmpty(_fcmServerKey);

            if (_isEnabled)
            {
                _logger.LogInformation("✅ FCM Push Notifications enabled");
            }
            else
            {
                _logger.LogWarning("⚠️ FCM Push Notifications disabled - No server key configured");
            }
        }

        /// <summary>
        /// Sends a push notification to a specific device token
        /// </summary>
        public async Task<bool> SendToDeviceAsync(
            string deviceToken,
            string title,
            string body,
            Dictionary<string, string>? data = null)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"📱 [FCM Disabled] Would send to device: {title}");
                return false;
            }

            try
            {
                var message = new
                {
                    to = deviceToken,
                    notification = new
                    {
                        title = title,
                        body = body,
                        sound = "default",
                        badge = "1",
                        priority = "high"
                    },
                    data = data ?? new Dictionary<string, string>(),
                    priority = "high"
                };

                return await SendFcmMessageAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send FCM notification to device: {deviceToken}");
                return false;
            }
        }

        /// <summary>
        /// Sends a push notification to multiple device tokens
        /// </summary>
        public async Task<bool> SendToMultipleDevicesAsync(
            List<string> deviceTokens,
            string title,
            string body,
            Dictionary<string, string>? data = null)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"📱 [FCM Disabled] Would send to {deviceTokens.Count} devices: {title}");
                return false;
            }

            if (deviceTokens.Count == 0)
            {
                _logger.LogWarning("No device tokens provided");
                return false;
            }

            try
            {
                // FCM supports up to 1000 registration IDs in a single request
                var batches = deviceTokens.Chunk(1000).ToList();
                var allSuccess = true;

                foreach (var batch in batches)
                {
                    var message = new
                    {
                        registration_ids = batch.ToArray(),
                        notification = new
                        {
                            title = title,
                            body = body,
                            sound = "default",
                            badge = "1",
                            priority = "high"
                        },
                        data = data ?? new Dictionary<string, string>(),
                        priority = "high"
                    };

                    var success = await SendFcmMessageAsync(message);
                    if (!success) allSuccess = false;
                }

                return allSuccess;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send FCM notification to multiple devices");
                return false;
            }
        }

        /// <summary>
        /// Sends a push notification to a topic (all users subscribed to that topic)
        /// </summary>
        public async Task<bool> SendToTopicAsync(
            string topic,
            string title,
            string body,
            Dictionary<string, string>? data = null)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"📱 [FCM Disabled] Would send to topic '{topic}': {title}");
                return false;
            }

            try
            {
                var message = new
                {
                    to = $"/topics/{topic}",
                    notification = new
                    {
                        title = title,
                        body = body,
                        sound = "default",
                        priority = "high"
                    },
                    data = data ?? new Dictionary<string, string>(),
                    priority = "high"
                };

                return await SendFcmMessageAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send FCM notification to topic: {topic}");
                return false;
            }
        }

        /// <summary>
        /// Sends notification for auction events (new auction, bid placed, auction ended, etc.)
        /// </summary>
        public async Task SendAuctionNotificationAsync(
            List<string> deviceTokens,
            NotificationType notificationType,
            long auctionId,
            string propertyName,
            decimal? amount = null)
        {
            if (deviceTokens.Count == 0) return;

            string title = "";
            string body = "";
            var data = new Dictionary<string, string>
            {
                ["type"] = "auction",
                ["auctionId"] = auctionId.ToString(),
                ["notificationType"] = notificationType.ToString()
            };

            switch (notificationType)
            {
                case NotificationType.AuctionStarted:
                    title = "New Auction Available!";
                    body = $"A new auction for '{propertyName}' has started. Check it out!";
                    break;

                case NotificationType.BidPlaced:
                    title = "New Bid Placed";
                    body = $"Someone bid ${amount:N2} on your auction for '{propertyName}'.";
                    break;

                case NotificationType.Outbid:
                    title = "You've Been Outbid!";
                    body = $"Someone placed a higher bid on '{propertyName}'. Bid again to stay in the race!";
                    break;

                case NotificationType.AuctionWon:
                    title = "🎉 Congratulations!";
                    body = $"You won the auction for '{propertyName}'! We'll contact you soon.";
                    break;

                case NotificationType.AuctionLost:
                    title = "Auction Ended";
                    body = $"The auction for '{propertyName}' has ended. Better luck next time!";
                    break;

                case NotificationType.AuctionEnded:
                    title = "Auction Ended";
                    body = $"Your auction for '{propertyName}' has ended with a winning bid of ${amount:N2}.";
                    break;

                case NotificationType.AuctionApproved:
                    title = "Auction Approved!";
                    body = $"Your auction request for '{propertyName}' has been approved and is now active.";
                    break;

                case NotificationType.AuctionRejected:
                    title = "Auction Rejected";
                    body = $"Your auction request for '{propertyName}' was rejected. Contact support for details.";
                    break;

                default:
                    title = "Instaprop Notification";
                    body = $"Update regarding '{propertyName}'";
                    break;
            }

            await SendToMultipleDevicesAsync(deviceTokens, title, body, data);
        }

        /// <summary>
        /// Sends notification for new chat messages
        /// </summary>
        public async Task SendChatNotificationAsync(
            Guid recipientId,
            string title,
            string message)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"📱 [FCM Disabled] Would send chat notification to user {recipientId}: {title}");
                return;
            }

            try
            {
                var data = new Dictionary<string, string>
                {
                    ["type"] = "chat",
                    ["recipientId"] = recipientId.ToString()
                };

                // TODO: Get device tokens for recipient from database
                // For now, send to topic based on user ID
                await SendToTopicAsync($"user_{recipientId}", title, message, data);
                
                _logger.LogInformation($"✅ Chat notification sent to user {recipientId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send chat notification to user {recipientId}");
            }
        }

        private async Task<bool> SendFcmMessageAsync(object message)
        {
            try
            {
                var httpClient = _httpClientFactory.CreateClient();
                httpClient.DefaultRequestHeaders.Authorization = 
                    new AuthenticationHeaderValue("key", $"={_fcmServerKey}");
                httpClient.DefaultRequestHeaders.TryAddWithoutValidation("Content-Type", "application/json");

                var json = JsonSerializer.Serialize(message);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await httpClient.PostAsync(
                    "https://fcm.googleapis.com/fcm/send",
                    content
                );

                var responseBody = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation($"✅ FCM notification sent successfully");
                    return true;
                }
                else
                {
                    _logger.LogError($"❌ FCM notification failed: {response.StatusCode} - {responseBody}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception while sending FCM message");
                return false;
            }
        }
    }

    /// <summary>
    /// Model to store user device tokens for push notifications
    /// </summary>
    public class DeviceToken
    {
        public long DeviceTokenId { get; set; }
        public long UserId { get; set; }
        public string Token { get; set; } = string.Empty;
        public string Platform { get; set; } = "Unknown"; // iOS, Android, Web
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastUsedAt { get; set; }
    }
}

