using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System.Text.Json;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PollsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PollsController(AppDbContext context)
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

        // GET: api/polls/{postId}
        [HttpGet("{postId:long}")]
        public async Task<ActionResult<object>> GetPollByPost(long postId)
        {
            var accountId = GetCurrentAccountId();

            var poll = await _context.Polls
                .Include(p => p.Post)
                .Include(p => p.Votes)
                .FirstOrDefaultAsync(p => p.PostId == postId);

            if (poll == null)
                return NotFound("Poll not found");

            var options = ParseOptions(poll.Options);
            var userSelections = accountId.HasValue
                ? poll.Votes.Where(v => v.AccountId == accountId.Value).Select(v => v.OptionIndex).ToList()
                : new List<int>();

            return Ok(new
            {
                pollId = poll.PollId,
                postId = poll.PostId,
                question = poll.Question,
                options,
                totalVotes = poll.TotalVotes,
                endsAt = poll.EndsAt,
                isMultipleChoice = poll.IsMultipleChoice,
                allowChangeVote = poll.AllowChangeVote,
                showResultsBeforeVote = poll.ShowResultsBeforeVote,
                imageUrl = poll.ImageUrl,
                userSelections
            });
        }

        // POST: api/polls/{pollId}/vote
        [HttpPost("{pollId:long}/vote")]
        [Authorize]
        public async Task<ActionResult> Vote(long pollId, [FromBody] VoteRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var poll = await _context.Polls
                .Include(p => p.Post)
                .Include(p => p.Votes)
                .FirstOrDefaultAsync(p => p.PollId == pollId);

            if (poll == null)
                return NotFound("Poll not found");

            if (poll.EndsAt.HasValue && poll.EndsAt.Value <= DateTime.UtcNow)
                return BadRequest("Poll has ended");

            // Enforce community membership
            var isMember = await _context.CommunityMembers
                .AnyAsync(m => m.AccountId == accountId.Value && m.CommunityId == poll.Post.CommunityId);
            if (!isMember)
                return Forbid("Must be a member to vote");

            var options = ParseOptions(poll.Options);
            if (poll.IsMultipleChoice)
            {
                // Multi-choice: request.OptionIndexes required
                if (request.OptionIndexes == null || !request.OptionIndexes.Any())
                    return BadRequest("OptionIndexes required for multi-choice poll");
                var set = request.OptionIndexes.Distinct().ToList();
                if (set.Any(i => i < 0 || i >= options.Count))
                    return BadRequest("Invalid option index");

                // Remove previous votes if AllowChangeVote is true; otherwise, do nothing
                if (!poll.AllowChangeVote)
                {
                    // If already voted, do not allow changes
                    var hasVotes = await _context.PollVotes.AnyAsync(v => v.PollId == poll.PollId && v.AccountId == accountId.Value);
                    if (hasVotes) return Ok(new { message = "Vote recorded" });
                }
                else
                {
                    var previous = _context.PollVotes.Where(v => v.PollId == poll.PollId && v.AccountId == accountId.Value).ToList();
                    foreach (var pv in previous)
                    {
                        if (pv.OptionIndex >= 0 && pv.OptionIndex < options.Count)
                            options[pv.OptionIndex].voteCount = Math.Max(0, options[pv.OptionIndex].voteCount - 1);
                        _context.PollVotes.Remove(pv);
                        poll.TotalVotes = Math.Max(0, poll.TotalVotes - 1);
                    }
                }

                foreach (var idx in set)
                {
                    _context.PollVotes.Add(new PollVote
                    {
                        PollId = poll.PollId,
                        AccountId = accountId.Value,
                        OptionIndex = idx,
                        CreatedAt = DateTime.UtcNow
                    });
                    options[idx].voteCount++;
                    poll.TotalVotes++;
                }
                poll.Options = JsonSerializer.Serialize(options);
            }
            else
            {
                if (request.OptionIndex == null)
                    return BadRequest("OptionIndex required for single-choice poll");
                var oi = request.OptionIndex.Value;
                if (oi < 0 || oi >= options.Count)
                    return BadRequest("Invalid option index");

                if (!poll.AllowChangeVote)
                {
                    var hasVotes = await _context.PollVotes.AnyAsync(v => v.PollId == poll.PollId && v.AccountId == accountId.Value);
                    if (hasVotes) return Ok(new { message = "Vote recorded" });
                }

                var existing = poll.Votes.FirstOrDefault(v => v.AccountId == accountId.Value);
                if (existing != null)
                {
                    if (existing.OptionIndex != oi)
                    {
                        if (existing.OptionIndex >= 0 && existing.OptionIndex < options.Count)
                            options[existing.OptionIndex].voteCount = Math.Max(0, options[existing.OptionIndex].voteCount - 1);
                        existing.OptionIndex = oi;
                        options[oi].voteCount++;
                    }
                }
                else
                {
                    _context.PollVotes.Add(new PollVote
                    {
                        PollId = poll.PollId,
                        AccountId = accountId.Value,
                        OptionIndex = oi,
                        CreatedAt = DateTime.UtcNow
                    });
                    options[oi].voteCount++;
                    poll.TotalVotes++;
                }
                poll.Options = JsonSerializer.Serialize(options);
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Vote recorded" });
        }

        private List<PollOptionDto> ParseOptions(string json)
        {
            try
            {
                var opts = JsonSerializer.Deserialize<List<PollOptionDto>>(json);
                return opts ?? new List<PollOptionDto>();
            }
            catch
            {
                return new List<PollOptionDto>();
            }
        }

        public class VoteRequest
        {
            public int? OptionIndex { get; set; }
            public List<int>? OptionIndexes { get; set; }
        }

        public class PollOptionDto
        {
            public string optionText { get; set; } = string.Empty;
            public int voteCount { get; set; } = 0;
        }
    }
}


