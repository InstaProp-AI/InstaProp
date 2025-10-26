using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/polls")]
    public class PollController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PollController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/polls/{id}/vote
        [HttpPost("{id}/vote")]
        [Authorize]
        public async Task<IActionResult> VoteOnPoll(long id, [FromBody] VoteDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var poll = await _context.Polls
                .Include(p => p.Post)
                .FirstOrDefaultAsync(p => p.PollId == id);

            if (poll == null)
                return NotFound("Poll not found");

            // Check if poll has ended
            if (poll.EndsAt.HasValue && DateTime.UtcNow > poll.EndsAt.Value)
                return BadRequest("Poll has ended");

            // Check if user already voted
            var existingVote = await _context.PollVotes
                .FirstOrDefaultAsync(v => v.PollId == id && v.AccountId == accountId.Value);

            if (existingVote != null)
                return BadRequest("Already voted on this poll");

            // Validate option index
            var options = JsonSerializer.Deserialize<List<dynamic>>(poll.Options) ?? new List<dynamic>();
            if (dto.OptionIndex < 0 || dto.OptionIndex >= options.Count)
                return BadRequest("Invalid option index");

            // Add vote
            _context.PollVotes.Add(new PollVote
            {
                PollId = id,
                AccountId = accountId.Value,
                OptionIndex = dto.OptionIndex,
                CreatedAt = DateTime.UtcNow
            });

            // Update option vote count
            options[dto.OptionIndex] = new Dictionary<string, object>
            {
                ["text"] = options[dto.OptionIndex].GetProperty("text").GetString() ?? "",
                ["voteCount"] = options[dto.OptionIndex].GetProperty("voteCount").GetInt32() + 1
            };

            poll.Options = JsonSerializer.Serialize(options);
            poll.TotalVotes++;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Vote recorded" });
        }

        // GET: api/polls/{id}/results
        [HttpGet("{id}/results")]
        public async Task<ActionResult<PollResponseDto>> GetPollResults(long id)
        {
            var accountId = GetCurrentAccountId();

            var poll = await _context.Polls
                .Include(p => p.Votes)
                .FirstOrDefaultAsync(p => p.PollId == id);

            if (poll == null)
                return NotFound("Poll not found");

            var options = JsonSerializer.Deserialize<List<dynamic>>(poll.Options) ?? new List<dynamic>();
            var userVote = accountId.HasValue 
                ? poll.Votes.FirstOrDefault(v => v.AccountId == accountId.Value) 
                : null;

            var pollOptions = options.Select((opt, index) => new PollOptionDto
            {
                Text = opt.GetProperty("text").GetString() ?? "",
                VoteCount = opt.GetProperty("voteCount").GetInt32(),
                Percentage = poll.TotalVotes > 0 ? (opt.GetProperty("voteCount").GetInt32() * 100.0 / poll.TotalVotes) : 0
            }).ToList();

            return Ok(new PollResponseDto
            {
                PollId = poll.PollId,
                Question = poll.Question,
                Options = pollOptions,
                TotalVotes = poll.TotalVotes,
                EndsAt = poll.EndsAt,
                HasVoted = userVote != null,
                UserVoteOptionIndex = userVote?.OptionIndex
            });
        }

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
                return accountId;
            return null;
        }
    }

    public class VoteDto
    {
        public int OptionIndex { get; set; }
    }
}

