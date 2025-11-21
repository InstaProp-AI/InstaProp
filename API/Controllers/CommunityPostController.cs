using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System.Security.Claims;

namespace InstapropAPI.Controllers
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

        // GET: api/posts/{id}/counts
        [HttpGet("~/api/posts/{id}/counts")]
        public async Task<ActionResult<object>> GetPostCounts(long id)
        {
            var exists = await _context.CommunityPosts.AnyAsync(p => p.PostId == id);
            if (!exists)
                return NotFound();

            var likeCount = await _context.PostLikes.CountAsync(l => l.PostId == id);
            var reactionCount = await _context.PostReactions.CountAsync(r => r.PostId == id);
            var commentCount = await _context.PostComments.CountAsync(c => c.PostId == id);

            return Ok(new { likeCount, reactionCount, commentCount });
        }

        // GET: api/posts/{id}/user-reaction
        [HttpGet("~/api/posts/{id}/user-reaction")]
        public async Task<ActionResult<object>> GetUserReaction(long id)
        {
            var accountId = GetCurrentAccountId();

            var exists = await _context.CommunityPosts.AnyAsync(p => p.PostId == id);
            if (!exists)
                return NotFound();

            if (!accountId.HasValue)
            {
                return Ok(new { isLiked = false, userReaction = (string?)null });
            }

            var isLiked = await _context.PostLikes
                .AnyAsync(l => l.PostId == id && l.AccountId == accountId.Value);

            var userReaction = await _context.PostReactions
                .Where(r => r.PostId == id && r.AccountId == accountId.Value)
                .Select(r => r.ReactionType.ToString())
                .FirstOrDefaultAsync();

            return Ok(new { isLiked, userReaction });
        }

        // POST: api/posts/{id}/bookmark
        [HttpPost("~/api/posts/{id}/bookmark")]
        [Authorize]
        public async Task<ActionResult> ToggleBookmark(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts.FirstOrDefaultAsync(p => p.PostId == id);
            if (post == null)
                return NotFound();

            var existing = await _context.PostBookmarks
                .FirstOrDefaultAsync(b => b.PostId == id && b.AccountId == accountId.Value);

            var isBookmarked = false;
            if (existing != null)
            {
                _context.PostBookmarks.Remove(existing);
            }
            else
            {
                _context.PostBookmarks.Add(new PostBookmark
                {
                    PostId = id,
                    AccountId = accountId.Value,
                    CreatedAt = DateTime.UtcNow
                });
                isBookmarked = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { isBookmarked });
        }

        // GET: api/posts/{id}/bookmark/status
        [HttpGet("~/api/posts/{id}/bookmark/status")]
        [Authorize]
        public async Task<ActionResult> GetBookmarkStatus(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var exists = await _context.PostBookmarks
                .AnyAsync(b => b.PostId == id && b.AccountId == accountId.Value);
            return Ok(new { isBookmarked = exists });
        }

        // GET: api/posts/bookmarked
        [HttpGet("~/api/posts/bookmarked")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<object>>> GetBookmarkedPosts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var bookmarkedPostIds = await _context.PostBookmarks
                .Where(b => b.AccountId == accountId.Value)
                .OrderByDescending(b => b.CreatedAt)
                .Select(b => b.PostId)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var posts = await _context.CommunityPosts
                .Include(p => p.Author)
                .Include(p => p.Community)
                .Include(p => p.Likes)
                .Include(p => p.Categories)
                .Include(p => p.Poll)
                    .ThenInclude(poll => poll.Votes)
                .Where(p => bookmarkedPostIds.Contains(p.PostId))
                .ToListAsync();

            var reactions = await _context.PostReactions
                .Where(r => bookmarkedPostIds.Contains(r.PostId))
                .ToListAsync();

            var result = posts.Select(p => MapToPostResponse(p, accountId, reactions));
            return Ok(result);
        }

        // POST: api/posts/{id}/share
        [HttpPost("~/api/posts/{id}/share")]
        [Authorize]
        public async Task<ActionResult> SharePost(long id, [FromBody] SharePostDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var original = await _context.CommunityPosts
                .Include(p => p.Community)
                .FirstOrDefaultAsync(p => p.PostId == id);

            if (original == null)
                return NotFound("Post not found");

            var targetCommunity = await _context.Communities
                .Include(c => c.Members)
                .FirstOrDefaultAsync(c => c.CommunityId == dto.TargetCommunityId);

            if (targetCommunity == null)
                return NotFound("Target community not found");

            if (!targetCommunity.Members.Any(m => m.AccountId == accountId.Value))
                return Forbid("Must be a member to share into this community");

            var contentPrefix = string.IsNullOrWhiteSpace(dto.Message) ? string.Empty : dto.Message.Trim() + "\n\n";
            var newPost = new CommunityPost
            {
                CommunityId = targetCommunity.CommunityId,
                AuthorId = accountId.Value,
                Content = contentPrefix + original.Content,
                ImageUrl = original.ImageUrl,
                PostType = original.PostType,
                CreatedAt = DateTime.UtcNow
            };

            _context.CommunityPosts.Add(newPost);
            targetCommunity.PostCount++;
            await _context.SaveChangesAsync();

            return Ok(new { postId = newPost.PostId });
        }

        // PUT: api/posts/{id}
        [HttpPut("~/api/posts/{id}")]
        [Authorize]
        public async Task<ActionResult> UpdatePost(long id, [FromBody] UpdatePostDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts.FindAsync(id);
            if (post == null)
                return NotFound();

            if (post.AuthorId != accountId.Value)
                return Forbid();

            post.Content = dto.Content ?? post.Content;
            post.ImageUrl = dto.ImageUrl;
            post.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/posts/{id}
        [HttpDelete("~/api/posts/{id}")]
        [Authorize]
        public async Task<ActionResult> DeletePost(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts
                .Include(p => p.Community)
                .FirstOrDefaultAsync(p => p.PostId == id);
            if (post == null)
                return NotFound();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            var isAdmin = account != null && account.RoleId == Role.ADMIN_ROLE_ID; // SECURITY: Check non-guessable RoleId
            if (post.AuthorId != accountId.Value && !isAdmin)
                return Forbid();

            if (post.Community != null && post.Community.PostCount > 0)
            {
                post.Community.PostCount--;
            }

            _context.CommunityPosts.Remove(post);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // POST: api/posts/{id}/report
        [HttpPost("~/api/posts/{id}/report")]
        [Authorize]
        public async Task<ActionResult> ReportPost(long id, [FromBody] ReportPostDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var exists = await _context.CommunityPosts.AnyAsync(p => p.PostId == id);
            if (!exists)
                return NotFound();

            // Placeholder implementation: accept report and return success
            return Ok(new { message = "Report received" });
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
            
            // Load reactions separately
            var postIds = posts.Select(p => p.PostId).ToList();
            var reactions = await _context.PostReactions
                .Where(r => postIds.Contains(r.PostId))
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

            var result = paginatedPosts.Select(p => MapToPostResponse(p, accountId, reactions));
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
            
            // Load reactions separately
            var postIds = posts.Select(p => p.PostId).ToList();
            var reactions = await _context.PostReactions
                .Where(r => postIds.Contains(r.PostId))
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

            var result = paginatedPosts.Select(p => MapToPostResponse(p, accountId, reactions));
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
            
            // Load reactions separately
            var reactions = await _context.PostReactions
                .Where(r => r.PostId == id)
                .ToListAsync();

            if (post == null)
                return NotFound();

            return Ok(MapToPostResponse(post, accountId, reactions));
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
            request.TryGetValue("poll", out var pollObj);

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

            // Create poll if provided and postType == Poll
            if (post.PostType == PostType.Poll && pollObj is Dictionary<string, object> pollData)
            {
                pollData.TryGetValue("question", out var questionObj);
                pollData.TryGetValue("options", out var optionsObj);
                pollData.TryGetValue("endsAt", out var endsAtObj);

                var optionsList = new List<object>();
                if (optionsObj is IEnumerable<object> optEnum)
                {
                    foreach (var o in optEnum)
                    {
                        var text = o?.ToString() ?? string.Empty;
                        optionsList.Add(new { optionText = text, voteCount = 0 });
                    }
                }

                var poll = new Poll
                {
                    PostId = post.PostId,
                    Question = questionObj?.ToString() ?? string.Empty,
                    Options = System.Text.Json.JsonSerializer.Serialize(optionsList),
                    EndsAt = endsAtObj != null && DateTime.TryParse(endsAtObj.ToString(), out var ends)
                        ? ends : null,
                    TotalVotes = 0,
                    ImageUrl = request.TryGetValue("pollImageUrl", out var pollImageObj) ? pollImageObj?.ToString() : null,
                };
                _context.Polls.Add(poll);
                await _context.SaveChangesAsync();
            }

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

        private object MapToPostResponse(CommunityPost post, long? accountId, List<PostReaction>? reactions = null)
        {
            // Calculate accurate counts from database
            var likeCount = post.Likes?.Count ?? 0;
            
            // Get reactions for this post
            var postReactions = reactions?.Where(r => r.PostId == post.PostId).ToList() ?? new List<PostReaction>();
            var reactionCount = postReactions.Count;
            
            // Check if user has liked (PostLikes table)
            var isLiked = accountId.HasValue && post.Likes?.Any(l => l.AccountId == accountId.Value) == true;
            
            // Get user's current reaction (PostReactions table)
            PostReaction? userReaction = null;
            string? userReactionType = null;
            if (accountId.HasValue && postReactions != null)
            {
                userReaction = postReactions.FirstOrDefault(r => r.AccountId == accountId.Value);
                if (userReaction != null)
                {
                    userReactionType = userReaction.ReactionType.ToString();
                }
            }
            
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
                authorRoleId = post.Author?.RoleId ?? 0, // SECURITY: Non-guessable RoleId
                authorRoleName = post.Author != null && post.Author.Role != null ? post.Author.Role.RoleName : "Owner",
                content = post.Content,
                imageUrl = post.ImageUrl,
                postType = post.PostType.ToString(),
                isPinned = post.IsPinned,
                likeCount = likeCount, // From PostLikes table
                reactionCount = reactionCount, // From PostReactions table
                userReaction = userReactionType, // Current user's reaction type if any
                commentCount = post.CommentCount,
                isLiked = isLiked,
                categories = post.Categories.Select(c => c.CategoryName).ToList(),
                createdAt = post.CreatedAt
            };

            return result;
        }

        public class SharePostDto
        {
            public long TargetCommunityId { get; set; }
            public string? Message { get; set; }
        }

        public class UpdatePostDto
        {
            public string? Content { get; set; }
            public string? ImageUrl { get; set; }
        }

        public class ReportPostDto
        {
            public string Reason { get; set; } = string.Empty;
            public string? Details { get; set; }
        }
    }
}
