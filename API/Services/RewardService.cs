using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace PropertyFlipperAPI.Services
{
    public class RewardService
    {
        private readonly AppDbContext _context;

        public RewardService(AppDbContext context)
        {
            _context = context;
        }

        public async Task AwardPointsAsync(long accountId, string rewardType, int points, string? description = null, long? relatedPropertyId = null)
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
            await _context.SaveChangesAsync();

            // Check for badge achievements
            await CheckAndAwardBadgesAsync(accountId);
        }

        public async Task<int> GetTotalPointsAsync(long accountId)
        {
            return await _context.UserRewards
                .Where(r => r.AccountId == accountId)
                .SumAsync(r => r.Points);
        }

        private async Task CheckAndAwardBadgesAsync(long accountId)
        {
            var totalPoints = await GetTotalPointsAsync(accountId);
            var existingBadges = await _context.UserBadges
                .Where(b => b.AccountId == accountId)
                .Select(b => b.BadgeName)
                .ToListAsync();

            // Award badges based on milestones
            var badgesToAward = new List<(string name, string icon, string description)>();

            if (totalPoints >= 100 && !existingBadges.Contains("Getting Started"))
                badgesToAward.Add(("Getting Started", "🌟", "Earned 100 points"));

            if (totalPoints >= 500 && !existingBadges.Contains("Active User"))
                badgesToAward.Add(("Active User", "🔥", "Earned 500 points"));

            if (totalPoints >= 1000 && !existingBadges.Contains("Power User"))
                badgesToAward.Add(("Power User", "⚡", "Earned 1000 points"));

            if (totalPoints >= 5000 && !existingBadges.Contains("VIP Member"))
                badgesToAward.Add(("VIP Member", "👑", "Earned 5000 points"));

            // Check for first bid badge
            var hasBid = await _context.Bids.AnyAsync(b => b.BidderId == accountId);
            if (hasBid && !existingBadges.Contains("First Bidder"))
                badgesToAward.Add(("First Bidder", "🎯", "Placed your first bid"));

            // Check for first property view badge
            var viewCount = await _context.PropertyViews.CountAsync(v => v.UserId == accountId);
            if (viewCount >= 10 && !existingBadges.Contains("Property Explorer"))
                badgesToAward.Add(("Property Explorer", "🔍", "Viewed 10+ properties"));

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

        public async Task<List<UserBadge>> GetUserBadgesAsync(long accountId)
        {
            return await _context.UserBadges
                .Where(b => b.AccountId == accountId)
                .OrderByDescending(b => b.AwardedAt)
                .ToListAsync();
        }
    }

    // Reward point values
    public static class RewardPoints
    {
        public const int PropertyView = 1;
        public const int PropertySaved = 5;
        public const int FirstBid = 10;
        public const int Bid = 5;
        public const int Purchase = 100;
        public const int Referral = 50;
        public const int SuccessfulReferral = 100; // When referred user makes purchase
    }
}

