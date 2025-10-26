using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System.Security.Claims;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/communities/{communityId}/posts")]
    public class CommunityPostController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CommunityPostController(AppDbContext context)
        {
            _context = context;
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

        // GET: api/communities/{communityId}/posts
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetPosts(
            long communityId,
            [FromQuery] string sort = "new",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var accountId = GetCurrentAccountId();

            // Check if user can access this community
            var community = await _context.Communities
                .FirstOrDefaultAsync(c => c.CommunityId == communityId && c.IsActive);

            if (community == null)
                return NotFound("Community not found");

            // Check access
            if (community.AccessType == CommunityAccessType.PublicAll)
            {
                // Public - anyone can view
            }
            else if (accountId.HasValue && accountId.Value == 1)
            {
                // Admin can always access (for testing purposes)
            }
            else if (accountId.HasValue)
            {
                // Check if user has property in this project (for private communities)
                var hasAccess = await _context.ChildProperties
                    .Where(p => p.OwnerId == accountId.Value && p.IsApproved)
                    .Join(_context.Projects, p => p.ProjectId, pr => pr.ProjectId, (p, pr) => pr)
                    .AnyAsync(pr => pr.DeveloperId == community.CreatedById);

                if (!hasAccess)
                {
                    // Check if user is a member
                    var isMember = await _context.CommunityMembers
                        .AnyAsync(m => m.AccountId == accountId.Value && m.CommunityId == communityId);

                    if (!isMember)
                        return Forbid("You don't have access to this community");
                }
            }
            else
            {
                return Unauthorized("Please log in to view this community");
            }

            var posts = await _context.CommunityPosts
                .Include(p => p.Author)
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Poll)
                    .ThenInclude(poll => poll.Votes)
                .Where(p => p.CommunityId == communityId)
                .ToListAsync();

            // Update trending scores
            foreach (var post in posts)
            {
                post.CalculateTrendingScore();
            }
            await _context.SaveChangesAsync();

            // Apply sorting with trending scores
            IOrderedEnumerable<CommunityPost> sortedPosts;
            switch (sort.ToLower())
            {
                case "hot":
                    sortedPosts = posts.OrderByDescending(p => p.TrendingScore);
                    break;
                case "top":
                    sortedPosts = posts.OrderByDescending(p => p.LikeCount + p.CommentCount);
                    break;
                default:
                    sortedPosts = posts.OrderByDescending(p => p.CreatedAt);
                    break;
            }

            var paginatedPosts = sortedPosts.Skip((page - 1) * pageSize).Take(pageSize);

            var result = paginatedPosts.Select(p => MapToPostResponse(p, accountId));
            return Ok(result);
        }

        // GET: api/posts/feed
        [HttpGet("~/api/posts/feed")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<object>>> GetFeed(
            [FromQuery] string sort = "new",
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            // Get user's joined communities
            var communityIds = await _context.CommunityMembers
                .Where(m => m.AccountId == accountId.Value)
                .Select(m => m.CommunityId)
                .ToListAsync();

            // Also include public communities
            var publicCommunityIds = await _context.Communities
                .Where(c => c.IsActive && c.AccessType == Models.CommunityAccessType.PublicAll)
                .Select(c => c.CommunityId)
                .ToListAsync();

            var allCommunityIds = communityIds.Union(publicCommunityIds).ToList();

            var posts = await _context.CommunityPosts
                .Include(p => p.Author)
                .Include(p => p.Community)
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Poll)
                    .ThenInclude(poll => poll.Votes)
                .Where(p => allCommunityIds.Contains(p.CommunityId))
                .ToListAsync();

            // Update trending scores for feed
            foreach (var post in posts)
            {
                post.CalculateTrendingScore();
            }

            // Apply sorting with trending scores
            IOrderedEnumerable<CommunityPost> sortedPosts;
            switch (sort.ToLower())
            {
                case "hot":
                    sortedPosts = posts.OrderByDescending(p => p.TrendingScore);
                    break;
                case "top":
                    sortedPosts = posts.OrderByDescending(p => p.LikeCount);
                    break;
                default:
                    sortedPosts = posts.OrderByDescending(p => p.CreatedAt);
                    break;
            }

            var paginatedPosts = sortedPosts.Skip((page - 1) * pageSize).Take(pageSize);

            var result = paginatedPosts.Select(p => MapToPostResponse(p, accountId));
            return Ok(result);
        }

        // GET: api/posts/{id}
        [HttpGet("~/api/posts/{id}")]
        public async Task<ActionResult<object>> GetPost(long id)
        {
            var accountId = GetCurrentAccountId();

            var post = await _context.CommunityPosts
                .Include(p => p.Author)
                .Include(p => p.Community)
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Poll)
                    .ThenInclude(poll => poll.Votes)
                .FirstOrDefaultAsync(p => p.PostId == id);

            if (post == null)
                return NotFound();

            return Ok(MapToPostResponse(post, accountId));
        }

        // POST: api/communities/{communityId}/posts
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<CommunityPost>> CreatePost(
            long communityId,
            [FromBody] Dictionary<string, object> request)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var community = await _context.Communities
                .Include(c => c.Members)
                .FirstOrDefaultAsync(c => c.CommunityId == communityId);

            if (community == null)
                return NotFound("Community not found");

            // Check if user is member
            if (!community.Members.Any(m => m.AccountId == accountId.Value))
                return Forbid("Must be a member to post");

            request.TryGetValue("content", out var contentObj);
            request.TryGetValue("imageUrl", out var imageUrlObj);
            request.TryGetValue("postType", out var postTypeObj);
            request.TryGetValue("categories", out var categoriesObj);

            var post = new CommunityPost
            {
                CommunityId = communityId,
                AuthorId = accountId.Value,
                Content = contentObj?.ToString() ?? "",
                ImageUrl = imageUrlObj?.ToString(),
                PostType = Enum.TryParse<PostType>(postTypeObj?.ToString(), true, out var pt) ? pt : PostType.Regular,
                CreatedAt = DateTime.UtcNow
            };

            _context.CommunityPosts.Add(post);
            community.PostCount++;

            // Handle categories
            if (categoriesObj is List<object> categories)
            {
                foreach (var cat in categories)
                {
                    _context.PostCategories.Add(new PostCategory
                    {
                        PostId = post.PostId,
                        CategoryName = cat.ToString()
                    });
                }
            }

            await _context.SaveChangesAsync();

            // Update author's post count and activity
            var author = await _context.Accounts.FindAsync(accountId.Value);
            if (author != null)
            {
                author.PostCount++;
                author.LastActiveAt = DateTime.UtcNow;
                
                // Award achievement if first post
                if (author.PostCount == 1)
                {
                    _context.UserAchievements.Add(new UserAchievement
                    {
                        AccountId = author.AccountId,
                        AchievementType = AchievementType.FirstPost,
                        Title = "First Post",
                        Description = "You've made your first community post!",
                        PointsAwarded = 10,
                        EarnedAt = DateTime.UtcNow
                    });
                }
            }

            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetPost), new { id = post.PostId }, post);
        }

        // POST: api/posts/{id}/like
        [HttpPost("~/api/posts/{id}/like")]
        [Authorize]
        public async Task<ActionResult> ToggleLike(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts
                .Include(p => p.Likes)
                .Include(p => p.Author)
                .FirstOrDefaultAsync(p => p.PostId == id);

            if (post == null)
                return NotFound();

            var existingLike = post.Likes.FirstOrDefault(l => l.AccountId == accountId.Value);

            if (existingLike != null)
            {
                // Unlike
                post.Likes.Remove(existingLike);
                _context.PostLikes.Remove(existingLike);
                post.LikeCount = Math.Max(0, post.LikeCount - 1);
            }
            else
            {
                // Like
                var like = new PostLike
                {
                    PostId = id,
                    AccountId = accountId.Value,
                    CreatedAt = DateTime.UtcNow
                };
                _context.PostLikes.Add(like);
                post.LikeCount++;
                
                // Update post author's likes received
                if (post.Author != null)
                {
                    post.Author.LikesReceived++;
                }
            }

            // Update last activity timestamp
            post.LastActivityAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { isLiked = existingLike == null });
        }

        private object MapToPostResponse(CommunityPost post, long? accountId)
        {
            var isLiked = accountId.HasValue && post.Likes.Any(l => l.AccountId == accountId.Value);
            var isUserJoinedCommunity = accountId.HasValue && _context.CommunityMembers
                .Any(m => m.CommunityId == post.CommunityId && m.AccountId == accountId.Value);

            var result = new
            {
                postId = post.PostId,
                communityId = post.CommunityId,
                communityName = post.Community?.Name ?? "",
                communityCoverPhotoUrl = post.Community?.CoverPhotoUrl,
                communityAccessType = post.Community?.AccessType.ToString() ?? "Private",
                isUserJoinedCommunity = isUserJoinedCommunity,
                authorId = post.AuthorId,
                authorName = post.Author?.FirstName + " " + post.Author?.LastName,
                authorType = post.Author?.Type.ToString() ?? "Owner",
                content = post.Content,
                imageUrl = post.ImageUrl,
                postType = post.PostType.ToString(),
                isPinned = post.IsPinned,
                likeCount = post.LikeCount,
                commentCount = post.CommentCount,
                isLiked = isLiked,
                categories = post.Categories.Select(c => c.CategoryName).ToList(),
                createdAt = post.CreatedAt
            };

            return result;
        }
    }
}
