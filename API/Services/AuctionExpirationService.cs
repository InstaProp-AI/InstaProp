using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Background service that automatically updates auction status to "Ended" when the auction time expires.
    /// Runs every 30 seconds to check for expired auctions.
    /// </summary>
    public class AuctionExpirationService : BackgroundService
    {
        private readonly ILogger<AuctionExpirationService> _logger;
        private readonly IServiceProvider _serviceProvider;

        public AuctionExpirationService(
            ILogger<AuctionExpirationService> logger,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 Auction Expiration Service started");

            // Wait a bit before starting the first check
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckAndUpdateExpiredAuctions();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error in Auction Expiration Service");
                }

                // Run every 30 seconds
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }

            _logger.LogInformation("🛑 Auction Expiration Service stopped");
        }

        private async Task CheckAndUpdateExpiredAuctions()
        {
            // Create a new scope for this operation
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var firestoreService = scope.ServiceProvider.GetRequiredService<FirestoreService>();

            var now = DateTime.UtcNow;

            // Find all active auctions that have expired
            var expiredAuctions = await context.Auctions
                .Include(a => a.Property)
                    .ThenInclude(p => p.Owner)
                .Include(a => a.Bids)
                    .ThenInclude(b => b.Bidder)
                .Where(a => a.Status == "Active")
                .ToListAsync();

            // Filter expired auctions (end time has passed)
            var auctionsToEnd = expiredAuctions
                .Where(a => a.StartAt.AddHours(a.Duration) < now)
                .ToList();

            if (auctionsToEnd.Any())
            {
                _logger.LogInformation($"⏰ Found {auctionsToEnd.Count} expired auction(s) to update");

                foreach (var auction in auctionsToEnd)
                {
                    var endTime = auction.StartAt.AddHours(auction.Duration);
                    _logger.LogInformation(
                        $"🔄 Ending auction #{auction.AuctionId} (Property: {auction.Property?.Name ?? "N/A"}) - Ended at: {endTime:yyyy-MM-dd HH:mm:ss} UTC"
                    );

                    // Update status to Ended
                    auction.Status = "Ended";

                    // Check if there's a winning bidder
                    var winningBid = auction.Bids
                        .OrderByDescending(b => b.BidAmount)
                        .FirstOrDefault();

                    if (winningBid != null && winningBid.Bidder != null)
                    {
                        // Notify the winner (highest bidder)
                        var winnerNotification = new Notification
                        {
                            UserId = winningBid.BidderId,
                            Title = "🎉 Congratulations - You Won!",
                            Message = $"Congratulations! You won the auction for '{auction.Property?.Name}' with your bid of ${winningBid.BidAmount:N2}. We will call you soon to schedule a meeting to finalize the purchase and arrange payment.",
                            Type = NotificationType.AuctionWon,
                            AuctionId = auction.AuctionId,
                            PropertyId = auction.PropertyId,
                            CreatedAt = DateTime.UtcNow
                        };
                        context.Notifications.Add(winnerNotification);

                        // Notify the auction lister (property owner)
                        if (auction.Property?.Owner != null)
                        {
                            var listerNotification = new Notification
                            {
                                UserId = auction.Property.OwnerId,
                                Title = "Auction Ended - Congratulations!",
                                Message = $"Your auction for '{auction.Property.Name}' has ended. The winning bid was ${winningBid.BidAmount:N2} from {winningBid.Bidder.FirstName} {winningBid.Bidder.LastName}. We will call you soon to schedule a meeting with the buyer to finalize the sale.",
                                Type = NotificationType.AuctionEnded,
                                AuctionId = auction.AuctionId,
                                PropertyId = auction.PropertyId,
                                CreatedAt = DateTime.UtcNow
                            };
                            context.Notifications.Add(listerNotification);
                        }

                        // Notify losing bidders
                        var losingBidders = auction.Bids
                            .Where(b => b.BidderId != winningBid.BidderId)
                            .Select(b => b.BidderId)
                            .Distinct()
                            .ToList();

                        foreach (var loserId in losingBidders)
                        {
                            var loserNotification = new Notification
                            {
                                UserId = loserId,
                                Title = "Auction Ended",
                                Message = $"The auction for '{auction.Property?.Name}' has ended. Unfortunately, you were outbid. Don't worry, there are many more opportunities!",
                                Type = NotificationType.AuctionLost,
                                AuctionId = auction.AuctionId,
                                PropertyId = auction.PropertyId,
                                CreatedAt = DateTime.UtcNow
                            };
                            context.Notifications.Add(loserNotification);
                        }

                        _logger.LogInformation($"✉️ Created notifications for auction #{auction.AuctionId} (1 winner, 1 lister, {losingBidders.Count} losers)");
                    }
                    else if (auction.Property?.Owner != null)
                    {
                        // No bids - notify the lister
                        var noBidsNotification = new Notification
                        {
                            UserId = auction.Property.OwnerId,
                            Title = "Auction Ended - No Bids",
                            Message = $"Your auction for '{auction.Property.Name}' has ended with no bids. Consider relisting with a lower starting price or different timing.",
                            Type = NotificationType.AuctionEnded,
                            AuctionId = auction.AuctionId,
                            PropertyId = auction.PropertyId,
                            CreatedAt = DateTime.UtcNow
                        };
                        context.Notifications.Add(noBidsNotification);
                        _logger.LogInformation($"✉️ Created no-bids notification for auction #{auction.AuctionId}");
                    }

                    // Update Firestore for real-time sync
                    try
                    {
                        await firestoreService.UpdateAuctionAsync(auction.AuctionId, auction);
                        _logger.LogInformation($"✅ Updated Firestore for auction #{auction.AuctionId}");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Failed to update Firestore for auction #{auction.AuctionId}");
                    }
                }

                // Save all changes at once
                await context.SaveChangesAsync();
                _logger.LogInformation($"✅ Successfully ended {auctionsToEnd.Count} auction(s)");
            }
        }
    }
}

