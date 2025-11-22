using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DiscoveryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DiscoveryController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/discovery/trending/posts
        [HttpGet("trending/posts")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<object>>> GetTrendingPosts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var accountId = GetCurrentAccountId();

            // Recalculate trending scores for all posts (in production, do this periodically)
            // Note: Removed Include(p => p.Author) to avoid Type column reference
            var posts = await _context.CommunityPosts
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Community)
                .ToListAsync();

            foreach (var post in posts)
            {
                post.CalculateTrendingScore();
            }

            await _context.SaveChangesAsync();

            // Note: Removed Include(p => p.Author) to avoid Type column reference
            var trendingPosts = await _context.CommunityPosts
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Community)
                .Include(p => p.Poll)
                    .ThenInclude(poll => poll.Votes)
                .OrderByDescending(p => p.TrendingScore)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var result = trendingPosts.Select(p => new
            {
                postId = p.PostId,
                communityId = p.CommunityId,
                communityName = p.Community?.Name ?? "",
                communityCoverPhotoUrl = p.Community?.CoverPhotoUrl,
                authorId = p.AuthorId,
                authorName = p.Author != null ? $"{p.Author.FirstName} {p.Author.LastName}" : "",
                authorRoleId = p.Author?.RoleId ?? 0, // SECURITY: Non-guessable RoleId
                authorRoleName = p.Author != null && p.Author.Role != null ? p.Author.Role.RoleName : "Owner",
                content = p.Content,
                imageUrl = p.ImageUrl,
                postType = p.PostType.ToString(),
                isPinned = p.IsPinned,
                likeCount = p.LikeCount,
                commentCount = p.CommentCount,
                viewCount = p.ViewCount,
                trendingScore = p.TrendingScore,
                categories = p.Categories.Select(c => c.CategoryName).ToList(),
                createdAt = p.CreatedAt,
                isLiked = accountId.HasValue && p.Likes.Any(l => l.AccountId == accountId.Value)
            });

            return Ok(result);
        }

        // GET: api/discovery/trending/communities
        [HttpGet("trending/communities")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<object>>> GetTrendingCommunities()
        {
            var accountId = GetCurrentAccountId();

            var communities = await _context.Communities
                .Include(c => c.Members)
                .Where(c => c.IsActive)
                .ToListAsync();

            // Calculate trending score for communities (activity + growth)
            var communityIds = communities.Select(c => c.CommunityId).ToList();

            var communityPosts = await _context.CommunityPosts
                .Where(p => communityIds.Contains(p.CommunityId))
                .GroupBy(p => p.CommunityId)
                .Select(g => new
                {
                    CommunityId = g.Key,
                    PostCount = g.Count(),
                    RecentPostCount = g.Count(p => p.CreatedAt >= DateTime.UtcNow.AddDays(-7)),
                    TotalLikes = g.Sum(p => p.LikeCount)
                })
                .ToListAsync();

            var memberCounts = await _context.CommunityMembers
                .Where(m => communityIds.Contains(m.CommunityId))
                .GroupBy(m => m.CommunityId)
                .Select(g => new
                {
                    CommunityId = g.Key,
                    TotalMembers = g.Count(),
                    NewMembers = g.Count(m => m.JoinedAt >= DateTime.UtcNow.AddDays(-7))
                })
                .ToListAsync();

            var trendingCommunities = communities.Select(c =>
            {
                var postStats = communityPosts.FirstOrDefault(p => p.CommunityId == c.CommunityId);
                var memberStats = memberCounts.FirstOrDefault(m => m.CommunityId == c.CommunityId);

                var trendingScore = (postStats?.RecentPostCount ?? 0) * 2.0 +
                                   (postStats?.TotalLikes ?? 0) * 0.5 +
                                   (memberStats?.NewMembers ?? 0) * 3.0 +
                                   (postStats?.PostCount ?? 0) * 0.1;

                var isJoined = accountId.HasValue && c.Members.Any(m => m.AccountId == accountId.Value);

                return new
                {
                    communityId = c.CommunityId,
                    name = c.Name,
                    description = c.Description,
                    coverPhotoUrl = c.CoverPhotoUrl,
                    memberCount = memberStats?.TotalMembers ?? 0,
                    postCount = postStats?.PostCount ?? 0,
                    newMembersThisWeek = memberStats?.NewMembers ?? 0,
                    recentPostsThisWeek = postStats?.RecentPostCount ?? 0,
                    trendingScore = trendingScore,
                    createdAt = c.CreatedAt,
                    isJoined = isJoined,
                    canJoin = !isJoined
                };
            })
            .OrderByDescending(c => c.trendingScore)
            .Take(10)
            .ToList();

            return Ok(trendingCommunities);
        }

        // GET: api/discovery/popular/members
        [HttpGet("popular/members")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<object>>> GetPopularMembers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var popularMembers = await _context.Accounts
                .Where(a => a.ShowInDirectory && !a.IsSuspended)
                .Select(a => new
                {
                    accountId = a.AccountId,
                    firstName = a.FirstName,
                    lastName = a.LastName,
                    email = a.Email,
                    roleId = a.RoleId, // SECURITY: Non-guessable RoleId
                    roleName = a.Role != null ? a.Role.RoleName : "Unknown",
                    reputationPoints = a.ReputationPoints,
                    postCount = a.PostCount,
                    commentCount = a.CommentCount,
                    likesReceived = a.LikesReceived,
                    lastActiveAt = a.LastActiveAt,
                    createdAt = a.CreatedAt,
                    hasProfilePhoto = false // Add when profile photos are implemented
                })
                .OrderByDescending(m => m.reputationPoints)
                .ThenByDescending(m => m.postCount + m.commentCount)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(popularMembers);
        }

        // GET: api/discovery/suggested/communities
        [HttpGet("suggested/communities")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<object>>> GetSuggestedCommunities()
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            // Get user's properties
            var userProperties = await _context.ChildProperties
                .Where(p => p.OwnerId == accountId && p.IsApproved)
                .ToListAsync();

            var projectIds = userProperties
                .Select(p => p.ProjectId)
                .Where(id => id.HasValue)
                .Cast<long>()
                .Distinct()
                .ToList();

            var developerIds = userProperties
                .Where(p => p.ProjectId.HasValue)
                .Join(_context.Projects,
                    p => p.ProjectId,
                    pr => pr.ProjectId,
                    (p, pr) => pr.DeveloperId)
                .Distinct()
                .ToList();

            // Get user's joined community IDs
            var joinedCommunityIds = await _context.CommunityMembers
                .Where(m => m.AccountId == accountId.Value)
                .Select(m => m.CommunityId)
                .ToListAsync();

            // Find communities matching user's interests
            var suggestedCommunities = await _context.Communities
                .Include(c => c.Members)
                .Where(c => c.IsActive && !joinedCommunityIds.Contains(c.CommunityId))
                .ToListAsync();

            var result = new List<object>();

            foreach (var community in suggestedCommunities)
            {
                var isRelevant = false;
                var reason = "";

                // Check if community matches user's projects
                if (community.ScopeType == CommunityScopeType.ProjectBased && !string.IsNullOrEmpty(community.ProjectIds))
                {
                    var commProjectIds = System.Text.Json.JsonSerializer.Deserialize<List<long>>(community.ProjectIds) ?? new List<long>();
                    if (commProjectIds.Any(id => projectIds.Contains(id)))
                    {
                        isRelevant = true;
                        reason = "You have properties in this project";
                    }
                }

                // Check if community matches user's developers
                if (community.ScopeType == CommunityScopeType.DeveloperBased && !string.IsNullOrEmpty(community.DeveloperIds))
                {
                    var commDeveloperIds = System.Text.Json.JsonSerializer.Deserialize<List<long>>(community.DeveloperIds) ?? new List<long>();
                    if (commDeveloperIds.Any(id => developerIds.Contains(id)))
                    {
                        isRelevant = true;
                        reason = "You have properties from this developer";
                    }
                }

                // Check if public community with similar interests
                if (community.AccessType == CommunityAccessType.PublicAll || 
                    community.AccessType == CommunityAccessType.PublicOwners)
                {
                    isRelevant = true;
                    reason = "Popular community for property owners";
                }

                if (isRelevant)
                {
                    var memberCount = await _context.CommunityMembers
                        .CountAsync(m => m.CommunityId == community.CommunityId);

                    var postCount = await _context.CommunityPosts
                        .CountAsync(p => p.CommunityId == community.CommunityId);

                    result.Add(new
                    {
                        communityId = community.CommunityId,
                        name = community.Name,
                        description = community.Description,
                        coverPhotoUrl = community.CoverPhotoUrl,
                        memberCount = memberCount,
                        postCount = postCount,
                        reason = reason,
                        createdAt = community.CreatedAt
                    });
                }

                // Limit suggestions
                if (result.Count >= 10)
                    break;
            }

            return Ok(result);
        }

        // GET: api/discovery/search
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> SearchContent(
            [FromQuery] string? query,
            [FromQuery] string? type, // posts, communities, members
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var accountId = GetCurrentAccountId();
            var results = new object();

            if (string.IsNullOrWhiteSpace(query))
                return Ok(new { posts = new List<object>(), communities = new List<object>(), members = new List<object>() });

            query = query.ToLower().Trim();

            if (type == null || type == "posts")
            {
                var posts = await _context.CommunityPosts
                    .Include(p => p.Community)
                    .Include(p => p.Likes)
                    .Include(p => p.Categories)
                    .Where(p => p.Content.ToLower().Contains(query) ||
                                p.Categories.Any(c => c.CategoryName.ToLower().Contains(query)))
                    .OrderByDescending(p => p.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(p => new
                    {
                        postId = p.PostId,
                        communityId = p.CommunityId,
                        communityName = p.Community.Name,
                        authorId = p.AuthorId,
                        // Load author name separately to avoid Type column reference
                        authorName = _context.Accounts
                            .Where(a => a.AccountId == p.AuthorId)
                            .Select(a => a.FirstName + " " + a.LastName)
                            .FirstOrDefault() ?? "",
                        content = p.Content,
                        imageUrl = p.ImageUrl,
                        likeCount = p.LikeCount,
                        commentCount = p.CommentCount,
                        categories = p.Categories.Select(c => c.CategoryName).ToList(),
                        createdAt = p.CreatedAt,
                        isLiked = accountId.HasValue && p.Likes.Any(l => l.AccountId == accountId.Value)
                    })
                    .ToListAsync();

                results = new { posts = posts };
            }

            if (type == null || type == "communities")
            {
                var communities = await _context.Communities
                    .Include(c => c.Members)
                    .Where(c => c.IsActive &&
                               (c.Name.ToLower().Contains(query) ||
                                (c.Description != null && c.Description.ToLower().Contains(query))))
                    .OrderByDescending(c => c.MemberCount)
                    .Take(10)
                    .Select(c => new
                    {
                        communityId = c.CommunityId,
                        name = c.Name,
                        description = c.Description,
                        coverPhotoUrl = c.CoverPhotoUrl,
                        memberCount = c.MemberCount,
                        postCount = c.PostCount,
                        createdAt = c.CreatedAt,
                        isJoined = accountId.HasValue && c.Members.Any(m => m.AccountId == accountId.Value)
                    })
                    .ToListAsync();

                results = new { communities = communities };
            }

            if (type == null || type == "members")
            {
                var members = await _context.Accounts
                    .Where(a => a.ShowInDirectory && !a.IsSuspended &&
                               (a.FirstName.ToLower().Contains(query) ||
                                a.LastName.ToLower().Contains(query) ||
                                a.Email.ToLower().Contains(query)))
                    .Select(a => new
                    {
                        accountId = a.AccountId,
                        firstName = a.FirstName,
                        lastName = a.LastName,
                        email = a.Email,
                        roleId = a.RoleId, // SECURITY: Non-guessable RoleId
                    roleName = a.Role != null ? a.Role.RoleName : "Unknown",
                        reputationPoints = a.ReputationPoints,
                        postCount = a.PostCount,
                        createdAt = a.CreatedAt
                    })
                    .OrderByDescending(m => m.reputationPoints)
                    .Take(20)
                    .ToListAsync();

                results = new { members = members };
            }

            return Ok(results);
        }

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
                return accountId;
            return null;
        }
    }
}

