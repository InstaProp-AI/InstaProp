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
    [AllowAnonymous]
    public class DiscoveryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DiscoveryController(AppDbContext context)
        {
            _context = context;
        }

        // Community endpoints removed

        // GET: api/discovery/popular/members
        [HttpGet("popular/members")]
        public async Task<ActionResult<IEnumerable<object>>> GetPopularMembers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            var popularMembers = await _context.Accounts
                .Where(a => !a.IsSuspended)
                .Select(a => new
                {
                    accountId = a.AccountId,
                    firstName = a.FirstName,
                    lastName = a.LastName,
                    email = a.Email,
                    roleId = a.RoleId, // SECURITY: Non-guessable RoleId
                    roleName = a.Role != null ? a.Role.RoleName : "Unknown",
                    // Community-related fields removed
                    // LastActiveAt removed (community feature)
                    createdAt = a.CreatedAt,
                    hasProfilePhoto = false // Add when profile photos are implemented
                })
                .OrderByDescending(m => m.createdAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(popularMembers);
        }

        // Suggested communities endpoint removed

        // GET: api/discovery/search
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<ActionResult<object>> SearchContent(
            [FromQuery] string? query,
            [FromQuery] string? type, // members only (posts and communities removed)
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            if (string.IsNullOrWhiteSpace(query))
                return Ok(new { members = new List<object>() });

            query = query.ToLower().Trim();

            if (type == null || type == "members")
            {
                var members = await _context.Accounts
                    .Where(a => !a.IsSuspended &&
                               (a.FirstName.ToLower().Contains(query) ||
                                a.LastName.ToLower().Contains(query) ||
                                a.Email.ToLower().Contains(query)))
                    .Select(a => new
                    {
                        accountId = a.AccountId,
                        firstName = a.FirstName,
                        lastName = a.LastName,
                        email = a.Email,
                        roleId = a.RoleId,
                        roleName = a.Role != null ? a.Role.RoleName : "Unknown",
                        createdAt = a.CreatedAt
                    })
                    .OrderByDescending(m => m.createdAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                return Ok(new { members = members });
            }

            return Ok(new { members = new List<object>() });
        }

        private Guid? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && Guid.TryParse(accountIdClaim.Value, out var accountId))
                return accountId;
            return null;
        }
    }
}

