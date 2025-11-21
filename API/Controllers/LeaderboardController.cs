using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstapropAPI.Models;
using InstapropAPI.Services;
using InstapropAPI.Attributes;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [FeaturePermissionAttribute("Leaderboard")]
    public class LeaderboardController : ControllerBase
    {
        private readonly LeaderboardService _leaderboardService;

        public LeaderboardController(LeaderboardService leaderboardService)
        {
            _leaderboardService = leaderboardService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<LeaderboardResponseDto>> GetLeaderboard(
            [FromQuery] string period = "thisWeek",
            CancellationToken cancellationToken = default)
        {
            if (!TryParsePeriod(period, out var targetPeriod))
            {
                return BadRequest(new { message = "Invalid period. Use thisWeek, lastWeek, or allTime." });
            }

            var accountId = GetOptionalAccountId();
            var result = await _leaderboardService.GetLeaderboardAsync(targetPeriod, accountId, cancellationToken);
            return Ok(result);
        }

        [HttpGet("highlights")]
        [AllowAnonymous]
        public async Task<ActionResult<LeaderboardHighlightsResponseDto>> GetHighlights(CancellationToken cancellationToken = default)
        {
            var accountId = GetOptionalAccountId();
            var result = await _leaderboardService.GetHighlightsAsync(accountId, cancellationToken);
            return Ok(result);
        }

        private long? GetOptionalAccountId()
        {
            var userIdClaim = User?.FindFirst("uid") ?? User?.FindFirst("sub");
            if (userIdClaim == null)
            {
                return null;
            }

            return long.TryParse(userIdClaim.Value, out var parsed) ? parsed : null;
        }

        private static bool TryParsePeriod(string raw, out LeaderboardPeriod period)
        {
            switch (raw.Trim().ToLowerInvariant())
            {
                case "thisweek":
                case "current":
                case "weekly":
                    period = LeaderboardPeriod.ThisWeek;
                    return true;
                case "lastweek":
                case "previous":
                    period = LeaderboardPeriod.LastWeek;
                    return true;
                case "alltime":
                case "lifetime":
                    period = LeaderboardPeriod.AllTime;
                    return true;
                default:
                    period = LeaderboardPeriod.ThisWeek;
                    return false;
            }
        }
    }
}


