using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SalesTeamController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SalesTeamController(AppDbContext context)
        {
            _context = context;
        }

        private Guid? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid") ?? User.FindFirst(ClaimTypes.NameIdentifier);
            if (accountIdClaim != null && Guid.TryParse(accountIdClaim.Value, out var guid))
            {
                return guid;
            }
            return null;
        }

        // GET: api/SalesTeam - Get all teams (admin sees all, developer sees only their teams)
        [HttpGet]
        public async Task<ActionResult<object>> GetAllTeams()
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                IQueryable<SalesTeam> query = _context.SalesTeams
                    .Include(t => t.Developer)
                    .Include(t => t.SalesMembers);

                // If developer, filter to only their teams
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID)
                {
                    query = query.Where(t => t.DeveloperId == currentAccountId.Value);
                }
                // Admin sees all teams

                var teams = await query
                    .OrderBy(t => t.TeamName)
                    .Select(t => new
                    {
                        t.TeamId,
                        t.TeamName,
                        DeveloperId = t.DeveloperId,
                        DeveloperName = $"{t.Developer.FirstName} {t.Developer.LastName}",
                        DeveloperEmail = t.Developer.Email,
                        MemberCount = t.SalesMembers.Count,
                        ActiveMemberCount = t.SalesMembers.Count(m => !m.IsSuspended),
                        CreatedAt = t.CreatedAt,
                        UpdatedAt = t.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(teams);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/SalesTeam/{id} - Get team details
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetTeam(Guid id)
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                var team = await _context.SalesTeams
                    .Include(t => t.Developer)
                    .Include(t => t.SalesMembers)
                    .FirstOrDefaultAsync(t => t.TeamId == id);

                if (team == null)
                    return NotFound(new { error = "Team not found" });

                // Check authorization: developer can only see their own teams
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID && team.DeveloperId != currentAccountId.Value)
                {
                    return Forbid("You can only view your own teams");
                }

                return Ok(new
                {
                    team.TeamId,
                    team.TeamName,
                    DeveloperId = team.DeveloperId,
                    DeveloperName = $"{team.Developer.FirstName} {team.Developer.LastName}",
                    DeveloperEmail = team.Developer.Email,
                    MemberCount = team.SalesMembers.Count,
                    ActiveMemberCount = team.SalesMembers.Count(m => !m.IsSuspended),
                    team.CreatedAt,
                    team.UpdatedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/SalesTeam/{id}/members - Get sales members in team
        [HttpGet("{id}/members")]
        public async Task<ActionResult<object>> GetTeamMembers(Guid id)
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                var team = await _context.SalesTeams
                    .Include(t => t.Developer)
                    .FirstOrDefaultAsync(t => t.TeamId == id);

                if (team == null)
                    return NotFound(new { error = "Team not found" });

                // Check authorization
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID && team.DeveloperId != currentAccountId.Value)
                {
                    return Forbid("You can only view members of your own teams");
                }

                var members = await _context.SalesAccounts
                    .Where(a => a.SalesTeamId == id && a.RoleId == Role.SALES_ROLE_ID)
                    .Include(a => a.Role)
                    .Select(a => new
                    {
                        a.AccountId,
                        a.FirstName,
                        a.LastName,
                        a.Email,
                        a.PhoneNumber,
                        RoleId = a.RoleId,
                        RoleName = a.Role != null ? a.Role.RoleName : "Sales",
                        Status = a.Status.ToString(),
                        a.EmailVerified,
                        a.PhoneVerified,
                        a.IsSuspended,
                        a.SuspendedUntil,
                        a.SuspensionReason,
                        a.CreatedAt,
                        a.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(members);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/SalesTeam/{id}/stats - Get team statistics
        [HttpGet("{id}/stats")]
        public async Task<ActionResult<object>> GetTeamStats(Guid id)
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                var team = await _context.SalesTeams
                    .Include(t => t.Developer)
                    .FirstOrDefaultAsync(t => t.TeamId == id);

                if (team == null)
                    return NotFound(new { error = "Team not found" });

                // Check authorization
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID && team.DeveloperId != currentAccountId.Value)
                {
                    return Forbid("You can only view stats of your own teams");
                }

                // Get team members
                var teamMemberIds = await _context.SalesAccounts
                    .Where(a => a.SalesTeamId == id && a.RoleId == Role.SALES_ROLE_ID)
                    .Select(a => a.AccountId)
                    .ToListAsync();

                // Calculate statistics
                var totalMembers = teamMemberIds.Count;
                var activeMembers = await _context.Accounts
                    .Where(a => teamMemberIds.Contains(a.AccountId) && !a.IsSuspended)
                    .CountAsync();

                // Total assigned users (users who have chats assigned to team members)
                var totalAssignedUsers = await _context.Chats
                    .Where(c => c.SalesMemberId.HasValue && teamMemberIds.Contains(c.SalesMemberId.Value))
                    .Select(c => c.UserId)
                    .Distinct()
                    .CountAsync();

                // Total chats assigned to team
                var totalChats = await _context.Chats
                    .Where(c => c.SalesMemberId.HasValue && teamMemberIds.Contains(c.SalesMemberId.Value))
                    .CountAsync();

                // Completed deals (chats that are marked as completed or auctions that are sold)
                var completedChats = await _context.Chats
                    .Where(c => c.SalesMemberId.HasValue && teamMemberIds.Contains(c.SalesMemberId.Value) && !c.IsActive)
                    .CountAsync();

                // Get auctions where properties belong to the developer and are sold
                var soldAuctions = await _context.Auctions
                    .Where(a => a.Status == "Sold" && a.Property != null && a.Property.OwnerId == team.DeveloperId)
                    .CountAsync();

                var totalDealsFinished = completedChats + soldAuctions;

                // Total revenue from sold auctions
                var totalRevenue = await _context.Auctions
                    .Where(a => a.Status == "Sold" && a.Property != null && a.Property.OwnerId == team.DeveloperId)
                    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0;

                // Average response time (time between chat creation and first message from sales)
                var chatsWithResponses = await _context.Chats
                    .Where(c => c.SalesMemberId.HasValue && teamMemberIds.Contains(c.SalesMemberId.Value))
                    .Include(c => c.Messages)
                    .Where(c => c.Messages.Any())
                    .ToListAsync();

                double? averageResponseTime = null;
                if (chatsWithResponses.Any())
                {
                    var responseTimes = chatsWithResponses
                        .Select(c =>
                        {
                            var firstSalesMessage = c.Messages
                                .Where(m => m.SenderId == c.SalesMemberId)
                                .OrderBy(m => m.CreatedAt)
                                .FirstOrDefault();
                            if (firstSalesMessage != null)
                            {
                                return (firstSalesMessage.CreatedAt - c.CreatedAt).TotalHours;
                            }
                            return (double?)null;
                        })
                        .Where(rt => rt.HasValue)
                        .Select(rt => rt.Value)
                        .ToList();

                    if (responseTimes.Any())
                    {
                        averageResponseTime = responseTimes.Average();
                    }
                }

                // Conversion rate (completed deals / total chats)
                var conversionRate = totalChats > 0 ? (double)totalDealsFinished / totalChats * 100 : 0;

                return Ok(new
                {
                    totalMembers,
                    activeMembers,
                    totalAssignedUsers,
                    totalChats,
                    totalDealsFinished,
                    totalRevenue,
                    averageResponseTimeHours = averageResponseTime,
                    conversionRate = Math.Round(conversionRate, 2)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/SalesTeam/developers/{developerId}/teams - Get teams for a developer
        [HttpGet("developers/{developerId}/teams")]
        [AdminAuthorize]
        public async Task<ActionResult<object>> GetDeveloperTeams(Guid developerId)
        {
            try
            {
                var developer = await _context.Accounts
                    .FirstOrDefaultAsync(a => a.AccountId == developerId && a.RoleId == Role.DEVELOPER_ROLE_ID);

                if (developer == null)
                    return NotFound(new { error = "Developer not found" });

                var teams = await _context.SalesTeams
                    .Where(t => t.DeveloperId == developerId)
                    .Include(t => t.SalesMembers)
                    .Select(t => new
                    {
                        t.TeamId,
                        t.TeamName,
                        DeveloperId = t.DeveloperId,
                        DeveloperName = $"{developer.FirstName} {developer.LastName}",
                        MemberCount = t.SalesMembers.Count,
                        ActiveMemberCount = t.SalesMembers.Count(m => !m.IsSuspended),
                        t.CreatedAt,
                        t.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(teams);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/SalesTeam - Create new team (Admin or Developer)
        [HttpPost]
        public async Task<ActionResult<object>> CreateTeam([FromBody] CreateTeamDto dto)
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                // Check authorization: Only Admin or Developer can create teams
                if (currentAccount.RoleId != Role.ADMIN_ROLE_ID && currentAccount.RoleId != Role.DEVELOPER_ROLE_ID)
                {
                    return Forbid();
                }

                // If developer, they can only create teams for themselves
                Guid targetDeveloperId;
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID)
                {
                    targetDeveloperId = currentAccountId.Value;
                }
                else
                {
                    // Admin can create teams for any developer
                    targetDeveloperId = dto.DeveloperId;
                }

                // Verify developer exists
                var developer = await _context.Accounts
                    .FirstOrDefaultAsync(a => a.AccountId == targetDeveloperId && a.RoleId == Role.DEVELOPER_ROLE_ID);

                if (developer == null)
                    return BadRequest(new { error = "Developer not found" });

                // Auto-generate team name if not provided
                var teamName = dto.TeamName;
                if (string.IsNullOrWhiteSpace(teamName))
                {
                    var teamCount = await _context.SalesTeams
                        .Where(t => t.DeveloperId == targetDeveloperId)
                        .CountAsync();
                    teamName = $"Sales Team {teamCount + 1}";
                }

                var team = new SalesTeam
                {
                    TeamName = teamName,
                    DeveloperId = targetDeveloperId,
                    CreatedAt = DateTime.UtcNow
                };

                _context.SalesTeams.Add(team);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    team.TeamId,
                    team.TeamName,
                    DeveloperId = team.DeveloperId,
                    DeveloperName = $"{developer.FirstName} {developer.LastName}",
                    team.CreatedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/SalesTeam/{id} - Update team
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateTeam(Guid id, [FromBody] UpdateTeamDto dto)
        {
            try
            {
                var currentAccountId = GetCurrentAccountId();
                if (!currentAccountId.HasValue)
                    return Unauthorized();

                var currentAccount = await _context.Accounts
                    .Include(a => a.Role)
                    .FirstOrDefaultAsync(a => a.AccountId == currentAccountId.Value);

                if (currentAccount == null)
                    return Unauthorized();

                var team = await _context.SalesTeams
                    .Include(t => t.Developer)
                    .FirstOrDefaultAsync(t => t.TeamId == id);

                if (team == null)
                    return NotFound(new { error = "Team not found" });

                // Check authorization: developer can only update their own teams
                if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID && team.DeveloperId != currentAccountId.Value)
                {
                    return Forbid("You can only update your own teams");
                }

                if (!string.IsNullOrWhiteSpace(dto.TeamName))
                {
                    team.TeamName = dto.TeamName;
                }

                if (dto.DeveloperId.HasValue)
                {
                    // Only admin can change developer
                    if (currentAccount.RoleId != Role.ADMIN_ROLE_ID)
                    {
                        return Forbid();
                    }

                    var developer = await _context.Accounts
                        .FirstOrDefaultAsync(a => a.AccountId == dto.DeveloperId.Value && a.RoleId == Role.DEVELOPER_ROLE_ID);

                    if (developer == null)
                        return BadRequest(new { error = "Developer not found" });

                    team.DeveloperId = dto.DeveloperId.Value;
                }

                team.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    team.TeamId,
                    team.TeamName,
                    DeveloperId = team.DeveloperId,
                    DeveloperName = $"{team.Developer.FirstName} {team.Developer.LastName}",
                    team.UpdatedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/SalesTeam/{id} - Delete team
        [HttpDelete("{id}")]
        [AdminAuthorize]
        public async Task<IActionResult> DeleteTeam(Guid id)
        {
            try
            {
                var team = await _context.SalesTeams
                    .Include(t => t.SalesMembers)
                    .FirstOrDefaultAsync(t => t.TeamId == id);

                if (team == null)
                    return NotFound(new { error = "Team not found" });

                // Remove team assignment from members (set to null)
                foreach (var member in team.SalesMembers)
                {
                    member.SalesTeamId = null;
                }

                _context.SalesTeams.Remove(team);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Team deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    // DTOs
    public class CreateTeamDto
    {
        public string? TeamName { get; set; }
        public Guid DeveloperId { get; set; }
    }

    public class UpdateTeamDto
    {
        public string? TeamName { get; set; }
        public Guid? DeveloperId { get; set; }
    }
}




