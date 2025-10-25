using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Services;
using System.Security.Claims;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RedemptionController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly RewardService _rewardService;

        public RedemptionController(AppDbContext context, RewardService rewardService)
        {
            _context = context;
            _rewardService = rewardService;
        }

        [HttpPost("redeem")]
        [Authorize]
        public async Task<ActionResult<RedemptionResponse>> RedeemReward([FromBody] RedeemRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            // Validate points
            var currentPoints = await _rewardService.GetCurrentPointsAsync(accountId.Value);
            if (currentPoints < request.Points)
            {
                return BadRequest(new { message = "Insufficient points" });
            }

            // Generate unique promo code
            string promoCode;
            bool isUnique = false;
            int attempts = 0;
            do
            {
                promoCode = _rewardService.GeneratePromoCode();
                isUnique = !await _context.Redemptions.AnyAsync(r => r.PromoCode == promoCode);
                attempts++;
            } while (!isUnique && attempts < 10);

            if (!isUnique)
            {
                return StatusCode(500, new { message = "Failed to generate unique promo code" });
            }

            // Spend points
            var success = await _rewardService.SpendPointsAsync(accountId.Value, request.Points);
            if (!success)
            {
                return BadRequest(new { message = "Failed to spend points" });
            }

            // Create redemption record
            var redemption = new Redemption
            {
                AccountId = accountId.Value,
                RewardType = request.RewardType,
                PointsSpent = request.Points,
                PromoCode = promoCode,
                RedeemedAt = DateTime.UtcNow
            };

            _context.Redemptions.Add(redemption);
            await _context.SaveChangesAsync();

            return Ok(new RedemptionResponse
            {
                RedemptionId = redemption.RedemptionId,
                PromoCode = promoCode,
                RewardType = redemption.RewardType,
                PointsSpent = redemption.PointsSpent,
                RedeemedAt = redemption.RedeemedAt
            });
        }

        [HttpGet("history")]
        [Authorize]
        public async Task<ActionResult<List<Redemption>>> GetRedemptionHistory()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var redemptions = await _context.Redemptions
                .Where(r => r.AccountId == accountId)
                .OrderByDescending(r => r.RedeemedAt)
                .ToListAsync();

            return Ok(redemptions);
        }

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
        }
    }

    public class RedeemRequest
    {
        public string RewardType { get; set; } = string.Empty;
        public int Points { get; set; }
    }

    public class RedemptionResponse
    {
        public long RedemptionId { get; set; }
        public string PromoCode { get; set; } = string.Empty;
        public string RewardType { get; set; } = string.Empty;
        public int PointsSpent { get; set; }
        public DateTime RedeemedAt { get; set; }
    }
}
