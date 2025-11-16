using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstapropAPI.Services;
using InstapropAPI.Attributes;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly NotificationService _notificationService;
        private readonly AppDbContext _context;
        private readonly FirestoreService _firestoreService;
        private readonly NotificationHelperService _helperService;

        public NotificationController(NotificationService notificationService, AppDbContext context, FirestoreService firestoreService, NotificationHelperService helperService)
        {
            _notificationService = notificationService;
            _context = context;
            _firestoreService = firestoreService;
            _helperService = helperService;
        }

        // GET: api/notification
        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] bool unreadOnly = false)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(new { message = "User not authenticated" });

            var notifications = await GetUserNotificationsWithBulk(userId.Value, unreadOnly);
            return Ok(notifications);
        }

        // GET: api/notification/public (no auth required)
        [HttpGet("public")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPublicNotifications()
        {
            var notifications = await GetUserNotificationsWithBulk(null, false);
            return Ok(notifications);
        }

        private async Task<List<NotificationDto>> GetUserNotificationsWithBulk(long? userId, bool unreadOnly)
        {
            // Get all notifications (both individual and bulk)
            var allNotifications = await _context.Notifications
                .Where(n => n.UserId == userId || n.UserId == null) // Individual OR bulk
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            var result = new List<NotificationDto>();

            foreach (var notification in allNotifications)
            {
                // Check if user should see this notification
                bool shouldShow = false;

                if (notification.UserId.HasValue && notification.UserId.Value == (userId ?? 0))
                {
                    // Individual notification for this user
                    shouldShow = true;
                }
                else if (!string.IsNullOrEmpty(notification.Recipients))
                {
                    // Bulk notification - check if user matches criteria
                    shouldShow = await _helperService.UserMatchesRecipients(userId, notification.Recipients);
                }

                if (shouldShow)
                {
                    var isRead = notification.IsReadByUser(userId ?? 0);
                    
                    if (unreadOnly && isRead)
                        continue;

                    result.Add(new NotificationDto
                    {
                        NotificationId = notification.NotificationId,
                        Title = notification.Title,
                        Message = notification.Message,
                        Type = (int)notification.Type,
                        IsRead = isRead,
                        AuctionId = notification.AuctionId,
                        BidId = notification.BidId,
                        PropertyId = notification.PropertyId,
                        EventId = notification.EventId,
                        CreatedAt = notification.CreatedAt
                    });
                }
            }

            return result;
        }

        // GET: api/notification/unread-count
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(new { message = "User not authenticated" });

            var notifications = await GetUserNotificationsWithBulk(userId.Value, true); // unread only
            return Ok(new { count = notifications.Count });
        }

        // PUT: api/notification/{id}/read
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(long id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(new { message = "User not authenticated" });

            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null)
                return NotFound(new { message = "Notification not found" });

            notification.MarkAsReadByUser(userId.Value);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Notification marked as read" });
        }

        // PUT: api/notification/read-all
        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(new { message = "User not authenticated" });

            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId || n.UserId == null)
                .ToListAsync();

            foreach (var notification in notifications)
            {
                // Check if user should see this notification
                if (notification.UserId.HasValue && notification.UserId.Value == userId.Value)
                {
                    notification.MarkAsReadByUser(userId.Value);
                }
                else if (!string.IsNullOrEmpty(notification.Recipients))
                {
                    if (await _helperService.UserMatchesRecipients(userId.Value, notification.Recipients))
                    {
                        notification.MarkAsReadByUser(userId.Value);
                    }
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "All notifications marked as read" });
        }

        // DELETE: api/notification/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNotification(long id)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
                return Unauthorized(new { message = "User not authenticated" });

            var success = await _notificationService.DeleteNotification(id, userId.Value);
            if (!success)
                return NotFound(new { message = "Notification not found" });

            return Ok(new { message = "Notification deleted" });
        }

        private long? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return null;
            }
            return userId;
        }

        // ========== ADMIN ENDPOINTS ==========

        // GET: api/notification/admin/users
        [HttpGet("admin/users")]
        [AdminAuthorize]
        public async Task<IActionResult> GetUsersForNotification([FromQuery] string? filter = null)
        {
            try
            {
                IQueryable<Account> query = _context.Accounts.Where(a => a.Type == AccountType.User);

                // Apply filters
                if (!string.IsNullOrEmpty(filter))
                {
                    switch (filter.ToLower())
                    {
                        case "all":
                            // No additional filter
                            break;
                        case "property_owners":
                            var propertyOwnerIds = await _context.ChildProperties
                                .Select(p => p.OwnerId)
                                .Distinct()
                                .ToListAsync();
                            query = query.Where(a => propertyOwnerIds.Contains(a.AccountId));
                            break;
                        case "auction_owners":
                            var auctionPropertyIds = await _context.Auctions
                                .Where(a => a.Status == "Active" || a.Status == "Requested")
                                .Select(a => a.PropertyId)
                                .Distinct()
                                .ToListAsync();
                            var auctionOwnerIds = await _context.ChildProperties
                                .Where(p => auctionPropertyIds.Contains((int)p.PropertyId))
                                .Select(p => p.OwnerId)
                                .Distinct()
                                .ToListAsync();
                            query = query.Where(a => auctionOwnerIds.Contains(a.AccountId));
                            break;
                        case "bidders":
                            var bidderIds = await _context.Bids
                                .Select(b => b.BidderId)
                                .Distinct()
                                .ToListAsync();
                            query = query.Where(a => bidderIds.Contains(a.AccountId));
                            break;
                        case "verified":
                            query = query.Where(a => a.Status == VerificationStatus.Verified);
                            break;
                        case "unverified":
                            query = query.Where(a => a.Status != VerificationStatus.Verified);
                            break;
                    }
                }

                var users = await query
                    .Select(a => new UserSummaryDto
                    {
                        AccountId = a.AccountId,
                        FirstName = a.FirstName,
                        LastName = a.LastName,
                        Email = a.Email,
                        PhoneNumber = a.PhoneNumber,
                        Status = a.Status.ToString(),
                        CreatedAt = a.CreatedAt
                    })
                    .OrderBy(a => a.FirstName)
                    .ToListAsync();

                return Ok(users);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error fetching users: {ex.Message}" });
            }
        }

        // GET: api/notification/admin/stats
        [HttpGet("admin/stats")]
        [AdminAuthorize]
        public async Task<IActionResult> GetUserStats()
        {
            try
            {
                var totalUsers = await _context.Accounts.CountAsync(a => a.Type == AccountType.User);
                var propertyOwnersCount = await _context.ChildProperties.Select(p => p.OwnerId).Distinct().CountAsync();
                var auctionOwnersCount = await _context.Auctions
                    .Where(a => a.Status == "Active" || a.Status == "Requested")
                    .Join(_context.ChildProperties, a => a.PropertyId, p => p.PropertyId, (a, p) => p.OwnerId)
                    .Distinct()
                    .CountAsync();
                var biddersCount = await _context.Bids.Select(b => b.BidderId).Distinct().CountAsync();
                var verifiedCount = await _context.Accounts.CountAsync(a => a.Type == AccountType.User && a.Status == VerificationStatus.Verified);

                return Ok(new
                {
                    totalUsers,
                    propertyOwnersCount,
                    auctionOwnersCount,
                    biddersCount,
                    verifiedCount,
                    unverifiedCount = totalUsers - verifiedCount
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error fetching stats: {ex.Message}" });
            }
        }

        // POST: api/notification/admin/send
        [HttpPost("admin/send")]
        [AdminAuthorize]
        public async Task<IActionResult> SendAdminNotification([FromBody] AdminNotificationDto notificationDto)
        {
            try
            {
                string recipients;
                int estimatedCount;

                // Map target type to recipients string
                switch (notificationDto.TargetType.ToLower())
                {
                    case "all_users_including_guests":
                        recipients = "all_users_including_guests";
                        estimatedCount = await _context.Accounts.CountAsync(a => a.Type == AccountType.User);
                        break;

                    case "guests_only":
                        recipients = "guests_only";
                        estimatedCount = 0; // Unknown number of guests
                        break;

                    case "logged_in_users":
                        recipients = "logged_in_users";
                        estimatedCount = await _context.Accounts.CountAsync(a => a.Type == AccountType.User);
                        break;

                    case "property_owners":
                        recipients = "property_owners";
                        estimatedCount = await _context.ChildProperties.Select(p => p.OwnerId).Distinct().CountAsync();
                        break;

                    case "auction_owners":
                        recipients = "auction_owners";
                        estimatedCount = await _helperService.GetRecipientCount("auction_owners");
                        break;

                    case "bidders":
                        recipients = "bidders";
                        estimatedCount = await _context.Bids.Select(b => b.BidderId).Distinct().CountAsync();
                        break;

                    case "verified_users":
                        recipients = "verified_users";
                        estimatedCount = await _context.Accounts
                            .CountAsync(a => a.Type == AccountType.User && a.Status == VerificationStatus.Verified);
                        break;

                    case "unverified_users":
                        recipients = "unverified_users";
                        estimatedCount = await _context.Accounts
                            .CountAsync(a => a.Type == AccountType.User && a.Status != VerificationStatus.Verified);
                        break;

                    case "specific":
                        if (notificationDto.UserIds == null || !notificationDto.UserIds.Any())
                        {
                            return BadRequest(new { message = "No user IDs provided for specific targeting" });
                        }
                        recipients = $"specific:{string.Join(",", notificationDto.UserIds)}";
                        estimatedCount = notificationDto.UserIds.Count;
                        break;

                    default:
                        return BadRequest(new { message = "Invalid target type" });
                }

                // Create ONE notification with Recipients field
                var notification = new Notification
                {
                    UserId = null, // Bulk notification has no specific user
                    Recipients = recipients,
                    Title = notificationDto.Title,
                    Message = notificationDto.Message,
                    Type = NotificationType.General,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();

                // Broadcast notification via Firestore for real-time updates
                await _firestoreService.BroadcastGeneralUpdateAsync("admin_notification", notification);

                // Also update individual user notifications in Firestore for specific targeting
                if (notificationDto.TargetType == "specific" && notificationDto.UserIds != null)
                {
                    foreach (var userId in notificationDto.UserIds)
                    {
                        await _firestoreService.UpdateUserNotificationAsync(userId, notification);
                    }
                }

                return Ok(new
                {
                    success = true,
                    message = $"✅ Notification sent successfully to {estimatedCount} user(s)!",
                    title = notificationDto.Title,
                    recipients = recipients,
                    estimatedRecipients = estimatedCount,
                    notificationId = notification.NotificationId,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error sending notification: {ex.Message}" });
            }
        }

        // GET: api/notification/admin/history
        [HttpGet("admin/history")]
        [AdminAuthorize]
        public async Task<IActionResult> GetNotificationHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            try
            {
                var skip = (page - 1) * pageSize;
                var notifications = await _context.Notifications
                    .OrderByDescending(n => n.CreatedAt)
                    .Skip(skip)
                    .Take(pageSize)
                    .Include(n => n.User)
                    .Select(n => new
                    {
                        n.NotificationId,
                        n.UserId,
                        UserName = n.User.FirstName + " " + n.User.LastName,
                        n.Title,
                        n.Message,
                        n.Type,
                        n.IsRead,
                        n.CreatedAt,
                        n.ReadAt
                    })
                    .ToListAsync();

                var totalCount = await _context.Notifications.CountAsync();

                return Ok(new
                {
                    notifications,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error fetching notification history: {ex.Message}" });
            }
        }
    }

    // DTOs
    public class AdminNotificationDto
    {
        public string TargetType { get; set; } = string.Empty; 
        // "all_users_including_guests", "guests_only", "logged_in_users", 
        // "property_owners", "auction_owners", "bidders", "verified_users", "unverified_users", "specific"
        public List<long>? UserIds { get; set; } // For specific users
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
    }

    public class UserSummaryDto
    {
        public long AccountId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class NotificationDto
    {
        public long NotificationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public int Type { get; set; }
        public bool IsRead { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }
        public long? PropertyId { get; set; }
        public long? EventId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

