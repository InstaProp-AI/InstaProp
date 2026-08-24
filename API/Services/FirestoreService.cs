using Google.Cloud.Firestore;
using InstapropAPI.Models;
using System.Text.Json;
using System.Linq;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Firestore service for real-time data synchronization.
    /// </summary>
    public class FirestoreService
    {
        private readonly ILogger<FirestoreService> _logger;
        private readonly IConfiguration _configuration;
        private FirestoreDb? _db;
        private readonly bool _isEnabled;

        public FirestoreService(
            ILogger<FirestoreService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;

            var projectId = configuration["Firebase:ProjectId"];
            _isEnabled = !string.IsNullOrEmpty(projectId);

            if (_isEnabled)
            {
                try
                {
                    var credentialsPath = configuration["Firebase:CredentialsPath"];
                    if (!string.IsNullOrEmpty(credentialsPath) && File.Exists(credentialsPath))
                    {
                        Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", credentialsPath);
                    }

                    _db = FirestoreDb.Create(projectId);
                    _logger.LogInformation($"✅ Firestore initialized for project: {projectId}");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Failed to initialize Firestore");
                    _isEnabled = false;
                }
            }
            else
            {
                _logger.LogWarning("⚠️ Firestore disabled - No project ID configured");
            }
        }

        #region Auction Updates

        /// <summary>
        /// Updates auction in Firestore
        /// </summary>
        public async Task UpdateAuctionAsync(Guid auctionId, Auction auction)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would update auction {auctionId}");
                return;
            }

            try
            {
                var docRef = _db.Collection("auctions").Document(auctionId.ToString());
                
                var auctionData = new Dictionary<string, object>
                {
                    ["auctionId"] = auction.AuctionId,
                    ["propertyId"] = auction.PropertyId,
                    ["startPrice"] = (double)auction.StartPrice,
                    ["currentPrice"] = (double)auction.CurrentPrice,
                    ["startAt"] = auction.StartAt.ToString("o"), // ISO 8601 format
                    ["duration"] = auction.Duration,
                    ["bidCount"] = auction.BidCount,
                    ["status"] = auction.Status,
                    ["createdAt"] = auction.CreatedAt.ToString("o"), // ISO 8601 format
                    ["updatedAt"] = DateTime.UtcNow.ToString("o"), // ISO 8601 format
                    ["property"] = auction.Property != null ? new Dictionary<string, object>
                    {
                        ["propertyId"] = auction.Property.PropertyId,
                        ["name"] = auction.Property.Name ?? "",
                        ["description"] = auction.Property.Description ?? "",
                        ["location"] = auction.Property.Location ?? "",
                        ["imageUrl"] = auction.Property.ImageUrl ?? "",
                        ["type"] = auction.Property.Type.ToDisplayName(),
                        ["status"] = auction.Property.Status.ToString(),
                        ["bedrooms"] = auction.Property.Bedrooms,
                        ["bathrooms"] = auction.Property.Bathrooms,
                        ["squareFeet"] = auction.Property.SquareFeet,
                        ["yearBuilt"] = auction.Property.YearBuilt,
                        ["type"] = PropertyTypeHelper.ToDisplayName(auction.Property.Type),
                        ["project"] = auction.Property.Project?.Name ?? "",
                        ["propertyImages"] = auction.Property.PropertyImages?.Select(img => new Dictionary<string, object>
                        {
                            ["propertyImageId"] = img.PropertyImageId,
                            ["propertyId"] = img.PropertyId,
                            ["imageUrl"] = img.ImageUrl ?? "",
                            ["imageType"] = img.ImageType ?? "",
                            ["isMainImage"] = img.IsMainImage,
                            ["displayOrder"] = img.DisplayOrder
                        }).ToList() ?? new List<Dictionary<string, object>>()
                    } : null
                };

                await docRef.SetAsync(auctionData, SetOptions.MergeAll);
                _logger.LogInformation($"✅ Updated auction {auctionId} in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to update auction {auctionId} in Firestore");
            }
        }

        /// <summary>
        /// Deletes auction from Firestore
        /// </summary>
        public async Task DeleteAuctionAsync(long auctionId)
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var docRef = _db.Collection("auctions").Document(auctionId.ToString());
                await docRef.DeleteAsync();
                _logger.LogInformation($"✅ Deleted auction {auctionId} from Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to delete auction {auctionId} from Firestore");
            }
        }

        #endregion

        #region Bid Updates

        /// <summary>
        /// Adds a new bid to Firestore
        /// </summary>
        public async Task AddBidAsync(Guid auctionId, Bid bid)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would add bid {bid.BidId} to auction {auctionId}");
                return;
            }

            try
            {
                var bidRef = _db.Collection("auctions")
                    .Document(auctionId.ToString())
                    .Collection("bids")
                    .Document(bid.BidId.ToString());

                var bidData = new Dictionary<string, object>
                {
                    ["bidId"] = bid.BidId,
                    ["auctionId"] = bid.AuctionId,
                    ["bidderId"] = bid.BidderId,
                    ["bidAmount"] = (double)bid.BidAmount,
                    ["createdAt"] = bid.CreatedAt.ToString("o"), // ISO 8601 format
                    ["bidder"] = bid.Bidder != null ? new Dictionary<string, object>
                    {
                        ["accountId"] = bid.Bidder.AccountId,
                        ["firstName"] = bid.Bidder.FirstName ?? "",
                        ["lastName"] = bid.Bidder.LastName ?? "",
                        ["email"] = bid.Bidder.Email ?? ""
                    } : null
                };

                await bidRef.SetAsync(bidData);
                _logger.LogInformation($"✅ Added bid {bid.BidId} to auction {auctionId} in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to add bid {bid.BidId} to Firestore");
            }
        }

        #endregion

        #region Notification Updates

        /// <summary>
        /// Updates user notifications in Firestore
        /// </summary>
        public async Task UpdateUserNotificationAsync(Guid userId, Notification notification)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would update notification for user {userId}");
                return;
            }

            try
            {
                var notifRef = _db.Collection("users")
                    .Document(userId.ToString())
                    .Collection("notifications")
                    .Document(notification.NotificationId.ToString());

                var notifData = new Dictionary<string, object>
                {
                    ["notificationId"] = notification.NotificationId,
                    ["userId"] = userId,
                    ["title"] = notification.Title,
                    ["message"] = notification.Message,
                    ["type"] = notification.Type.ToString(),
                    ["isRead"] = notification.IsRead,
                    ["auctionId"] = notification.AuctionId?.ToString() ?? "",
                    ["propertyId"] = notification.PropertyId?.ToString() ?? "",
                    ["eventId"] = notification.EventId?.ToString() ?? "",
                    ["bidId"] = notification.BidId?.ToString() ?? "",
                    ["createdAt"] = notification.CreatedAt.ToString("o"), // ISO 8601 format
                    ["readAt"] = notification.ReadAt?.ToString("o") // ISO 8601 format, nullable
                };

                await notifRef.SetAsync(notifData);
                _logger.LogInformation($"✅ Updated notification for user {userId} in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to update notification for user {userId}");
            }
        }

        /// <summary>
        /// Marks notification as read in Firestore
        /// </summary>
        public async Task MarkNotificationAsReadAsync(Guid userId, Guid notificationId)
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var notifRef = _db.Collection("users")
                    .Document(userId.ToString())
                    .Collection("notifications")
                    .Document(notificationId.ToString());

                await notifRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["isRead"] = true,
                    ["readAt"] = DateTime.UtcNow.ToString("o") // ISO 8601 format
                });

                _logger.LogInformation($"✅ Marked notification {notificationId} as read in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to mark notification as read");
            }
        }

        #endregion

        #region General Updates

        /// <summary>
        /// Broadcasts general update to all users
        /// </summary>
        public async Task BroadcastGeneralUpdateAsync(string type, object data)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would broadcast {type}");
                return;
            }

            try
            {
                var updateRef = _db.Collection("broadcasts").Document();
                
                var updateData = new Dictionary<string, object>
                {
                    ["type"] = type,
                    ["data"] = JsonSerializer.Serialize(data),
                    ["timestamp"] = DateTime.UtcNow.ToString("o") // ISO 8601 format
                };

                await updateRef.SetAsync(updateData);
                _logger.LogInformation($"✅ Broadcast {type} to Firestore");

                // Auto-cleanup old broadcasts (keep last 100)
                _ = Task.Run(async () => await CleanupOldBroadcasts());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to broadcast {type}");
            }
        }

        #endregion

        #region User/Account Updates

        /// <summary>
        /// Syncs user account to Firestore (for dashboard real-time user list)
        /// </summary>
        public async Task SyncUserAsync(Guid userId, AccountBase account)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would sync user {userId}");
                return;
            }

            try
            {
                var userRef = _db.Collection("users").Document(userId.ToString());
                
                var userData = new Dictionary<string, object>
                {
                    ["accountId"] = account.AccountId,
                    ["firstName"] = account.FirstName ?? "",
                    ["lastName"] = account.LastName ?? "",
                    ["email"] = account.Email ?? "",
                    ["phoneNumber"] = account.PhoneNumber ?? "",
                    ["roleId"] = account.RoleId.ToString(), // SECURITY: Non-guessable RoleId
                    ["role"] = account.Role != null ? account.Role.RoleName : "Unknown",
                    ["status"] = account.Status.ToString(),
                    ["emailVerified"] = account.EmailVerified,
                    ["phoneVerified"] = account.PhoneVerified,
                    ["isSuspended"] = account.IsSuspended,
                    ["createdAt"] = account.CreatedAt.ToString("o"), // ISO 8601 format
                    ["updatedAt"] = DateTime.UtcNow.ToString("o") // ISO 8601 format
                };

                await userRef.SetAsync(userData, SetOptions.MergeAll);
                _logger.LogInformation($"✅ Synced user {userId} to Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to sync user {userId} to Firestore");
            }
        }

        /// <summary>
        /// Deletes user from Firestore
        /// </summary>
        public async Task DeleteUserAsync(Guid userId)
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var userRef = _db.Collection("users").Document(userId.ToString());
                await userRef.DeleteAsync();
                _logger.LogInformation($"✅ Deleted user {userId} from Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to delete user {userId} from Firestore");
            }
        }

        #endregion

        #region Property Updates

        /// <summary>
        /// Syncs property to Firestore
        /// </summary>
        public async Task SyncPropertyAsync(long propertyId, Property property)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would sync property {propertyId}");
                return;
            }

            try
            {
                var propertyRef = _db.Collection("properties").Document(propertyId.ToString());
                
                var propertyData = new Dictionary<string, object>
                {
                    ["propertyId"] = property.PropertyId,
                    ["ownerId"] = property.OwnerId,
                    ["name"] = property.Name ?? "",
                    ["description"] = property.Description ?? "",
                    ["location"] = property.Location ?? "",
                    ["type"] = property.Type.ToString(),
                    ["status"] = property.Status.ToString(),
                    ["bedrooms"] = property.Bedrooms,
                    ["bathrooms"] = property.Bathrooms,
                    ["squareFeet"] = property.SquareFeet,
                    ["yearBuilt"] = property.YearBuilt,
                    ["type"] = PropertyTypeHelper.ToDisplayName(property.Type),
                    ["project"] = property.Project?.Name ?? "",
                    ["imageUrl"] = property.ImageUrl ?? "",
                    ["createdAt"] = property.CreatedAt.ToString("o"), // ISO 8601 format
                    ["updatedAt"] = DateTime.UtcNow.ToString("o") // ISO 8601 format
                };

                await propertyRef.SetAsync(propertyData, SetOptions.MergeAll);
                _logger.LogInformation($"✅ Synced property {propertyId} to Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to sync property {propertyId} to Firestore");
            }
        }

        #endregion

        #region Chat Updates

        /// <summary>
        /// Creates a chat room in Firestore
        /// </summary>
        public async Task CreateChatAsync(Guid chatId, Guid userId, Guid developerId, Guid? projectId)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would create chat {chatId}");
                return;
            }

            try
            {
                var chatRef = _db.Collection("chats").Document(chatId.ToString());
                
                var chatData = new Dictionary<string, object>
                {
                    ["chatId"] = chatId,
                    ["userId"] = userId,
                    ["developerId"] = developerId,
                    ["projectId"] = projectId?.ToString() ?? "",
                    ["createdAt"] = DateTime.UtcNow,
                    ["lastMessageAt"] = DateTime.UtcNow,
                    ["isActive"] = true
                };

                await chatRef.SetAsync(chatData);
                _logger.LogInformation($"✅ Created chat {chatId} in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to create chat {chatId} in Firestore");
            }
        }

        /// <summary>
        /// Sends a chat message to Firestore for real-time delivery
        /// </summary>
        public async Task SendChatMessageAsync(Guid chatId, Guid messageId, Guid senderId, string content, Guid? propertyId, DateTime createdAt, DateTime expiresAt)
        {
            if (!_isEnabled || _db == null)
            {
                _logger.LogInformation($"[Firestore Disabled] Would send message {messageId} to chat {chatId}");
                return;
            }

            try
            {
                var messageRef = _db.Collection("chats")
                    .Document(chatId.ToString())
                    .Collection("messages")
                    .Document(messageId.ToString());

                var messageData = new Dictionary<string, object>
                {
                    ["messageId"] = messageId.ToString(),
                    ["chatId"] = chatId.ToString(),
                    ["senderId"] = senderId.ToString(),
                    ["content"] = content,
                    ["propertyId"] = propertyId?.ToString() ?? "",
                    ["createdAt"] = createdAt,
                    ["isRead"] = false,
                    ["expiresAt"] = expiresAt
                };

                await messageRef.SetAsync(messageData);

                // Update chat's lastMessageAt
                var chatRef = _db.Collection("chats").Document(chatId.ToString());
                await chatRef.UpdateAsync(new Dictionary<string, object>
                {
                    ["lastMessageAt"] = DateTime.UtcNow
                });

                _logger.LogInformation($"✅ Sent message {messageId} to chat {chatId} in Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send message {messageId} to Firestore");
            }
        }

        /// <summary>
        /// Marks chat messages as read in Firestore
        /// </summary>
        public async Task MarkChatMessagesAsReadAsync(Guid chatId, Guid userId)
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var messagesRef = _db.Collection("chats")
                    .Document(chatId.ToString())
                    .Collection("messages");

                var unreadMessages = await messagesRef
                    .WhereNotEqualTo("senderId", userId)
                    .WhereEqualTo("isRead", false)
                    .GetSnapshotAsync();

                var batch = _db.StartBatch();
                foreach (var doc in unreadMessages.Documents)
                {
                    batch.Update(doc.Reference, new Dictionary<string, object>
                    {
                        ["isRead"] = true
                    });
                }
                await batch.CommitAsync();

                _logger.LogInformation($"✅ Marked {unreadMessages.Count} messages as read in chat {chatId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to mark messages as read in chat {chatId}");
            }
        }

        /// <summary>
        /// Deletes expired chat messages from Firestore
        /// </summary>
        public async Task DeleteExpiredChatMessagesAsync()
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var now = DateTime.UtcNow;
                var chatsRef = _db.Collection("chats");
                var chats = await chatsRef.GetSnapshotAsync();

                int totalDeleted = 0;

                foreach (var chatDoc in chats.Documents)
                {
                    var messagesRef = chatDoc.Reference.Collection("messages");
                    var expiredMessages = await messagesRef
                        .WhereLessThan("expiresAt", now.ToString("o"))
                        .GetSnapshotAsync();

                    if (expiredMessages.Count > 0)
                    {
                        var batch = _db.StartBatch();
                        foreach (var messageDoc in expiredMessages.Documents)
                        {
                            batch.Delete(messageDoc.Reference);
                        }
                        await batch.CommitAsync();
                        totalDeleted += expiredMessages.Count;
                    }
                }

                _logger.LogInformation($"🧹 Deleted {totalDeleted} expired chat messages from Firestore");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to delete expired chat messages");
            }
        }

        #endregion

        #region Utility Methods

        /// <summary>
        /// Cleans up old broadcast messages
        /// </summary>
        private async Task CleanupOldBroadcasts()
        {
            if (!_isEnabled || _db == null) return;

            try
            {
                var oldBroadcasts = await _db.Collection("broadcasts")
                    .OrderByDescending("timestamp")
                    .Offset(100)
                    .GetSnapshotAsync();

                var batch = _db.StartBatch();
                foreach (var doc in oldBroadcasts.Documents)
                {
                    batch.Delete(doc.Reference);
                }
                await batch.CommitAsync();

                _logger.LogInformation($"🧹 Cleaned up {oldBroadcasts.Count} old broadcasts");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to cleanup old broadcasts");
            }
        }

        /// <summary>
        /// Checks if Firestore is enabled and connected
        /// </summary>
        public bool IsEnabled() => _isEnabled && _db != null;

        #endregion
    }
}

