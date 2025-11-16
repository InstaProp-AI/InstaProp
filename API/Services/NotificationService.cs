using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    public class NotificationService
    {
        private readonly AppDbContext _context;
        private readonly FirestoreService _firestoreService;

        public NotificationService(AppDbContext context, FirestoreService firestoreService)
        {
            _context = context;
            _firestoreService = firestoreService;
        }

        // Create notification when someone places a bid on your auction
        public async Task NotifyAuctionOwnerOfBid(long auctionId, long bidderId, decimal bidAmount)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == auctionId);

            if (auction?.Property == null) return;

            var bidder = await _context.Accounts.FindAsync(bidderId);
            if (bidder == null) return;

            var notification = new Notification
            {
                UserId = auction.Property.OwnerId,
                Title = "New Bid Placed",
                Message = $"{bidder.FirstName} {bidder.LastName} placed a bid of ${bidAmount:N2} on your property '{auction.Property.Name}'.",
                Type = NotificationType.BidPlaced,
                AuctionId = auctionId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Update Firestore for real-time sync
            await _firestoreService.UpdateUserNotificationAsync((long)auction.Property.OwnerId, notification);
        }

        // Create notification when someone places a higher bid (outbid)
        public async Task NotifyOutbidBidders(long auctionId, long newBidderId, decimal newBidAmount)
        {
            // Get all unique bidders for this auction except the new bidder
            var previousBidders = await _context.Bids
                .Where(b => b.AuctionId == auctionId && b.BidderId != newBidderId)
                .Select(b => b.BidderId)
                .Distinct()
                .ToListAsync();

            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == auctionId);

            if (auction?.Property == null) return;

            var notificationsToSync = new List<(long userId, Notification notification)>();

            // Load all bids for this auction into memory to avoid SQLite decimal aggregate issues
            var allAuctionBids = await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .ToListAsync();

            foreach (var bidderId in previousBidders)
            {
                // Only notify if their highest bid is lower than the new bid
                // Use LINQ to Objects (in-memory) to avoid SQLite decimal aggregate issues
                var bidderBids = allAuctionBids.Where(b => b.BidderId == bidderId).ToList();
                
                if (bidderBids.Any())
                {
                    var highestBid = bidderBids.Max(b => b.BidAmount);

                    if (highestBid < newBidAmount)
                    {
                        var notification = new Notification
                        {
                            UserId = bidderId,
                            Title = "You've Been Outbid",
                            Message = $"Someone placed a higher bid of ${newBidAmount:N2} on '{auction.Property.Name}'. Place a new bid to stay in the race!",
                            Type = NotificationType.Outbid,
                            AuctionId = auctionId,
                            CreatedAt = DateTime.UtcNow
                        };

                        _context.Notifications.Add(notification);
                        notificationsToSync.Add((bidderId, notification));
                    }
                }
            }

            // Save to database first to get NotificationIds
            await _context.SaveChangesAsync();

            // Then sync to Firestore
            foreach (var (userId, notification) in notificationsToSync)
            {
                await _firestoreService.UpdateUserNotificationAsync(userId, notification);
            }
        }

        // Create notification when a new auction starts
        public async Task NotifyNewAuction(long auctionId)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == auctionId);

            if (auction?.Property == null) return;

            // Get all users except the auction owner
            var users = await _context.Accounts
                .Where(a => a.AccountId != auction.Property.OwnerId && a.Type == AccountType.User)
                .ToListAsync();

            var notificationsToSync = new List<(long userId, Notification notification)>();

            foreach (var user in users)
            {
                var notification = new Notification
                {
                    UserId = user.AccountId,
                    Title = "New Auction Started",
                    Message = $"A new auction for '{auction.Property.Name}' has started with a starting price of ${auction.StartPrice:N2}.",
                    Type = NotificationType.AuctionStarted,
                    AuctionId = auctionId,
                    PropertyId = auction.PropertyId,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Notifications.Add(notification);
                notificationsToSync.Add((user.AccountId, notification));
            }

            // Save to database first to get NotificationIds
            await _context.SaveChangesAsync();

            // Then sync to Firestore
            foreach (var (userId, notification) in notificationsToSync)
            {
                await _firestoreService.UpdateUserNotificationAsync(userId, notification);
            }
        }

        // Create notification when auction is approved
        public async Task NotifyAuctionApproved(long auctionId)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == auctionId);

            if (auction?.Property == null) return;

            var notification = new Notification
            {
                UserId = auction.Property.OwnerId,
                Title = "Auction Approved",
                Message = $"Your auction request for '{auction.Property.Name}' has been approved and is now active!",
                Type = NotificationType.AuctionApproved,
                AuctionId = auctionId,
                PropertyId = auction.PropertyId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Update Firestore for real-time sync
            await _firestoreService.UpdateUserNotificationAsync((long)auction.Property.OwnerId, notification);
        }

        // Create notification when auction is rejected
        public async Task NotifyAuctionRejected(long auctionId)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == auctionId);

            if (auction?.Property == null) return;

            var notification = new Notification
            {
                UserId = auction.Property.OwnerId,
                Title = "Auction Rejected",
                Message = $"Your auction request for '{auction.Property.Name}' has been rejected. Please contact support for more information.",
                Type = NotificationType.AuctionRejected,
                AuctionId = auctionId,
                PropertyId = auction.PropertyId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Update Firestore for real-time sync
            await _firestoreService.UpdateUserNotificationAsync((long)auction.Property.OwnerId, notification);
        }

        // Create notification for upcoming events (reminder)
        public async Task NotifyEventReminder(long eventId)
        {
            var eventItem = await _context.Events.FindAsync(eventId);
            if (eventItem == null) return;

            var notification = new Notification
            {
                UserId = eventItem.UserId,
                Title = "Event Reminder",
                Message = $"Reminder: '{eventItem.Title}' is scheduled for {eventItem.EventDate:MMMM dd, yyyy}.",
                Type = NotificationType.EventReminder,
                EventId = eventId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Update Firestore for real-time sync
            await _firestoreService.UpdateUserNotificationAsync(eventItem.UserId, notification);
        }

        // Create notification for new public events
        public async Task NotifyNewPublicEvent(long eventId)
        {
            var eventItem = await _context.Events.FindAsync(eventId);
            if (eventItem == null || !eventItem.IsPublic) return;

            // Get all users except the event creator
            var users = await _context.Accounts
                .Where(a => a.AccountId != eventItem.UserId && a.Type == AccountType.User)
                .ToListAsync();

            var notificationsToSync = new List<(long userId, Notification notification)>();

            foreach (var user in users)
            {
                var notification = new Notification
                {
                    UserId = user.AccountId,
                    Title = "New Public Event",
                    Message = $"A new public event '{eventItem.Title}' has been added to the calendar on {eventItem.EventDate:MMMM dd, yyyy}.",
                    Type = NotificationType.PublicEvent,
                    EventId = eventId,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Notifications.Add(notification);
                notificationsToSync.Add((user.AccountId, notification));
            }

            // Save to database first to get NotificationIds
            await _context.SaveChangesAsync();

            // Then sync to Firestore
            foreach (var (userId, notification) in notificationsToSync)
            {
                await _firestoreService.UpdateUserNotificationAsync(userId, notification);
            }
        }

        // Get all notifications for a user
        public async Task<List<Notification>> GetUserNotifications(long userId, bool unreadOnly = false)
        {
            var query = _context.Notifications.Where(n => n.UserId == userId);

            if (unreadOnly)
            {
                query = query.Where(n => !n.IsRead);
            }

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();
        }

        // Mark notification as read
        public async Task<bool> MarkAsRead(long notificationId, long userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.NotificationId == notificationId && n.UserId == userId);

            if (notification == null) return false;

            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return true;
        }

        // Mark all notifications as read for a user
        public async Task MarkAllAsRead(long userId)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        // Delete notification
        public async Task<bool> DeleteNotification(long notificationId, long userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.NotificationId == notificationId && n.UserId == userId);

            if (notification == null) return false;

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();

            return true;
        }

        // Get unread count
        public async Task<int> GetUnreadCount(long userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }
    }
}

