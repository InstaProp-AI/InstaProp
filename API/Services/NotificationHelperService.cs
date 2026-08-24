using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    public class NotificationHelperService
    {
        private readonly AppDbContext _context;

        public NotificationHelperService(AppDbContext context)
        {
            _context = context;
        }

        // Check if a user matches the recipient criteria
        public async Task<bool> UserMatchesRecipients(Guid? userId, string recipients)
        {
            if (string.IsNullOrEmpty(recipients))
                return false;

            var recipientType = recipients.ToLower();

            switch (recipientType)
            {
                case "all_users_including_guests":
                    return true; // Everyone sees this, even not logged in

                case "guests_only":
                    return !userId.HasValue; // Only for non-logged-in users

                case "logged_in_users":
                case "all_users":
                    return userId.HasValue; // Only logged-in users

                case "property_owners":
                    if (!userId.HasValue) return false;
                    return await _context.Properties
                        .AnyAsync(p => p.OwnerId == userId.Value);

                case "auction_owners":
                    if (!userId.HasValue) return false;
                    var auctionPropertyIds = await _context.Auctions
                        .Where(a => a.Status == "Active" || a.Status == "Requested")
                        .Select(a => a.PropertyId)
                        .ToListAsync();
                    return await _context.Properties
                        .AnyAsync(p => auctionPropertyIds.Contains(p.PropertyId) && p.OwnerId == userId.Value);

                case "bidders":
                    if (!userId.HasValue) return false;
                    return await _context.Bids
                        .AnyAsync(b => b.BidderId == userId.Value);

                case "verified_users":
                    if (!userId.HasValue) return false;
                    var verifiedUser = await _context.Accounts.FindAsync(userId.Value);
                    return verifiedUser?.Status == VerificationStatus.Verified;

                case "unverified_users":
                    if (!userId.HasValue) return false;
                    var unverifiedUser = await _context.Accounts.FindAsync(userId.Value);
                    return unverifiedUser?.Status != VerificationStatus.Verified;

                default:
                    // Handle specific users: "specific:1,2,3,4"
                    if (recipientType.StartsWith("specific:"))
                    {
                        if (!userId.HasValue) return false;
                        var userIds = recipientType.Substring(9)
                            .Split(',', StringSplitOptions.RemoveEmptyEntries)
                            .Select(id => Guid.TryParse(id, out var parsedId) ? parsedId : Guid.Empty)
                            .Where(id => id != Guid.Empty)
                            .ToList();
                        return userIds.Contains(userId.Value);
                    }
                    return false;
            }
        }

        // Get recipient count for preview
        public async Task<int> GetRecipientCount(string recipients)
        {
            var recipientType = recipients.ToLower();

            switch (recipientType)
            {
                case "all_users_including_guests":
                    return int.MaxValue; // Can't count guests

                case "guests_only":
                    return 0; // Can't count guests

                case "logged_in_users":
                case "all_users":
                    return await _context.Accounts.CountAsync(a => a.RoleId == Role.USER_ROLE_ID);

                case "property_owners":
                    return await _context.Properties.Select(p => p.OwnerId).Distinct().CountAsync();

                case "auction_owners":
                    var auctionPropertyIds = await _context.Auctions
                        .Where(a => a.Status == "Active" || a.Status == "Requested")
                        .Select(a => a.PropertyId)
                        .ToListAsync();
                    return await _context.Properties
                        .Where(p => auctionPropertyIds.Contains(p.PropertyId))
                        .Select(p => p.OwnerId)
                        .Distinct()
                        .CountAsync();

                case "bidders":
                    return await _context.Bids.Select(b => b.BidderId).Distinct().CountAsync();

                case "verified_users":
                    return await _context.Accounts
                        .CountAsync(a => a.RoleId == Role.USER_ROLE_ID && a.Status == VerificationStatus.Verified);

                case "unverified_users":
                    return await _context.Accounts
                        .CountAsync(a => a.RoleId == Role.USER_ROLE_ID && a.Status != VerificationStatus.Verified);

                default:
                    if (recipientType.StartsWith("specific:"))
                    {
                        var userIds = recipientType.Substring(9)
                            .Split(',', StringSplitOptions.RemoveEmptyEntries)
                            .Select(id => Guid.TryParse(id, out var parsedId) ? parsedId : Guid.Empty)
                            .Where(id => id != Guid.Empty)
                            .ToList();
                        return userIds.Count();
                    }
                    return 0;
            }
        }
    }
}

