using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Services;
using PropertyFlipperAPI.Models.Feed;
using System.Security.Claims;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FeedController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly ILogger<FeedController> _logger;

        public FeedController(AppDbContext context, IMemoryCache cache, ILogger<FeedController> logger)
        {
            _context = context;
            _cache = cache;
            _logger = logger;
        }

        protected long? GetCurrentAccountId()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim != null && long.TryParse(userIdClaim.Value, out long userId))
            {
                return userId;
            }
            return null;
        }

        // GET: api/feed/explore?page=1&pageSize=20
        [HttpGet("explore")]
        public async Task<ActionResult<FeedResponseDto>> GetExploreFeed(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] long? userId = null)
        {
            userId ??= GetCurrentAccountId();

            try
            {
                // Check cache first
                var cacheKey = $"feed_explore_p{page}_u{userId}";
                if (_cache.TryGetValue(cacheKey, out FeedResponseDto? cached))
                {
                    _logger.LogInformation("Serving cached feed for page {Page} user {UserId}", page, userId);
                    return Ok(cached);
                }

                // Fetch all available content
                var allPosts = await GetAllPosts(userId);
                var allAuctions = await GetAllAuctions();
                var allLiveStreams = await GetActiveLiveStreams();
                var allNews = await GetAllNews();
                var allProjects = await GetAllProjects();
                var allDevelopers = await GetAllDevelopers();
                var dealHighlights = await GetDealHighlights();
                var projectStories = await GetProjectStories();
                var investorMilestones = await GetInvestorMilestones();
                var valuationPrompts = await GetValuationPrompts(userId);
                var paymentReminders = await GetPaymentReminders(userId);

                // Create weighted pool with time-based boosting
                var contentPool = new List<FeedItemDto>();
                var random = new Random(page * DateTime.Now.Millisecond + (int)(userId ?? 0));
                
                // Time-based boost multipliers (removed communityWeight)
                var (postWeight, auctionWeight, livestreamWeight, newsWeight, projectWeight) = GetTimeBasedWeights();

                // Add posts (40% weight = 8 copies per post, boosted by time)
                foreach (var post in allPosts)
                {
                    var copies = (int)(8 * postWeight);
                    for (int i = 0; i < copies; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "post",
                            Data = post,
                            Id = $"post_{post.PostId}"
                        });
                    }
                }

                // Add auctions (15% weight = 3 copies per auction, boosted by time)
                foreach (var auction in allAuctions)
                {
                    var copies = (int)(3 * auctionWeight);
                    for (int i = 0; i < copies; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "auction",
                            Data = auction,
                            Id = $"auction_{auction.AuctionId}"
                        });
                    }
                }

                // Add live streams (10% weight = 2 copies per stream, boosted by time)
                foreach (var stream in allLiveStreams)
                {
                    var copies = (int)(2 * livestreamWeight);
                    for (int i = 0; i < copies; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "livestream",
                            Data = stream,
                            Id = $"livestream_{stream.StreamId}"
                        });
                    }
                }

                // Add news (10% weight = 2 copies, boosted by time)
                foreach (var article in allNews)
                {
                    var copies = (int)(2 * newsWeight);
                    for (int i = 0; i < copies; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "news",
                            Data = article,
                            Id = $"news_{article.NewsArticleId}"
                        });
                    }
                }

                // Add projects (8% weight = 2 copies, boosted by time)
                foreach (var project in allProjects)
                {
                    var copies = (int)(2 * projectWeight);
                    for (int i = 0; i < copies; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "project",
                            Data = project,
                            Id = $"project_{project.ProjectId}"
                        });
                    }
                }

                // Add developers (5% weight = 1 copy, no time boost)
                foreach (var developer in allDevelopers)
                {
                    contentPool.Add(new FeedItemDto
                    {
                        Type = "developer",
                        Data = developer,
                        Id = $"developer_{developer.DeveloperId}"
                    });
                }

                // Add deal highlights (premium curated entries)
                foreach (var highlight in dealHighlights)
                {
                    for (int i = 0; i < 4; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "deal_highlight",
                            Data = highlight,
                            Id = $"deal_highlight_{highlight.AuctionId}"
                        });
                    }
                }

                // Add project stories
                foreach (var story in projectStories)
                {
                    for (int i = 0; i < 3; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "project_story",
                            Data = story,
                            Id = $"project_story_{story.ProjectId}"
                        });
                    }
                }

                // Add investor milestones
                foreach (var milestone in investorMilestones)
                {
                    for (int i = 0; i < 2; i++)
                    {
                        contentPool.Add(new FeedItemDto
                        {
                            Type = "investor_milestone",
                            Data = milestone,
                            Id = $"investor_milestone_{milestone.AchievementId}"
                        });
                    }
                }

                // Add valuation prompts (7% weight = 1 copy per prompt)
                foreach (var prompt in valuationPrompts)
                {
                    contentPool.Add(new FeedItemDto
                    {
                        Type = "valuationPrompt",
                        Data = prompt,
                        Id = $"valuationPrompt_{prompt.PropertyId ?? 0}_{userId ?? 0}"
                    });
                }

                // Add payment reminders (5% weight = 1 copy per reminder)
                foreach (var reminder in paymentReminders)
                {
                    contentPool.Add(new FeedItemDto
                    {
                        Type = "paymentReminder",
                        Data = reminder,
                        Id = $"paymentReminder_{reminder.EventId}"
                    });
                }

                // Shuffle entire pool
                contentPool = contentPool.OrderBy(x => random.Next()).ToList();

                // Paginate: skip to page, take items
                var skip = (page - 1) * pageSize;
                var feedItems = contentPool.Skip(skip).Take(pageSize).ToList();

                // Deduplicate to remove same item appearing twice
                var seenIds = new HashSet<string>();
                feedItems = feedItems
                    .Where(item =>
                    {
                        if (seenIds.Contains(item.Id))
                        {
                            return false;
                        }
                        seenIds.Add(item.Id);
                        return true;
                    })
                    .ToList();

                // Apply boost rules (ending soon auctions, trending posts, etc.)
                feedItems = ApplyBoostRules(feedItems, allAuctions, random);

                // Add variable rewards - randomly vary distribution
                if (random.Next(100) < 20) // 20% chance of burst
                {
                    feedItems = AddContentBurst(feedItems, allAuctions, allPosts, random);
                }

                // Inject urgency items (ending soon auctions, breaking news)
                feedItems = InjectUrgencyItems(feedItems, allAuctions, allNews, random);

                // Track analytics
                TrackFeedAnalytics(userId, page, feedItems.Count);

                var response = new FeedResponseDto
                {
                    Items = feedItems,
                    Page = page,
                    HasMore = contentPool.Count > (skip + pageSize) && feedItems.Count >= pageSize
                };

                // Cache for 60 seconds
                _cache.Set(cacheKey, response, TimeSpan.FromSeconds(60));

                _logger.LogInformation("Generated feed page {Page} with {Count} items at {Hour}h", 
                    page, feedItems.Count, DateTime.Now.Hour);

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating explore feed");
                return StatusCode(500, new { error = "Failed to generate feed" });
            }
        }

        private async Task<List<DealHighlightDto>> GetDealHighlights()
        {
            var auctions = await _context.Auctions
                .AsNoTracking()
                .Include(a => a.Property)
                    .ThenInclude(p => p.PropertyImages)
                .Where(a => a.Status == "Approved" || a.Status == "Active" || a.Status == "Ended")
                .OrderByDescending(a => a.CreatedAt)
                .Take(30)
                .ToListAsync();

            if (!auctions.Any())
            {
                return new List<DealHighlightDto>();
            }

            var now = DateTime.UtcNow;
            var highlights = new List<DealHighlightDto>();

            foreach (var auction in auctions)
            {
                if (auction.Property == null)
                {
                    continue;
                }

                var endAt = auction.StartAt.AddHours(auction.Duration);
                var startPrice = auction.StartPrice <= 0 ? 1 : auction.StartPrice;
                var gain = auction.CurrentPrice - auction.StartPrice;
                var roi = (double)(gain / startPrice);

                var primaryImage = auction.Property.PropertyImages?
                    .OrderByDescending(img => img.IsMainImage)
                    .ThenBy(img => img.DisplayOrder)
                    .Select(img => img.ImageUrl)
                    .FirstOrDefault();

                if (string.IsNullOrWhiteSpace(primaryImage))
                {
                    primaryImage = auction.Property.ImageUrl;
                }

                highlights.Add(new DealHighlightDto
                {
                    AuctionId = auction.AuctionId,
                    PropertyId = auction.PropertyId,
                    PropertyName = auction.Property?.Name ?? $"Property #{auction.PropertyId}",
                    Location = auction.Property?.Location,
                    ImageUrl = primaryImage,
                    StartPrice = auction.StartPrice,
                    CurrentPrice = auction.CurrentPrice,
                    RoiPercentage = Math.Round(roi * 100, 2),
                    EndAt = endAt,
                    BidCount = auction.BidCount,
                    IsEndingSoon = endAt <= now.AddHours(4) && endAt > now
                });
            }

            return highlights
                .OrderByDescending(h => h.RoiPercentage)
                .ThenBy(h => h.EndAt)
                .Take(8)
                .ToList();
        }

        private async Task<List<ProjectStoryDto>> GetProjectStories()
        {
            var projects = await _context.Projects
                .AsNoTracking()
                .Where(p => p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .Take(20)
                .ToListAsync();

            if (!projects.Any())
            {
                return new List<ProjectStoryDto>();
            }

            var projectIds = projects.Select(p => p.ProjectId).ToList();

            var propertyStats = await _context.ChildProperties
                .AsNoTracking()
                .Where(cp => cp.ProjectId != null && projectIds.Contains(cp.ProjectId.Value))
                .GroupBy(cp => cp.ProjectId!.Value)
                .Select(g => new
                {
                    ProjectId = g.Key,
                    PropertyCount = g.Count()
                })
                .ToListAsync();

            var auctionStats = await _context.Auctions
                .AsNoTracking()
                .Join(
                    _context.ChildProperties.AsNoTracking(),
                    auction => auction.PropertyId,
                    property => property.PropertyId,
                    (auction, property) => new { auction, property })
                .Where(x => x.property.ProjectId != null && projectIds.Contains(x.property.ProjectId.Value))
                .Select(x => new
                {
                    ProjectId = x.property.ProjectId!.Value,
                    x.auction.StartPrice,
                    x.auction.CurrentPrice,
                    x.auction.Status
                })
                .ToListAsync();

            var milestoneData = await _context.ProjectMilestones
                .AsNoTracking()
                .Where(m => projectIds.Contains(m.ProjectId))
                .ToListAsync();

            var stories = new List<ProjectStoryDto>();

            foreach (var project in projects)
            {
                var milestones = milestoneData.Where(m => m.ProjectId == project.ProjectId).ToList();
                var auctionsForProject = auctionStats.Where(a => a.ProjectId == project.ProjectId).ToList();

                var activeAuctionCount = auctionsForProject.Count(a => a.Status == "Approved" || a.Status == "Active");

                var roiSamples = auctionsForProject
                    .Where(a => a.StartPrice != 0)
                    .Select(a => (double)((a.CurrentPrice - a.StartPrice) / (a.StartPrice == 0 ? 1 : a.StartPrice)))
                    .ToList();

                var averageRoi = roiSamples.Any() ? Math.Round(roiSamples.Average() * 100, 2) : 0;

                var latestMilestone = milestones
                    .OrderByDescending(m => m.TargetDate)
                    .Select(m => new ProjectStoryMilestoneDto
                    {
                        Title = m.Title,
                        TargetDate = m.TargetDate,
                        CompletedDate = m.CompletedDate
                    })
                    .FirstOrDefault();

                var projectPropertyStats = propertyStats.FirstOrDefault(s => s.ProjectId == project.ProjectId);

                stories.Add(new ProjectStoryDto
                {
                    ProjectId = project.ProjectId,
                    Name = project.Name,
                    Location = project.Location,
                    CreatedAt = project.CreatedAt,
                    PropertyCount = projectPropertyStats?.PropertyCount ?? 0,
                    ActiveAuctionCount = activeAuctionCount,
                    CompletedMilestones = milestones.Count(m => m.Status == MilestoneStatus.Completed),
                    UpcomingMilestones = milestones.Count(m => m.Status != MilestoneStatus.Completed),
                    AverageRoi = averageRoi,
                    LatestMilestone = latestMilestone
                });
            }

            return stories
                .OrderByDescending(s => s.ActiveAuctionCount)
                .ThenByDescending(s => s.PropertyCount)
                .Take(10)
                .ToList();
        }

        private async Task<List<InvestorMilestoneDto>> GetInvestorMilestones()
        {
            var achievements = await _context.UserAchievements
                .AsNoTracking()
                .Include(a => a.Account)
                .OrderByDescending(a => a.EarnedAt)
                .Take(30)
                .ToListAsync();

            if (!achievements.Any())
            {
                return new List<InvestorMilestoneDto>();
            }

            var accountIds = achievements.Select(a => a.AccountId).Distinct().ToList();

            var portfolioStats = await _context.ChildProperties
                .AsNoTracking()
                .Where(cp => cp.OwnerId != null && accountIds.Contains(cp.OwnerId.Value))
                .GroupBy(cp => cp.OwnerId!.Value)
                .Select(g => new
                {
                    AccountId = g.Key,
                    PropertyCount = g.Count(),
                    TotalBuyIn = g.Sum(cp => cp.BuyingPrice ?? 0)
                })
                .ToListAsync();

            var reputationLookup = await _context.Accounts
                .AsNoTracking()
                .Where(a => accountIds.Contains(a.AccountId))
                .Select(a => new { a.AccountId, a.ReputationPoints })
                .ToListAsync();

            var reputationMap = reputationLookup.ToDictionary(r => r.AccountId, r => r.ReputationPoints);

            var milestones = new List<InvestorMilestoneDto>();

            foreach (var achievement in achievements)
            {
                var name = $"{achievement.Account.FirstName} {achievement.Account.LastName}".Trim();
                var initialsSource = string.IsNullOrWhiteSpace(name)
                    ? achievement.Account.Email
                    : name;

                string initials = string.Empty;
                if (!string.IsNullOrWhiteSpace(initialsSource))
                {
                    var parts = initialsSource
                        .Split(' ', StringSplitOptions.RemoveEmptyEntries)
                        .Select(p => p[0]);
                    initials = string.Concat(parts).ToUpperInvariant();
                    if (initials.Length > 2)
                    {
                        initials = initials.Substring(0, 2);
                    }
                }

                var portfolio = portfolioStats.FirstOrDefault(p => p.AccountId == achievement.AccountId);

                milestones.Add(new InvestorMilestoneDto
                {
                    AchievementId = achievement.AchievementId,
                    AccountId = achievement.AccountId,
                    InvestorName = string.IsNullOrWhiteSpace(name) ? achievement.Account.Email : name,
                    Title = achievement.Title,
                    Description = achievement.Description,
                    EarnedAt = achievement.EarnedAt,
                    PointsAwarded = achievement.PointsAwarded,
                    PortfolioCount = portfolio?.PropertyCount ?? 0,
                    TotalBuyInValue = portfolio?.TotalBuyIn ?? 0,
                    ReputationPoints = reputationMap.TryGetValue(achievement.AccountId, out var rep) ? rep : 0,
                    Initials = initials
                });
            }

            return milestones
                .OrderByDescending(m => m.PointsAwarded)
                .ThenByDescending(m => m.EarnedAt)
                .Take(10)
                .ToList();
        }

        private async Task<List<CommunityPost>> GetAllPosts(long? userId)
        {
            var query = _context.CommunityPosts
                .Include(p => p.Author)
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .AsQueryable();

            // Get recent posts (last 30 days)
            var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
            query = query.Where(p => p.CreatedAt >= thirtyDaysAgo);

            // Boost trending posts (created in last 6 hours with high engagement)
            var sixHoursAgo = DateTime.UtcNow.AddHours(-6);
            var trendingPosts = await query
                .Where(p => p.CreatedAt >= sixHoursAgo)
                .Where(p => p.LikeCount > 20 || p.CommentCount > 10)
                .OrderByDescending(p => p.LikeCount + p.CommentCount * 2)
                .Take(20)
                .ToListAsync();

            // Get regular high-engagement posts
            var regularPosts = await query
                .OrderByDescending(p => p.LikeCount + p.CommentCount * 2)
                .Take(80)
                .ToListAsync();

            // Combine trending + regular, trending appears more often
            var allPosts = trendingPosts.Concat(regularPosts).Distinct().ToList();
            
            return allPosts;
        }

        private async Task<List<Auction>> GetAllAuctions()
        {
            return await _context.Auctions
                .Include(a => a.Property)
                    .ThenInclude(p => p.PropertyImages)
                .Where(a => a.Status == "Approved" || a.Status == "Active" || a.Status == "Ended")
                .OrderByDescending(a => a.CreatedAt)
                .Take(50)
                .ToListAsync();
        }

        private async Task<List<LiveStreamDto>> GetActiveLiveStreams()
        {
            var streams = await _context.LiveStreams
                .Include(s => s.Developer)
                .Where(s => s.Status == "Live")
                .OrderByDescending(s => s.StartTime)
                .Take(20)
                .ToListAsync();

            return streams.Select(s => new LiveStreamDto
            {
                StreamId = s.StreamId,
                DeveloperId = s.DeveloperId,
                DeveloperName = $"{s.Developer?.FirstName} {s.Developer?.LastName}",
                DeveloperProfileImageUrl = null,
                Title = s.Title,
                Description = s.Description,
                StreamUrl = s.StreamUrl,
                ThumbnailUrl = s.ThumbnailUrl,
                Status = s.Status,
                ViewerCount = s.ViewerCount,
                StartTime = s.StartTime,
                EndTime = s.EndTime,
                CreatedAt = s.CreatedAt
            }).ToList();
        }

        private async Task<List<ValuationPromptDto>> GetValuationPrompts(long? userId)
        {
            if (!userId.HasValue)
            {
                // For non-logged-in users, return generic prompt
                return new List<ValuationPromptDto>
                {
                    new ValuationPromptDto
                    {
                        PropertyId = null,
                        PropertyName = null,
                        PropertyImageUrl = null,
                        IsGeneric = true
                    }
                };
            }

            // Get user's properties without recent valuations (last 30 days)
            var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
            var propertiesWithRecentValuations = await _context.PropertyValuations
                .Where(v => v.CalculatedAt >= thirtyDaysAgo)
                .Select(v => v.PropertyId)
                .ToListAsync();

            var properties = await _context.ChildProperties
                .Include(p => p.PropertyImages)
                .Where(p => p.OwnerId == userId.Value && p.IsApproved)
                .Where(p => !propertiesWithRecentValuations.Contains(p.PropertyId))
                .Take(5)
                .ToListAsync();

            return properties.Select(p => new ValuationPromptDto
            {
                PropertyId = p.PropertyId,
                PropertyName = p.Name,
                PropertyImageUrl = p.PropertyImages.FirstOrDefault()?.ImageUrl ?? (p.ImageUrl ?? null),
                IsGeneric = false
            }).ToList();
        }

        private async Task<List<PaymentReminderDto>> GetPaymentReminders(long? userId)
        {
            if (!userId.HasValue)
                return new List<PaymentReminderDto>();

            var now = DateTime.UtcNow;
            var sevenDaysFromNow = now.AddDays(7);

            var reminders = await _context.Events
                .Include(e => e.User)
                .Where(e => e.UserId == userId.Value)
                .Where(e => e.Type == EventType.Installment)
                .Where(e => e.EventDate >= now && e.EventDate <= sevenDaysFromNow)
                .Where(e => !e.IsCompleted)
                .OrderBy(e => e.EventDate)
                .Take(5)
                .ToListAsync();

            var reminderDtos = new List<PaymentReminderDto>();
            foreach (var e in reminders)
            {
                string? propertyName = null;
                if (e.PropertyId.HasValue)
                {
                    var property = await _context.ChildProperties
                        .Where(p => p.PropertyId == (int)e.PropertyId.Value)
                        .Select(p => p.Name)
                        .FirstOrDefaultAsync();
                    propertyName = property;
                }

                reminderDtos.Add(new PaymentReminderDto
                {
                    EventId = e.EventId,
                    PropertyId = e.PropertyId.HasValue ? (int)e.PropertyId.Value : null,
                    PropertyName = propertyName,
                    Amount = e.Amount,
                    EventDate = e.EventDate,
                    DaysUntilDue = (int)(e.EventDate - now).TotalDays,
                    IsReminderSet = e.IsReminderSet
                });
            }

            return reminderDtos;
        }

        private async Task<List<NewsArticle>> GetAllNews()
        {
            // Get actual news articles from the database
            return await _context.NewsArticles
                .Include(n => n.Images)
                .Where(n => n.IsPublished)
                .OrderByDescending(n => n.PublishedDate)
                .Take(20)
                .ToListAsync();
        }

        private async Task<List<Project>> GetAllProjects()
        {
            return await _context.Projects
                .Include(p => p.Developer)
                .OrderByDescending(p => p.CreatedAt)
                .Take(20)
                .ToListAsync();
        }

        private async Task<List<FeaturedDeveloper>> GetAllDevelopers()
        {
            return await _context.DeveloperProfiles
                .Include(d => d.Account)
                .OrderByDescending(d => d.Rating)
                .Take(10)
                .Select(d => new FeaturedDeveloper
                {
                    DeveloperId = d.ProfileId,
                    FirstName = d.Account.FirstName,
                    LastName = d.Account.LastName,
                    CompanyName = d.CompanyName,
                    ProfileImageUrl = d.ProfileImageUrl,
                    Rating = (double)d.Rating
                })
                .ToListAsync();
        }

        private List<FeedItemDto> ApplyBoostRules(List<FeedItemDto> items, List<Auction> auctions, Random random)
        {
            // Boost ending soon auctions
            foreach (var item in items.Where(x => x.Type == "auction").ToList())
            {
                var auction = item.Data as Auction;
                if (auction != null)
                {
                    var endAt = auction.StartAt.AddHours(auction.Duration);
                    if (endAt <= DateTime.UtcNow.AddHours(2))
                    {
                        items.Remove(item);
                        items.Insert(random.Next(0, Math.Min(3, items.Count)), item);
                    }
                }
            }

            return items;
        }

        private List<FeedItemDto> AddContentBurst(List<FeedItemDto> items, List<Auction> auctions, List<CommunityPost> posts, Random random)
        {
            // Occasionally add a burst of auctions (5 in a row)
            if (random.Next(100) < 20) // 20% chance
            {
                var auctionBurst = auctions
                    .OrderBy(x => random.Next())
                    .Take(5)
                    .Select(a => new FeedItemDto
                    {
                        Type = "auction",
                        Data = a,
                        Id = $"auction_{a.AuctionId}"
                    })
                    .ToList();

                if (auctionBurst.Any() && items.Count > 5)
                {
                    var insertPosition = random.Next(5, Math.Min(10, items.Count));
                    items.InsertRange(insertPosition, auctionBurst);
                }
            }

            return items;
        }

        // Time-based boosting: Different content for different times of day
        private (double post, double auction, double livestream, double news, double project) GetTimeBasedWeights()
        {
            var hour = DateTime.Now.Hour;
            
            // Morning (6am-12pm): Boost news and projects (productivity time)
            if (hour >= 6 && hour < 12)
            {
                return (1.0, 0.8, 1.0, 1.5, 1.5);
            }
            // Afternoon (12pm-6pm): Boost auctions and livestreams (shopping/engagement time)
            else if (hour >= 12 && hour < 18)
            {
                return (1.2, 1.8, 1.5, 1.0, 1.0);
            }
            // Evening (6pm-12am): Boost posts and livestreams (engagement time)
            else if (hour >= 18 && hour < 24)
            {
                return (1.5, 1.2, 1.8, 0.8, 0.8);
            }
            // Night (12am-6am): Boost everything slightly, varied content
            else
            {
                return (1.2, 1.2, 1.3, 1.2, 1.2);
            }
        }

        // Variable reward system: Randomize item counts per page
        private int GetRandomItemCount(int baseCount, Random random)
        {
            // Sometimes give more, sometimes less (±50% variance)
            var variance = random.Next(-baseCount / 2, baseCount / 2);
            return Math.Max(1, baseCount + variance);
        }

        // Urgency injection: Add high-value items at key positions
        private List<FeedItemDto> InjectUrgencyItems(List<FeedItemDto> items, List<Auction> auctions, List<NewsArticle> news, Random random)
        {
            // Every 5th position, potentially inject an urgent item
            for (int i = 4; i < items.Count; i += 5)
            {
                if (random.Next(100) < 30) // 30% chance at each position
                {
                    var urgentItem = GetUrgentItem(auctions, news, random);
                    if (urgentItem != null)
                    {
                        items.Insert(i, urgentItem);
                    }
                }
            }
            return items;
        }

        private FeedItemDto? GetUrgentItem(List<Auction> auctions, List<NewsArticle> news, Random random)
        {
            // Try to get an ending soon auction
            var endingSoon = auctions
                .Where(a =>
                {
                    var endAt = a.StartAt.AddHours(a.Duration);
                    return endAt <= DateTime.UtcNow.AddHours(1) && endAt >= DateTime.UtcNow;
                })
                .OrderBy(x => random.Next())
                .FirstOrDefault();
                
            if (endingSoon != null)
            {
                return new FeedItemDto
                {
                    Type = "auction",
                    Data = endingSoon,
                    Id = $"auction_urgent_{endingSoon.AuctionId}"
                };
            }
            
            // Try breaking news
            var breaking = news
                .Where(n => n.PublishedDate >= DateTime.UtcNow.AddHours(-2))
                .OrderBy(x => random.Next())
                .FirstOrDefault();
                
            if (breaking != null)
            {
                return new FeedItemDto
                {
                    Type = "news",
                    Data = breaking,
                    Id = $"news_urgent_{breaking.NewsArticleId}"
                };
            }
            
            return null;
        }

        // Analytics tracking
        private void TrackFeedAnalytics(long? userId, int page, int itemCount)
        {
            // This would integrate with your analytics service
            _logger.LogInformation(
                "Feed Analytics - User: {UserId}, Page: {Page}, Items: {Count}, Time: {Time}",
                userId ?? 0, page, itemCount, DateTime.Now.Hour
            );
        }
    }

    public class FeedResponseDto
    {
        public List<FeedItemDto> Items { get; set; } = new();
        public int Page { get; set; }
        public bool HasMore { get; set; }
    }

    public class FeedItemDto
    {
        public string Type { get; set; } = "";
        public object Data { get; set; } = new();
        public string Id { get; set; } = "";
    }

    public class FeaturedDeveloper
    {
        public long DeveloperId { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string CompanyName { get; set; } = "";
        public string? ProfileImageUrl { get; set; }
        public double Rating { get; set; }
    }

    public class ValuationPromptDto
    {
        public int? PropertyId { get; set; }
        public string? PropertyName { get; set; }
        public string? PropertyImageUrl { get; set; }
        public bool IsGeneric { get; set; }
    }

    public class PaymentReminderDto
    {
        public long EventId { get; set; }
        public int? PropertyId { get; set; }
        public string? PropertyName { get; set; }
        public decimal? Amount { get; set; }
        public DateTime EventDate { get; set; }
        public int DaysUntilDue { get; set; }
        public bool IsReminderSet { get; set; }
    }
}
