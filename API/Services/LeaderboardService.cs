using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Services
{
    public class LeaderboardService
    {
        private readonly AppDbContext _context;
        private readonly RewardService _rewardService;
        private readonly ILogger<LeaderboardService>? _logger;

        private static readonly decimal[] CashbackPrizes = { 2000m, 1000m, 500m };
        private static readonly string[] PrizeLabels = { "Champion", "Runner-up", "Third place" };
        private const string CashbackRewardType = "WeeklyLeaderboardCashback";

        private static readonly Dictionary<string, string> RewardTypeCategories = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Bid"] = "Bidding Blitz",
            ["FirstBid"] = "Bidding Blitz",
            ["Purchase"] = "Deal Closers",
            ["Referral"] = "Referral Rocket",
            ["SuccessfulReferral"] = "Referral Rocket",
            ["PropertySaved"] = "Market Scouts",
            ["Valuation"] = "Valuation Masters",
            ["AddProperty"] = "Listing Legends",
            ["EventCreated"] = "Community Builders",
            ["ScheduleImport"] = "Finance Gurus",
            [CashbackRewardType] = "Leaderboard"
        };

        public LeaderboardService(AppDbContext context, RewardService rewardService, ILogger<LeaderboardService>? logger = null)
        {
            _context = context;
            _rewardService = rewardService;
            _logger = logger;
        }

        public async Task<LeaderboardResponseDto> GetLeaderboardAsync(
            LeaderboardPeriod period,
            long? requestingAccountId,
            CancellationToken cancellationToken = default)
        {
            var (rangeStart, rangeEndExclusive) = GetDateRange(period, DateTime.UtcNow);

            if (period == LeaderboardPeriod.LastWeek)
            {
                var snapshot = await EnsureWeeklySnapshotAsync(rangeStart, cancellationToken);
                var aggregates = await BuildAggregatedRowsAsync(rangeStart, rangeEndExclusive, cancellationToken, snapshot.Standings.Select(s => s.AccountId).Distinct().ToList());
                return BuildSnapshotResponse(snapshot, aggregates, requestingAccountId, period, rangeStart, rangeEndExclusive);
            }

            var aggregatedRows = await BuildAggregatedRowsAsync(rangeStart, rangeEndExclusive, cancellationToken);
            var response = await BuildDynamicResponseAsync(
                aggregatedRows,
                period,
                rangeStart,
                rangeEndExclusive,
                requestingAccountId,
                cancellationToken,
                applyPotentialCashback: period == LeaderboardPeriod.ThisWeek);

            if (aggregatedRows.Count > 0)
            {
                await UpsertCachedStandingsAsync(period, aggregatedRows, cancellationToken);
            }

            return response;
        }

        public async Task<LeaderboardHighlightsResponseDto> GetHighlightsAsync(
            long? requestingAccountId,
            CancellationToken cancellationToken = default)
        {
            var now = DateTime.UtcNow;
            var lastWeekRange = GetDateRange(LeaderboardPeriod.LastWeek, now);
            var thisWeekRange = GetDateRange(LeaderboardPeriod.ThisWeek, now);

            var snapshot = await EnsureWeeklySnapshotAsync(lastWeekRange.Start, cancellationToken);
            var lastWeekAggregates = await BuildAggregatedRowsAsync(lastWeekRange.Start, lastWeekRange.End, cancellationToken, snapshot.Standings.Select(s => s.AccountId).Distinct().ToList());
            var lastWeekEntries = BuildSnapshotResponse(snapshot, lastWeekAggregates, requestingAccountId, LeaderboardPeriod.LastWeek, lastWeekRange.Start, lastWeekRange.End).Entries;

            var thisWeekAggregates = await BuildAggregatedRowsAsync(thisWeekRange.Start, thisWeekRange.End, cancellationToken);
            var thisWeekResponse = await BuildDynamicResponseAsync(
                thisWeekAggregates,
                LeaderboardPeriod.ThisWeek,
                thisWeekRange.Start,
                thisWeekRange.End,
                requestingAccountId,
                cancellationToken,
                applyPotentialCashback: true);

            return new LeaderboardHighlightsResponseDto
            {
                LastWeek = new LeaderboardHighlightDto
                {
                    RangeStart = lastWeekRange.Start,
                    RangeEnd = lastWeekRange.End,
                    Headline = snapshot.HighlightHeadline ?? $"Weekly champion: {lastWeekEntries.FirstOrDefault()?.DisplayName}",
                    Summary = snapshot.HighlightSummary ?? $"Top scorers collected {lastWeekEntries.FirstOrDefault()?.Points ?? 0} pts last week.",
                    First = lastWeekEntries.FirstOrDefault(),
                    Second = lastWeekEntries.Skip(1).FirstOrDefault(),
                    Third = lastWeekEntries.Skip(2).FirstOrDefault()
                },
                ThisWeek = new LeaderboardHighlightDto
                {
                    RangeStart = thisWeekRange.Start,
                    RangeEnd = thisWeekRange.End,
                    Headline = thisWeekResponse.Headline,
                    Summary = thisWeekResponse.Subheading,
                    First = thisWeekResponse.Entries.FirstOrDefault(),
                    Second = thisWeekResponse.Entries.Skip(1).FirstOrDefault(),
                    Third = thisWeekResponse.Entries.Skip(2).FirstOrDefault()
                },
                PersonalThisWeek = thisWeekResponse.PersonalEntry,
                ActionablePrompts = BuildActionPrompts(thisWeekResponse.PersonalEntry)
            };
        }

        private async Task UpsertCachedStandingsAsync(
            LeaderboardPeriod period,
            List<LeaderboardComputationRow> aggregates,
            CancellationToken cancellationToken)
        {
            if (period != LeaderboardPeriod.ThisWeek && period != LeaderboardPeriod.AllTime)
            {
                return;
            }

            var topEntries = aggregates
                .OrderByDescending(a => a.Points)
                .ThenByDescending(a => a.TotalRewards)
                .Take(50)
                .ToList();

            var existing = await _context.LeaderboardStandings
                .Where(ls => ls.Period == period && ls.SnapshotId == null)
                .ToListAsync(cancellationToken);

            if (existing.Count > 0)
            {
                _context.LeaderboardStandings.RemoveRange(existing);
            }

            var streaks = await GetStreakWeeksAsync(topEntries.Select(t => t.AccountId).ToList(), cancellationToken);
            var now = DateTime.UtcNow;
            var rank = 1;

            foreach (var entry in topEntries)
            {
                _context.LeaderboardStandings.Add(new LeaderboardStanding
                {
                    AccountId = entry.AccountId,
                    Period = period,
                    Rank = rank,
                    Points = entry.Points,
                    CashbackAwarded = 0m,
                    EngagementScore = entry.EngagementScore,
                    StreakWeeks = streaks.TryGetValue(entry.AccountId, out var streak) ? streak : 0,
                    RewardSummary = null,
                    ComputedAt = now
                });
                rank++;
            }

            await _context.SaveChangesAsync(cancellationToken);
        }

        private async Task<WeeklyLeaderboardSnapshot> EnsureWeeklySnapshotAsync(
            DateTime weekStart,
            CancellationToken cancellationToken)
        {
            var weekEnd = weekStart.AddDays(7).AddTicks(-1);

            var snapshot = await _context.WeeklyLeaderboardSnapshots
                .Include(s => s.Standings)
                .ThenInclude(s => s.Account)
                .FirstOrDefaultAsync(s => s.WeekStart == weekStart && s.WeekEnd == weekEnd, cancellationToken);

            if (snapshot == null)
            {
                var aggregates = await BuildAggregatedRowsAsync(
                    weekStart,
                    weekStart.AddDays(7),
                    cancellationToken);

                var topEntries = aggregates
                    .OrderByDescending(a => a.Points)
                    .ThenByDescending(a => a.TotalRewards)
                    .Take(50)
                    .ToList();

                snapshot = new WeeklyLeaderboardSnapshot
                {
                    WeekStart = weekStart,
                    WeekEnd = weekEnd,
                    HighlightHeadline = BuildHeadline(topEntries),
                    HighlightSummary = BuildSummary(topEntries),
                };

                PopulateSnapshotStandings(snapshot, topEntries);

                _context.WeeklyLeaderboardSnapshots.Add(snapshot);
                await _context.SaveChangesAsync(cancellationToken);
            }

            await ProcessSnapshotPayoutsAsync(snapshot, cancellationToken);

            return snapshot;
        }

        private async Task ProcessSnapshotPayoutsAsync(
            WeeklyLeaderboardSnapshot snapshot,
            CancellationToken cancellationToken)
        {
            if (snapshot.PayoutProcessed)
            {
                return;
            }

            var standingsOrdered = snapshot.Standings
                .OrderBy(s => s.Rank)
                .Take(CashbackPrizes.Length)
                .ToList();

            for (var index = 0; index < standingsOrdered.Count; index++)
            {
                var standing = standingsOrdered[index];
                var prize = CashbackPrizes[index];
                var label = PrizeLabels[index];

                standing.CashbackAwarded = prize;
                standing.RewardSummary = $"{label} cashback bonus {prize:0} EGP unlocked";

                try
                {
                    await _rewardService.AwardPointsAsync(
                        standing.AccountId,
                        CashbackRewardType,
                        (int)prize,
                        $"{label} - Week of {snapshot.WeekStart:MMM dd}",
                        null);
                }
                catch (Exception ex)
                {
                    _logger?.LogError(ex, "Failed to award leaderboard cashback for account {AccountId}", standing.AccountId);
                }
            }

            snapshot.PayoutProcessed = true;
            await _context.SaveChangesAsync(cancellationToken);
        }

        private LeaderboardResponseDto BuildSnapshotResponse(
            WeeklyLeaderboardSnapshot snapshot,
            List<LeaderboardComputationRow> aggregates,
            long? requestingAccountId,
            LeaderboardPeriod period,
            DateTime rangeStart,
            DateTime rangeEndExclusive)
        {
            var aggregateMap = aggregates.ToDictionary(a => a.AccountId);
            var entries = new List<LeaderboardEntryDto>();

            foreach (var standing in snapshot.Standings.OrderBy(s => s.Rank))
            {
                if (!aggregateMap.TryGetValue(standing.AccountId, out var aggregate))
                {
                    continue;
                }

                var entry = CreateEntryDto(
                    aggregate,
                    standing.Rank,
                    period,
                    requestingAccountId,
                    snapshot.WeekStart,
                    snapshot.WeekEnd.AddTicks(1),
                    standing.StreakWeeks);

                entry.CashbackAwarded = standing.CashbackAwarded;
                entry.RewardSummary = standing.RewardSummary;
                entry.EngagementScore = standing.EngagementScore ?? aggregate.EngagementScore;

                entries.Add(entry);
            }

            entries = entries.OrderBy(e => e.Rank).ToList();
            RecomputePointGaps(entries);

            return new LeaderboardResponseDto
            {
                Period = period,
                RangeStart = rangeStart,
                RangeEnd = rangeEndExclusive,
                Headline = snapshot.HighlightHeadline ?? "Weekly champions locked in",
                Subheading = snapshot.HighlightSummary ?? "Last week's leaderboard is sealed and prizes have been paid out.",
                Entries = entries,
                PersonalEntry = entries.FirstOrDefault(e => e.IsRequester),
                MomentumTips = BuildMomentumTips(period, entries.FirstOrDefault(e => e.IsRequester))
            };
        }

        private async Task<LeaderboardResponseDto> BuildDynamicResponseAsync(
            List<LeaderboardComputationRow> aggregates,
            LeaderboardPeriod period,
            DateTime rangeStart,
            DateTime rangeEndExclusive,
            long? requestingAccountId,
            CancellationToken cancellationToken,
            bool applyPotentialCashback = false)
        {
            var entries = new List<LeaderboardEntryDto>();

            if (aggregates.Count == 0)
            {
                return new LeaderboardResponseDto
                {
                    Period = period,
                    RangeStart = rangeStart,
                    RangeEnd = rangeEndExclusive,
                    Headline = period == LeaderboardPeriod.ThisWeek
                        ? "Be the first to grab the weekly crown"
                        : "Start collecting rewards to climb the hall of fame",
                    Subheading = "Engage with the app to earn reward points and unlock cashback prizes.",
                    Entries = entries,
                    PersonalEntry = null,
                    MomentumTips = BuildMomentumTips(period, null)
                };
            }

            var streaks = await GetStreakWeeksAsync(aggregates.Select(a => a.AccountId).ToList(), cancellationToken);

            var ordered = aggregates
                .OrderByDescending(a => a.Points)
                .ThenByDescending(a => a.TotalRewards)
                .ThenBy(a => a.LastRewardAt ?? DateTime.MinValue)
                .Select((row, index) =>
                    CreateEntryDto(
                        row,
                        index + 1,
                        period,
                        requestingAccountId,
                        rangeStart,
                        rangeEndExclusive,
                        streaks.TryGetValue(row.AccountId, out var streak) ? streak : 0))
                .ToList();

            if (applyPotentialCashback)
            {
                for (var i = 0; i < ordered.Count && i < CashbackPrizes.Length; i++)
                {
                    ordered[i].PotentialCashback = CashbackPrizes[i];
                }
            }

            RecomputePointGaps(ordered);

            return new LeaderboardResponseDto
            {
                Period = period,
                RangeStart = rangeStart,
                RangeEnd = rangeEndExclusive,
                Headline = period switch
                {
                    LeaderboardPeriod.ThisWeek => $"Weekly prize pool: {CashbackPrizes.Sum():0} EGP up for grabs",
                    LeaderboardPeriod.AllTime => "Legends of Property Flipper",
                    _ => "Leaderboard"
                },
                Subheading = period switch
                {
                    LeaderboardPeriod.ThisWeek => "Finish the week in the top 3 to unlock instant cashback rewards.",
                    LeaderboardPeriod.AllTime => "Lifetime performance based on every reward you’ve ever earned.",
                    _ => "Leaderboard overview"
                },
                Entries = ordered,
                PersonalEntry = ordered.FirstOrDefault(e => e.IsRequester),
                MomentumTips = BuildMomentumTips(period, ordered.FirstOrDefault(e => e.IsRequester))
            };
        }

        private static void PopulateSnapshotStandings(WeeklyLeaderboardSnapshot snapshot, List<LeaderboardComputationRow> aggregates)
        {
            if (aggregates.Count == 0)
            {
                return;
            }

            var streaks = new Dictionary<long, int>();
            var rank = 1;

            foreach (var aggregate in aggregates)
            {
                var standing = new LeaderboardStanding
                {
                    AccountId = aggregate.AccountId,
                    Period = LeaderboardPeriod.LastWeek,
                    Rank = rank,
                    Points = aggregate.Points,
                    CashbackAwarded = rank <= CashbackPrizes.Length ? CashbackPrizes[rank - 1] : 0m,
                    EngagementScore = aggregate.EngagementScore,
                    StreakWeeks = streaks.TryGetValue(aggregate.AccountId, out var streak) ? streak : 0,
                    RewardSummary = rank <= CashbackPrizes.Length
                        ? $"{PrizeLabels[rank - 1]} payday locked"
                        : null,
                    ComputedAt = DateTime.UtcNow
                };

                snapshot.Standings.Add(standing);

                if (rank == 1)
                {
                    snapshot.WinnerAccountId = aggregate.AccountId;
                    snapshot.WinnerPoints = aggregate.Points;
                }
                else if (rank == 2)
                {
                    snapshot.SecondPlaceAccountId = aggregate.AccountId;
                    snapshot.SecondPlacePoints = aggregate.Points;
                }
                else if (rank == 3)
                {
                    snapshot.ThirdPlaceAccountId = aggregate.AccountId;
                    snapshot.ThirdPlacePoints = aggregate.Points;
                }

                rank++;
            }
        }

        private LeaderboardEntryDto CreateEntryDto(
            LeaderboardComputationRow row,
            int rank,
            LeaderboardPeriod period,
            long? requestingAccountId,
            DateTime rangeStart,
            DateTime rangeEndExclusive,
            int streakWeeks)
        {
            return new LeaderboardEntryDto
            {
                AccountId = row.AccountId,
                DisplayName = row.DisplayName,
                AvatarInitials = row.AvatarInitials,
                Rank = rank,
                Points = row.Points,
                TotalRewards = row.TotalRewards,
                CashbackAwarded = 0m,
                PotentialCashback = 0m,
                EngagementScore = Math.Round(row.EngagementScore, 2),
                StreakWeeks = streakWeeks,
                RewardSummary = null,
                IsRequester = requestingAccountId.HasValue && requestingAccountId.Value == row.AccountId,
                LastRewardAt = row.LastRewardAt,
                Activity = row.ActivitySlices,
                RewardTypeCounts = row.RewardTypeCounts
            };
        }

        private async Task<List<LeaderboardComputationRow>> BuildAggregatedRowsAsync(
            DateTime rangeStart,
            DateTime rangeEndExclusive,
            CancellationToken cancellationToken,
            List<long>? focusAccounts = null)
        {
            var rewardsQuery = _context.UserRewards
                .AsNoTracking()
                .Where(r => r.EarnedAt >= rangeStart && r.EarnedAt < rangeEndExclusive);

            if (focusAccounts != null && focusAccounts.Count > 0)
            {
                rewardsQuery = rewardsQuery.Where(r => focusAccounts.Contains(r.AccountId));
            }

            var aggregatedHeads = await rewardsQuery
                .GroupBy(r => r.AccountId)
                .Select(g => new LeaderboardHead
                {
                    AccountId = g.Key,
                    Points = g.Sum(r => r.Points),
                    RewardCount = g.Count(),
                    LastRewardAt = g.Max(r => (DateTime?)r.EarnedAt)
                })
                .OrderByDescending(h => h.Points)
                .ThenByDescending(h => h.RewardCount)
                .Take(100)
                .ToListAsync(cancellationToken);

            if (aggregatedHeads.Count == 0)
            {
                return new List<LeaderboardComputationRow>();
            }

            var accountIds = aggregatedHeads.Select(h => h.AccountId).ToList();

            var rewardDetails = await rewardsQuery
                .Where(r => accountIds.Contains(r.AccountId))
                .Select(r => new RewardSlice
                {
                    AccountId = r.AccountId,
                    RewardType = r.RewardType,
                    Points = r.Points,
                    EarnedAt = r.EarnedAt
                })
                .ToListAsync(cancellationToken);

            var accounts = await _context.Accounts
                .AsNoTracking()
                .Where(a => accountIds.Contains(a.AccountId))
                .Select(a => new
                {
                    a.AccountId,
                    a.FirstName,
                    a.LastName,
                    a.Email
                })
                .ToDictionaryAsync(a => a.AccountId, cancellationToken);

            var rows = new List<LeaderboardComputationRow>();

            foreach (var head in aggregatedHeads)
            {
                if (!accounts.TryGetValue(head.AccountId, out var account))
                {
                    continue;
                }

                var displayName = BuildDisplayName(account.FirstName, account.LastName, account.Email);
                var initials = BuildInitials(account.FirstName, account.LastName, account.Email);
                var slices = rewardDetails.Where(r => r.AccountId == head.AccountId).ToList();

                var categorySlices = BuildActivitySlices(slices);
                var rewardTypeCounts = BuildRewardTypeCounts(slices);
                var engagementScore = ComputeEngagementScore(head.Points, head.RewardCount, categorySlices);

                rows.Add(new LeaderboardComputationRow(
                    head.AccountId,
                    displayName,
                    initials,
                    head.Points,
                    head.RewardCount,
                    head.LastRewardAt,
                    categorySlices,
                    rewardTypeCounts,
                    engagementScore));
            }

            return rows;
        }

        private static void RecomputePointGaps(List<LeaderboardEntryDto> entries)
        {
            for (var i = 0; i < entries.Count; i++)
            {
                if (i == 0)
                {
                    entries[i].PointsToNextRank = null;
                    continue;
                }

                var above = entries[i - 1];
                entries[i].PointsToNextRank = Math.Max(0, above.Points - entries[i].Points + 1);
            }
        }

        private async Task<Dictionary<long, int>> GetStreakWeeksAsync(
            List<long> accountIds,
            CancellationToken cancellationToken)
        {
            if (accountIds.Count == 0)
            {
                return new Dictionary<long, int>();
            }

            var standings = await _context.LeaderboardStandings
                .AsNoTracking()
                .Where(ls => ls.Period == LeaderboardPeriod.LastWeek && ls.SnapshotId != null && accountIds.Contains(ls.AccountId))
                .Select(ls => new
                {
                    ls.AccountId,
                    ls.Rank,
                    WeekStart = ls.Snapshot!.WeekStart
                })
                .OrderByDescending(ls => ls.WeekStart)
                .ToListAsync(cancellationToken);

            var streaks = new Dictionary<long, int>();

            foreach (var accountId in accountIds)
            {
                var streak = 0;
                DateTime? previousWeek = null;

                foreach (var entry in standings.Where(s => s.AccountId == accountId))
                {
                    if (previousWeek == null)
                    {
                        streak++;
                        previousWeek = entry.WeekStart;
                        continue;
                    }

                    if (previousWeek.Value.AddDays(-7) == entry.WeekStart)
                    {
                        streak++;
                        previousWeek = entry.WeekStart;
                    }
                    else
                    {
                        break;
                    }
                }

                if (streak > 0)
                {
                    streaks[accountId] = streak;
                }
            }

            return streaks;
        }

        private static string BuildDisplayName(string? firstName, string? lastName, string? email)
        {
            if (!string.IsNullOrWhiteSpace(firstName) || !string.IsNullOrWhiteSpace(lastName))
            {
                return $"{firstName?.Trim()} {lastName?.Trim()}".Trim();
            }

            return email ?? "Community member";
        }

        private static string BuildInitials(string? firstName, string? lastName, string? email)
        {
            var initials = string.Empty;

            if (!string.IsNullOrWhiteSpace(firstName))
            {
                initials += char.ToUpperInvariant(firstName.Trim()[0]);
            }

            if (!string.IsNullOrWhiteSpace(lastName))
            {
                initials += char.ToUpperInvariant(lastName.Trim()[0]);
            }

            if (initials.Length == 0 && !string.IsNullOrWhiteSpace(email))
            {
                initials = char.ToUpperInvariant(email[0]).ToString();
            }

            return initials;
        }

        private static List<LeaderboardActivitySliceDto> BuildActivitySlices(IEnumerable<RewardSlice> rewards)
        {
            var slices = new Dictionary<string, LeaderboardActivitySliceDto>(StringComparer.OrdinalIgnoreCase);

            foreach (var reward in rewards)
            {
                var category = RewardTypeCategories.TryGetValue(reward.RewardType, out var mapped)
                    ? mapped
                    : "Bonus Boosts";

                if (!slices.TryGetValue(category, out var slice))
                {
                    slice = new LeaderboardActivitySliceDto
                    {
                        Category = category,
                        Count = 0,
                        Points = 0
                    };
                    slices[category] = slice;
                }

                slice.Count += 1;
                slice.Points += reward.Points;
            }

            return slices.Values
                .OrderByDescending(s => s.Points)
                .ThenByDescending(s => s.Count)
                .ToList();
        }

        private static Dictionary<string, int> BuildRewardTypeCounts(IEnumerable<RewardSlice> rewards)
        {
            var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (var reward in rewards)
            {
                counts.TryGetValue(reward.RewardType, out var value);
                counts[reward.RewardType] = value + 1;
            }
            return counts;
        }

        private static double ComputeEngagementScore(int points, int rewardCount, List<LeaderboardActivitySliceDto> slices)
        {
            var uniqueCategories = slices.Count;
            var activityBonus = rewardCount * 5;
            var diversityBonus = uniqueCategories * 30;
            var biddingBoost = slices
                .Where(s => s.Category.Equals("Bidding Blitz", StringComparison.OrdinalIgnoreCase))
                .Sum(s => s.Count) * 10;

            return points + activityBonus + diversityBonus + biddingBoost;
        }

        private static string BuildHeadline(List<LeaderboardComputationRow> aggregates)
        {
            if (aggregates.Count == 0)
            {
                return "Weekly leaderboard awaiting contenders";
            }

            var top = aggregates.First();
            return $"{top.DisplayName} captured the weekly crown";
        }

        private static string BuildSummary(List<LeaderboardComputationRow> aggregates)
        {
            if (aggregates.Count == 0)
            {
                return "No activity was recorded for this week.";
            }

            var top = aggregates.First();
            var bids = top.ActivitySlices.FirstOrDefault(s => s.Category == "Bidding Blitz")?.Count ?? 0;
            var referrals = top.ActivitySlices.FirstOrDefault(s => s.Category == "Referral Rocket")?.Count ?? 0;
            return $"{top.DisplayName} stacked {top.Points} pts with {bids} bids and {referrals} referral boosts.";
        }

        private static List<string> BuildMomentumTips(LeaderboardPeriod period, LeaderboardEntryDto? personalEntry)
        {
            var tips = new List<string>
            {
                "Earn reward points by bidding, referring friends, and closing deals.",
                "Top 3 each week unlock instant cashback — stay active daily."
            };

            if (personalEntry == null)
            {
                tips.Add("Connect your portfolio and start earning points to appear on the leaderboard.");
                return tips;
            }

            if (personalEntry.PointsToNextRank.HasValue && personalEntry.PointsToNextRank.Value > 0)
            {
                tips.Add($"Only {personalEntry.PointsToNextRank.Value} pts to reach rank #{personalEntry.Rank - 1}. Join a live auction or refer a buyer to close the gap.");
            }

            if (personalEntry.Activity.All(a => a.Category != "Referral Rocket"))
            {
                tips.Add("Send referral invites — successful referrals deliver massive point boosts.");
            }

            if (period == LeaderboardPeriod.ThisWeek && personalEntry.Rank > 3)
            {
                tips.Add("Focus on high-value actions today to break into the top 3 and secure cashback.");
            }

            return tips;
        }

        private static List<string> BuildActionPrompts(LeaderboardEntryDto? personalEntry)
        {
            var prompts = new List<string>
            {
                "Join a live auction and place competitive bids.",
                "Invite friends to the platform — referrals deliver bonus points.",
                "Track your portfolio for valuation insights and bonus rewards."
            };

            if (personalEntry == null)
            {
                return prompts;
            }

            if (personalEntry.PointsToNextRank.HasValue && personalEntry.PointsToNextRank.Value <= 50)
            {
                prompts.Insert(0, $"You are {personalEntry.PointsToNextRank.Value} pts away from a higher tier — complete a valuation or referral today.");
            }

            return prompts;
        }

        private static (DateTime Start, DateTime End) GetDateRange(LeaderboardPeriod period, DateTime referenceUtc)
        {
            var referenceDate = referenceUtc.Date;
            var offset = (7 + (referenceDate.DayOfWeek - DayOfWeek.Monday)) % 7;
            var startOfWeek = referenceDate.AddDays(-offset);

            return period switch
            {
                LeaderboardPeriod.ThisWeek => (startOfWeek, startOfWeek.AddDays(7)),
                LeaderboardPeriod.LastWeek => (startOfWeek.AddDays(-7), startOfWeek),
                LeaderboardPeriod.AllTime => (DateTime.MinValue, referenceUtc.AddSeconds(1)),
                _ => (startOfWeek, startOfWeek.AddDays(7))
            };
        }

        private sealed record LeaderboardHead
        {
            public long AccountId { get; init; }
            public int Points { get; init; }
            public int RewardCount { get; init; }
            public DateTime? LastRewardAt { get; init; }
        }

        private sealed record RewardSlice
        {
            public long AccountId { get; init; }
            public string RewardType { get; init; } = string.Empty;
            public int Points { get; init; }
            public DateTime EarnedAt { get; init; }
        }

        private sealed record LeaderboardComputationRow(
            long AccountId,
            string DisplayName,
            string AvatarInitials,
            int Points,
            int TotalRewards,
            DateTime? LastRewardAt,
            List<LeaderboardActivitySliceDto> ActivitySlices,
            Dictionary<string, int> RewardTypeCounts,
            double EngagementScore);
    }
}


