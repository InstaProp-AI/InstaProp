using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace InstapropAPI.Services
{
    public class RewardService
    {
        private readonly AppDbContext _context;

        public RewardService(AppDbContext context)
        {
            _context = context;
        }

        public async Task AwardPointsAsync(Guid accountId, string rewardType, int points, string? description = null, Guid? relatedPropertyId = null)
        {
            var reward = new UserReward
            {
                AccountId = accountId,
                RewardType = rewardType,
                Points = points,
                Description = description,
                RelatedPropertyId = relatedPropertyId,
                EarnedAt = DateTime.UtcNow
            };

            _context.UserRewards.Add(reward);

            // Update both TotalEarnedPoints and CurrentPoints
            var account = await _context.Accounts.FindAsync(accountId);
            if (account != null)
            {
                account.TotalEarnedPoints += points;
                account.CurrentPoints += points;
            }

            await _context.SaveChangesAsync();

            // Check for badge achievements
            await CheckAndAwardBadgesAsync(accountId);
        }

        public async Task<int> GetTotalPointsAsync(Guid accountId)
        {
            var account = await _context.Accounts.FindAsync(accountId);
            return account?.TotalEarnedPoints ?? 0;
        }

        public async Task<int> GetCurrentPointsAsync(Guid accountId)
        {
            var account = await _context.Accounts.FindAsync(accountId);
            return account?.CurrentPoints ?? 0;
        }

        public async Task<bool> SpendPointsAsync(Guid accountId, int points)
        {
            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null || account.CurrentPoints < points)
                return false;
            
            account.CurrentPoints -= points;
            await _context.SaveChangesAsync();
            return true;
        }

        public string GeneratePromoCode()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            var random = new Random();
            return new string(Enumerable.Repeat(chars, 5)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }

        private async Task CheckAndAwardBadgesAsync(Guid accountId)
        {
            var totalPoints = await GetTotalPointsAsync(accountId);
            var existingBadges = await _context.UserBadges
                .Where(b => b.AccountId == accountId)
                .Select(b => b.BadgeName)
                .ToListAsync();

            // Award badges based on milestones (lowered thresholds for easier achievement)
            var badgesToAward = new List<(string name, string icon, string description)>();

            if (totalPoints >= 500 && !existingBadges.Contains("Getting Started"))
                badgesToAward.Add(("Getting Started", "🌟", "Earned 500 points"));

            if (totalPoints >= 1000 && !existingBadges.Contains("Active User"))
                badgesToAward.Add(("Active User", "🔥", "Earned 1000 points"));

            if (totalPoints >= 2500 && !existingBadges.Contains("Power User"))
                badgesToAward.Add(("Power User", "⚡", "Earned 2500 points"));

            if (totalPoints >= 5000 && !existingBadges.Contains("VIP Member"))
                badgesToAward.Add(("VIP Member", "👑", "Earned 5000 points"));

            if (totalPoints >= 10000 && !existingBadges.Contains("Elite"))
                badgesToAward.Add(("Elite", "💎", "Earned 10000 points"));

            // Check for first bid badge
            var hasBid = await _context.Bids.AnyAsync(b => b.BidderId == accountId);
            if (hasBid && !existingBadges.Contains("First Bidder"))
                badgesToAward.Add(("First Bidder", "🎯", "Placed your first bid"));

            // Award new badges
            foreach (var (name, icon, description) in badgesToAward)
            {
                _context.UserBadges.Add(new UserBadge
                {
                    AccountId = accountId,
                    BadgeName = name,
                    BadgeIcon = icon,
                    Description = description,
                    AwardedAt = DateTime.UtcNow
                });
            }

            if (badgesToAward.Any())
                await _context.SaveChangesAsync();
        }

        public async Task<List<UserBadge>> GetUserBadgesAsync(Guid accountId)
        {
            return await _context.UserBadges
                .Where(b => b.AccountId == accountId)
                .OrderByDescending(b => b.AwardedAt)
                .ToListAsync();
        }
    }

    // Reward point values (increased for easier achievement)
    public static class RewardPoints
    {
        public const int PropertySaved = 50;
        public const int FirstBid = 150;
        public const int Bid = 100;
        public const int Purchase = 1000;
        public const int Referral = 500;
        public const int SuccessfulReferral = 1000; // When referred user makes purchase
        public const int Valuation = 150; // Property valuation
        public const int AddProperty = 200; // Adding a property
        public const int EventCreated = 20; // Creating an event
        public const int ScheduleImport = 250; // Importing payment schedule
    }
}

