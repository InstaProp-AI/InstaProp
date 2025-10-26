using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReactionController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ReactionController(AppDbContext context)
        {
            _context = context;
        }

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
                return accountId;
            return null;
        }

        // POST: api/reaction/post/{postId}
        [HttpPost("post/{postId}")]
        [Authorize]
        public async Task<ActionResult> AddPostReaction(long postId, [FromBody] ReactionRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts
                .Include(p => p.Author)
                .FirstOrDefaultAsync(p => p.PostId == postId);

            if (post == null)
                return NotFound("Post not found");

            // Check if user already reacted to this post
            var existingReaction = await _context.PostReactions
                .FirstOrDefaultAsync(r => r.PostId == postId && r.AccountId == accountId.Value);

            if (existingReaction != null)
            {
                // Update existing reaction
                existingReaction.ReactionType = request.ReactionType;
                existingReaction.CreatedAt = DateTime.UtcNow;
            }
            else
            {
                // Add new reaction
                var reaction = new PostReaction
                {
                    PostId = postId,
                    AccountId = accountId.Value,
                    ReactionType = request.ReactionType,
                    CreatedAt = DateTime.UtcNow
                };
                _context.PostReactions.Add(reaction);

                // Update author's reputation
                if (post.Author != null)
                {
                    post.Author.ReputationPoints += GetReactionPoints(request.ReactionType);
                    post.Author.LikesReceived++;
                }
            }

            post.LastActivityAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Reaction added successfully" });
        }

        // DELETE: api/reaction/post/{postId}
        [HttpDelete("post/{postId}")]
        [Authorize]
        public async Task<ActionResult> RemovePostReaction(long postId)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var reaction = await _context.PostReactions
                .FirstOrDefaultAsync(r => r.PostId == postId && r.AccountId == accountId.Value);

            if (reaction == null)
                return NotFound("Reaction not found");

            var post = await _context.CommunityPosts
                .Include(p => p.Author)
                .FirstOrDefaultAsync(p => p.PostId == postId);

            if (post != null && post.Author != null)
            {
                post.Author.ReputationPoints -= GetReactionPoints(reaction.ReactionType);
                post.Author.LikesReceived = Math.Max(0, post.Author.LikesReceived - 1);
            }

            _context.PostReactions.Remove(reaction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Reaction removed successfully" });
        }

        // GET: api/reaction/post/{postId}/summary
        [HttpGet("post/{postId}/summary")]
        public async Task<ActionResult> GetReactionSummary(long postId)
        {
            var reactions = await _context.PostReactions
                .Where(r => r.PostId == postId)
                .GroupBy(r => r.ReactionType)
                .Select(g => new
                {
                    ReactionType = g.Key,
                    Count = g.Count()
                })
                .ToListAsync();

            return Ok(reactions);
        }

        private int GetReactionPoints(ReactionType reactionType)
        {
            return reactionType switch
            {
                ReactionType.Like => 1,
                ReactionType.Celebrate => 2,
                ReactionType.Insightful => 3,
                ReactionType.Helpful => 3,
                ReactionType.Love => 2,
                ReactionType.ThankYou => 4,
                _ => 1
            };
        }
    }

    public class ReactionRequest
    {
        public ReactionType ReactionType { get; set; }
    }
}

