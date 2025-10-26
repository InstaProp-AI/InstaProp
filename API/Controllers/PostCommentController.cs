using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/posts/{postId}/comments")]
    public class PostCommentController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PostCommentController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/posts/{postId}/comments
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CommentResponseDto>>> GetComments(long postId)
        {
            var accountId = GetCurrentAccountId();

            var comments = await _context.PostComments
                .Include(c => c.Author)
                .Include(c => c.Likes)
                .Include(c => c.Replies)
                    .ThenInclude(r => r.Author)
                .Include(c => c.Replies)
                    .ThenInclude(r => r.Likes)
                .Where(c => c.PostId == postId && c.ParentCommentId == null)
                .OrderByDescending(c => c.CreatedAt)
                .ToListAsync();

            var result = comments.Select(c => MapToCommentResponse(c, accountId));
            return Ok(result);
        }

        // POST: api/posts/{postId}/comments
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<PostComment>> CreateComment(long postId, [FromBody] CreateCommentDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var post = await _context.CommunityPosts
                .Include(p => p.Community)
                .FirstOrDefaultAsync(p => p.PostId == postId);
            
            if (post == null)
                return NotFound("Post not found");

            // Check if user is a member of the community
            var isMember = await _context.CommunityMembers
                .AnyAsync(m => m.AccountId == accountId.Value && m.CommunityId == post.CommunityId);

            if (!isMember)
                return Forbid("Must be a member of this community to comment");

            // Validate parent comment if provided
            if (dto.ParentCommentId.HasValue)
            {
                var parentComment = await _context.PostComments
                    .FirstOrDefaultAsync(c => c.CommentId == dto.ParentCommentId.Value);
                if (parentComment == null)
                    return NotFound("Parent comment not found");
            }

            var comment = new PostComment
            {
                PostId = postId,
                AuthorId = accountId.Value,
                Content = dto.Content,
                ParentCommentId = dto.ParentCommentId,
                CreatedAt = DateTime.UtcNow
            };

            _context.PostComments.Add(comment);
            post.CommentCount++;
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetComments), new { postId }, MapToCommentResponse(comment, accountId));
        }

        // PUT: api/comments/{id}
        [HttpPut("~/api/comments/{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateComment(long id, [FromBody] CreateCommentDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var comment = await _context.PostComments.FindAsync(id);
            if (comment == null)
                return NotFound();

            // Check if user is author
            if (comment.AuthorId != accountId.Value)
                return Forbid();

            comment.Content = dto.Content;
            comment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/comments/{id}
        [HttpDelete("~/api/comments/{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteComment(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.CommentId == id);

            if (comment == null)
                return NotFound();

            // Check if user is author, community moderator, or admin
            var account = await _context.Accounts.FindAsync(accountId.Value);
            var isCreator = comment.AuthorId == accountId.Value;
            var isAdmin = account?.Type == AccountType.Admin;
            
            // TODO: Check if user is community moderator

            if (!isCreator && !isAdmin)
                return Forbid();

            comment.Post.CommentCount--;
            _context.PostComments.Remove(comment);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/comments/{id}/like
        [HttpPost("~/api/comments/{id}/like")]
        [Authorize]
        public async Task<IActionResult> ToggleLike(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var existingLike = await _context.CommentLikes
                .FirstOrDefaultAsync(l => l.CommentId == id && l.AccountId == accountId.Value);

            var comment = await _context.PostComments.FindAsync(id);
            if (comment == null)
                return NotFound();

            if (existingLike != null)
            {
                _context.CommentLikes.Remove(existingLike);
                comment.LikeCount--;
            }
            else
            {
                _context.CommentLikes.Add(new CommentLike
                {
                    CommentId = id,
                    AccountId = accountId.Value,
                    CreatedAt = DateTime.UtcNow
                });
                comment.LikeCount++;
            }

            await _context.SaveChangesAsync();
            return Ok(new { isLiked = existingLike == null });
        }

        // Helper methods
        private CommentResponseDto MapToCommentResponse(PostComment comment, long? accountId)
        {
            var isLiked = accountId.HasValue && comment.Likes.Any(l => l.AccountId == accountId.Value);

            return new CommentResponseDto
            {
                CommentId = comment.CommentId,
                PostId = comment.PostId,
                AuthorId = comment.AuthorId,
                AuthorName = $"{comment.Author?.FirstName} {comment.Author?.LastName}",
                AuthorType = GetAuthorType(comment.Author),
                Content = comment.Content,
                ParentCommentId = comment.ParentCommentId,
                LikeCount = comment.LikeCount,
                IsLiked = isLiked,
                Replies = comment.Replies.OrderByDescending(r => r.CreatedAt)
                    .Select(r => MapToCommentResponse(r, accountId))
                    .ToList(),
                CreatedAt = comment.CreatedAt
            };
        }

        private string GetAuthorType(Account? author)
        {
            if (author == null) return "Owner";
            
            if (author.Type == AccountType.Admin)
                return "Admin";
            
            if (author.Type == AccountType.Developer)
                return "Developer";
            
            return "Owner";
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

