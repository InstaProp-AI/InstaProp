using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using InstapropAPI.Extensions;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CommunityController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CommunityController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/community
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CommunityResponseDto>>> GetCommunities()
        {
            var accountId = GetCurrentAccountId();
            
            var communities = await _context.Communities
                .Where(c => c.IsActive)
                .Include(c => c.Members)
                .ToListAsync();

            // Get actual counts from database
            var communityIds = communities.Select(c => c.CommunityId).ToList();
            
            var memberCounts = await _context.CommunityMembers
                .Where(m => communityIds.Contains(m.CommunityId))
                .GroupBy(m => m.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var postCounts = await _context.CommunityPosts
                .Where(p => communityIds.Contains(p.CommunityId))
                .GroupBy(p => p.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var result = new List<CommunityResponseDto>();

            foreach (var community in communities)
            {
                // For public communities, always include
                if (community.AccessType == CommunityAccessType.PublicAll)
                {
                    var isJoined = accountId.HasValue && community.Members.Any(m => m.AccountId == accountId.Value);
                    var userMember = accountId.HasValue 
                        ? community.Members.FirstOrDefault(m => m.AccountId == accountId.Value) 
                        : null;

                    result.Add(new CommunityResponseDto
                    {
                        CommunityId = community.CommunityId,
                        Name = community.Name,
                        Description = community.Description,
                        ScopeType = community.ScopeType,
                        AccessType = community.AccessType,
                        ProjectIds = ParseJsonArray<long>(community.ProjectIds),
                        DeveloperIds = ParseJsonArray<long>(community.DeveloperIds),
                        CoverPhotoUrl = community.CoverPhotoUrl,
                        MemberCount = memberCounts.GetValueOrDefault(community.CommunityId, 0),
                        PostCount = postCounts.GetValueOrDefault(community.CommunityId, 0),
                        CreatedAt = community.CreatedAt,
                        IsJoined = isJoined,
                        CanJoin = !isJoined,
                        IsLocked = false,
                        UserRole = userMember?.Role
                    });
                }
                else if (accountId.HasValue)
                {
                    // For private communities, check access
                    var canAccess = await CanAccessCommunity(accountId.Value, community);
                    var isJoined = community.Members.Any(m => m.AccountId == accountId.Value);
                    var userMember = community.Members.FirstOrDefault(m => m.AccountId == accountId.Value);

                    if (canAccess)
                    {
                        // User has access - show full details
                        result.Add(new CommunityResponseDto
                        {
                            CommunityId = community.CommunityId,
                            Name = community.Name,
                            Description = community.Description,
                            ScopeType = community.ScopeType,
                            AccessType = community.AccessType,
                            ProjectIds = ParseJsonArray<long>(community.ProjectIds),
                            DeveloperIds = ParseJsonArray<long>(community.DeveloperIds),
                            CoverPhotoUrl = community.CoverPhotoUrl,
                            MemberCount = memberCounts.GetValueOrDefault(community.CommunityId, 0),
                            PostCount = postCounts.GetValueOrDefault(community.CommunityId, 0),
                            CreatedAt = community.CreatedAt,
                            IsJoined = isJoined,
                            CanJoin = !isJoined,
                            IsLocked = false,
                            UserRole = userMember?.Role
                        });
                    }
                    else
                    {
                        // User doesn't have access - show as locked (limited info)
                        result.Add(new CommunityResponseDto
                        {
                            CommunityId = community.CommunityId,
                            Name = community.Name,
                            Description = community.Description,
                            ScopeType = community.ScopeType,
                            AccessType = community.AccessType,
                            ProjectIds = ParseJsonArray<long>(community.ProjectIds),
                            DeveloperIds = ParseJsonArray<long>(community.DeveloperIds),
                            CoverPhotoUrl = community.CoverPhotoUrl,
                            MemberCount = 0,
                            PostCount = 0,
                            CreatedAt = community.CreatedAt,
                            IsJoined = false,
                            CanJoin = false,
                            IsLocked = true,
                            UserRole = null
                        });
                    }
                }
            }

            return Ok(result);
        }

        // GET: api/community/my
        [HttpGet("my")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<CommunityResponseDto>>> GetMyCommunities()
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var communities = await _context.Communities
                .Include(c => c.Members)
                .Where(c => c.IsActive && c.Members.Any(m => m.AccountId == accountId.Value))
                .ToListAsync();

            // Get actual counts from database
            var communityIds = communities.Select(c => c.CommunityId).ToList();
            
            var memberCounts = await _context.CommunityMembers
                .Where(m => communityIds.Contains(m.CommunityId))
                .GroupBy(m => m.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var postCounts = await _context.CommunityPosts
                .Where(p => communityIds.Contains(p.CommunityId))
                .GroupBy(p => p.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var result = communities.Select(c =>
            {
                var member = c.Members.FirstOrDefault(m => m.AccountId == accountId.Value);
                return new CommunityResponseDto
                {
                    CommunityId = c.CommunityId,
                    Name = c.Name,
                    Description = c.Description,
                    ScopeType = c.ScopeType,
                    AccessType = c.AccessType,
                    ProjectIds = ParseJsonArray<long>(c.ProjectIds),
                    DeveloperIds = ParseJsonArray<long>(c.DeveloperIds),
                    CoverPhotoUrl = c.CoverPhotoUrl,
                    MemberCount = memberCounts.GetValueOrDefault(c.CommunityId, 0),
                    PostCount = postCounts.GetValueOrDefault(c.CommunityId, 0),
                    CreatedAt = c.CreatedAt,
                    IsJoined = true,
                    CanJoin = false,
                    IsLocked = false,
                    UserRole = member?.Role
                };
            }).ToList();

            return Ok(result);
        }

        // GET: api/community/recommended
        [HttpGet("recommended")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<CommunityResponseDto>>> GetRecommendedCommunities()
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            // Get user's properties
            var userProperties = await _context.ChildProperties
                .Where(p => p.OwnerId == accountId && p.IsApproved)
                .ToListAsync();

            var projectIds = userProperties.Select(p => p.ProjectId).Where(id => id.HasValue).Cast<long>().Distinct();
            var developerIds = userProperties
                .Where(p => p.ProjectId.HasValue)
                .Join(_context.Projects, p => p.ProjectId, pr => pr.ProjectId, (p, pr) => pr.DeveloperId)
                .Distinct()
                .ToList();

            // Find private communities for user's projects/developers
            var recommendedCommunities = await _context.Communities
                .Include(c => c.Members)
                .Where(c => c.IsActive && 
                            c.AccessType == CommunityAccessType.Private &&
                            !c.Members.Any(m => m.AccountId == accountId))
                .ToListAsync();

            // Get actual counts
            var communityIds = recommendedCommunities.Select(c => c.CommunityId).ToList();
            
            var memberCounts = await _context.CommunityMembers
                .Where(m => communityIds.Contains(m.CommunityId))
                .GroupBy(m => m.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var postCounts = await _context.CommunityPosts
                .Where(p => communityIds.Contains(p.CommunityId))
                .GroupBy(p => p.CommunityId)
                .Select(g => new { CommunityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.CommunityId, x => x.Count);

            var result = new List<CommunityResponseDto>();

            foreach (var community in recommendedCommunities)
            {
                var canAccess = await CanAccessCommunity(accountId.Value, community);
                if (canAccess)
                {
                    result.Add(new CommunityResponseDto
                    {
                        CommunityId = community.CommunityId,
                        Name = community.Name,
                        Description = community.Description,
                        ScopeType = community.ScopeType,
                        AccessType = community.AccessType,
                        ProjectIds = ParseJsonArray<long>(community.ProjectIds),
                        DeveloperIds = ParseJsonArray<long>(community.DeveloperIds),
                        CoverPhotoUrl = community.CoverPhotoUrl,
                        MemberCount = memberCounts.GetValueOrDefault(community.CommunityId, 0),
                        PostCount = postCounts.GetValueOrDefault(community.CommunityId, 0),
                        CreatedAt = community.CreatedAt,
                        IsJoined = false,
                        CanJoin = true,
                        IsLocked = false,
                        UserRole = null
                    });
                }
            }

            return Ok(result);
        }

        // GET: api/community/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<CommunityResponseDto>> GetCommunity(long id)
        {
            var accountId = GetCurrentAccountId();

            var community = await _context.Communities
                .Include(c => c.Members)
                .FirstOrDefaultAsync(c => c.CommunityId == id);

            if (community == null || !community.IsActive)
                return NotFound();

            var canAccess = accountId.HasValue && await CanAccessCommunity(accountId.Value, community);
            if (!canAccess && community.AccessType != CommunityAccessType.PublicAll)
                return Forbid();

            var isJoined = accountId.HasValue && community.Members.Any(m => m.AccountId == accountId.Value);
            var userMember = accountId.HasValue 
                ? community.Members.FirstOrDefault(m => m.AccountId == accountId.Value) 
                : null;

            // Get actual counts
            var memberCount = await _context.CommunityMembers
                .CountAsync(m => m.CommunityId == community.CommunityId);
            
            var postCount = await _context.CommunityPosts
                .CountAsync(p => p.CommunityId == community.CommunityId);

            return Ok(new CommunityResponseDto
            {
                CommunityId = community.CommunityId,
                Name = community.Name,
                Description = community.Description,
                ScopeType = community.ScopeType,
                AccessType = community.AccessType,
                ProjectIds = ParseJsonArray<long>(community.ProjectIds),
                DeveloperIds = ParseJsonArray<long>(community.DeveloperIds),
                CoverPhotoUrl = community.CoverPhotoUrl,
                MemberCount = memberCount,
                PostCount = postCount,
                CreatedAt = community.CreatedAt,
                IsJoined = isJoined,
                CanJoin = canAccess && !isJoined,
                IsLocked = false,
                UserRole = userMember?.Role
            });
        }

        // POST: api/community
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Community>> CreateCommunity([FromBody] CreateCommunityDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            // SECURITY: Only admins and developers can create communities - check RoleId
            if (!account.IsDeveloperOrAdmin())
                return Forbid();

            var community = new Community
            {
                Name = dto.Name,
                Description = dto.Description,
                CreatedById = accountId.Value,
                ScopeType = dto.ScopeType,
                AccessType = dto.AccessType,
                ProjectIds = dto.ProjectIds != null ? JsonSerializer.Serialize(dto.ProjectIds) : null,
                DeveloperIds = dto.DeveloperIds != null ? JsonSerializer.Serialize(dto.DeveloperIds) : null,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Communities.Add(community);
            await _context.SaveChangesAsync();

            // Add creator as member with Creator role
            _context.CommunityMembers.Add(new CommunityMember
            {
                CommunityId = community.CommunityId,
                AccountId = accountId.Value,
                Role = CommunityMemberRole.Creator,
                JoinedAt = DateTime.UtcNow
            });

            community.MemberCount = 1;
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCommunity), new { id = community.CommunityId }, community);
        }

        // POST: api/community/{id}/join
        [HttpPost("{id}/join")]
        [Authorize]
        public async Task<IActionResult> JoinCommunity(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var community = await _context.Communities
                .Include(c => c.Members)
                .FirstOrDefaultAsync(c => c.CommunityId == id);

            if (community == null || !community.IsActive)
                return NotFound();

            // Check if already a member
            if (community.Members.Any(m => m.AccountId == accountId.Value))
                return Conflict("Already a member");

            // Check if user can access
            var canAccess = await CanAccessCommunity(accountId.Value, community);
            if (!canAccess && community.AccessType != CommunityAccessType.PublicAll)
                return Forbid("Cannot join this community");

            _context.CommunityMembers.Add(new CommunityMember
            {
                CommunityId = community.CommunityId,
                AccountId = accountId.Value,
                Role = CommunityMemberRole.Member,
                JoinedAt = DateTime.UtcNow
            });

            community.MemberCount++;
            await _context.SaveChangesAsync();

            return Ok();
        }

        // DELETE: api/community/{id}/leave
        [HttpDelete("{id}/leave")]
        [Authorize]
        public async Task<IActionResult> LeaveCommunity(long id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var member = await _context.CommunityMembers
                .FirstOrDefaultAsync(m => m.CommunityId == id && m.AccountId == accountId.Value);

            if (member == null)
                return NotFound("Not a member of this community");

            // Creator cannot leave
            if (member.Role == CommunityMemberRole.Creator)
                return BadRequest("Creator cannot leave community");

            _context.CommunityMembers.Remove(member);

            var community = await _context.Communities.FindAsync(id);
            if (community != null)
            {
                community.MemberCount--;
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

        // GET: api/community/{id}/members
        [HttpGet("{id}/members")]
        public async Task<ActionResult<IEnumerable<object>>> GetCommunityMembers(long id)
        {
            var community = await _context.Communities.FindAsync(id);
            if (community == null || !community.IsActive)
                return NotFound();

            var accountId = GetCurrentAccountId();
            var canAccess = accountId.HasValue && await CanAccessCommunity(accountId.Value, community);
            
            if (!canAccess && community.AccessType != CommunityAccessType.PublicAll)
                return Forbid();

            var members = await _context.CommunityMembers
                .Include(m => m.Account)
                .Where(m => m.CommunityId == id)
                .OrderByDescending(m => m.Role == CommunityMemberRole.Creator)
                .ThenByDescending(m => m.Role == CommunityMemberRole.Moderator)
                .ThenByDescending(m => m.JoinedAt)
                .Take(50)
                .Select(m => new
                {
                    m.AccountId,
                    FirstName = m.Account.FirstName,
                    LastName = m.Account.LastName,
                    ImageUrl = (string?)null, // Profile images not currently implemented
                    m.Role,
                    m.JoinedAt
                })
                .ToListAsync();

            return Ok(members);
        }

        // GET: api/community/{id}/stats
        [HttpGet("{id}/stats")]
        public async Task<ActionResult<object>> GetCommunityStats(long id)
        {
            var community = await _context.Communities.FindAsync(id);
            if (community == null || !community.IsActive)
                return NotFound();

            var accountId = GetCurrentAccountId();
            var canAccess = accountId.HasValue && await CanAccessCommunity(accountId.Value, community);
            
            if (!canAccess && community.AccessType != CommunityAccessType.PublicAll)
                return Forbid();

            // Get actual counts
            var memberCount = await _context.CommunityMembers
                .CountAsync(m => m.CommunityId == id);
            
            var postCount = await _context.CommunityPosts
                .CountAsync(p => p.CommunityId == id);

            // Get member count for this month
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            var newMembersThisMonth = await _context.CommunityMembers
                .CountAsync(m => m.CommunityId == id && m.JoinedAt >= startOfMonth);

            // Get active members (posted or commented this month)
            var activeMemberIds = await _context.CommunityPosts
                .Where(p => p.CommunityId == id && p.CreatedAt >= startOfMonth)
                .Select(p => p.AuthorId)
                .Union(
                    _context.PostComments
                        .Include(c => c.Post)
                        .Where(c => c.Post.CommunityId == id && c.CreatedAt >= startOfMonth)
                        .Select(c => c.AuthorId)
                )
                .Distinct()
                .CountAsync();

            var activityRate = memberCount > 0 
                ? Math.Round((double)activeMemberIds / memberCount * 100, 1) 
                : 0.0;

            // Get property stats for project-based communities
            int? propertyCount = null;
            decimal? totalPropertyValue = null;
            decimal? averagePropertyValue = null;

            if (community.ScopeType == CommunityScopeType.ProjectBased && !string.IsNullOrEmpty(community.ProjectIds))
            {
                var projectIds = ParseJsonArray<long>(community.ProjectIds);
                propertyCount = await _context.ChildProperties
                    .CountAsync(p => p.ProjectId.HasValue && projectIds.Contains((long)p.ProjectId));

                if (propertyCount > 0)
                {
                    var properties = await _context.ChildProperties
                        .Where(p => p.ProjectId.HasValue && projectIds.Contains((long)p.ProjectId))
                        .ToListAsync();
                    
                    totalPropertyValue = properties.Sum(p => p.BuyingPrice);
                    averagePropertyValue = properties.Average(p => p.BuyingPrice);
                }
            }

            return Ok(new
            {
                MemberCount = memberCount,
                PostCount = postCount,
                NewMembersThisMonth = newMembersThisMonth,
                ActiveMemberCount = activeMemberIds,
                ActivityRate = activityRate,
                PropertyCount = propertyCount,
                TotalPropertyValue = totalPropertyValue,
                AveragePropertyValue = averagePropertyValue
            });
        }

        // Helper Methods
        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
                return accountId;
            return null;
        }

        private async Task<bool> CanAccessCommunity(long accountId, Community community)
        {
            // Check access based on AccessType
            if (community.AccessType == CommunityAccessType.PublicAll)
                return true;

            if (community.AccessType == CommunityAccessType.PublicOwners)
            {
                var hasApprovedProperty = await _context.ChildProperties
                    .AnyAsync(p => p.OwnerId == accountId && p.IsApproved);
                return hasApprovedProperty;
            }

            // Private access - check scope
            if (community.AccessType == CommunityAccessType.Private)
            {
                if (community.ScopeType == CommunityScopeType.ProjectBased)
                {
                    var projectIds = ParseJsonArray<long>(community.ProjectIds);
                    var hasPropertyInProject = await _context.ChildProperties
                        .AnyAsync(p => p.OwnerId == accountId && p.IsApproved && 
                                      p.ProjectId.HasValue && projectIds.Contains((long)p.ProjectId));
                    return hasPropertyInProject;
                }
                else if (community.ScopeType == CommunityScopeType.DeveloperBased)
                {
                    var developerIds = ParseJsonArray<long>(community.DeveloperIds);
                    var hasPropertyFromDeveloper = await _context.ChildProperties
                        .Join(_context.Projects, p => p.ProjectId, pr => pr.ProjectId, (p, pr) => new { p, pr })
                        .AnyAsync(x => x.p.OwnerId == accountId && x.p.IsApproved && developerIds.Contains(x.pr.DeveloperId));
                    return hasPropertyFromDeveloper;
                }
            }

            return false;
        }

        private List<T> ParseJsonArray<T>(string? json)
        {
            if (string.IsNullOrEmpty(json))
                return new List<T>();
            
            try
            {
                return JsonSerializer.Deserialize<List<T>>(json) ?? new List<T>();
            }
            catch
            {
                return new List<T>();
            }
        }
    }
}

