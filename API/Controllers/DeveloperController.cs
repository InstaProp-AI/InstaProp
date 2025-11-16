using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using System.Linq;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DeveloperController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ImgBBService _imgBBService;

        public DeveloperController(AppDbContext context, ImgBBService imgBBService)
        {
            _context = context;
            _imgBBService = imgBBService;
        }

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return accountId;
            }
            return null;
        }

        // GET: api/developer/profile/{developerId} - Get developer profile (Public)
        [HttpGet("profile/{developerId}")]
        public async Task<ActionResult<DeveloperProfileDto>> GetDeveloperProfile(long developerId)
        {
            var developer = await _context.Accounts
                .FirstOrDefaultAsync(a => a.AccountId == developerId && a.Type == AccountType.Developer);

            if (developer == null)
                return NotFound("Developer not found");

            var profile = await _context.DeveloperProfiles
                .FirstOrDefaultAsync(p => p.AccountId == developerId);

            var projects = await _context.Projects
                .Where(p => p.DeveloperId == developerId && p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var projectIds = projects.Select(p => p.ProjectId).ToList();
            var projectIdSet = new HashSet<long>(projectIds);

            var propertyQueryable = _context.ChildProperties
                .Where(cp =>
                    (cp.ProjectId.HasValue && projectIdSet.Contains(cp.ProjectId.Value)) ||
                    cp.OwnerId == developerId);

            var totalProperties = await propertyQueryable
                .Select(cp => cp.PropertyId)
                .Distinct()
                .CountAsync();

            var soldProperties = await propertyQueryable
                .Where(cp => cp.Auctions.Any(a => a.Status == "Sold"))
                .Select(cp => cp.PropertyId)
                .Distinct()
                .CountAsync();

            var latestPropertiesRaw = await propertyQueryable
                .OrderByDescending(cp => cp.CreatedAt)
                .Select(cp => new PropertySummaryDto
                {
                    PropertyId = cp.PropertyId,
                    ProjectId = cp.ProjectId,
                    Name = cp.Name,
                    Location = cp.Location,
                    ImageUrl = cp.ImageUrl ?? string.Empty,
                    Status = cp.Status.ToString(),
                    Type = cp.Type.ToDisplayName(),
                    Bedrooms = cp.Bedrooms,
                    Bathrooms = cp.Bathrooms,
                    SquareFeet = cp.SquareFeet
                })
                .Take(100)
                .ToListAsync();

            var propertySummaries = latestPropertiesRaw
                .DistinctBy(p => p.PropertyId)
                .Take(20)
                .ToList();

            var projectPropertyCounts = await _context.ChildProperties
                .Where(cp => cp.ProjectId.HasValue && projectIdSet.Contains(cp.ProjectId.Value))
                .GroupBy(cp => cp.ProjectId!.Value)
                .Select(g => new { ProjectId = g.Key, Count = g.Count() })
                .ToListAsync();

            var projectCoverImages = await _context.ChildProperties
                .Where(cp => cp.ProjectId.HasValue && projectIdSet.Contains(cp.ProjectId.Value) && !string.IsNullOrEmpty(cp.ImageUrl))
                .GroupBy(cp => cp.ProjectId!.Value)
                .Select(g => new
                {
                    ProjectId = g.Key,
                    ImageUrl = g
                        .OrderByDescending(cp => cp.CreatedAt)
                        .Select(cp => cp.ImageUrl)
                        .FirstOrDefault()
                })
                .ToListAsync();

            var propertyCountLookup = projectPropertyCounts.ToDictionary(x => x.ProjectId, x => x.Count);
            var projectCoverLookup = projectCoverImages
                .Where(x => !string.IsNullOrEmpty(x.ImageUrl))
                .ToDictionary(x => x.ProjectId, x => x.ImageUrl!);

            var projectSummaries = projects.Select(p => new ProjectSummaryDto
            {
                ProjectId = p.ProjectId,
                Name = p.Name,
                Location = p.Location,
                PropertiesCount = propertyCountLookup.TryGetValue(p.ProjectId, out var count) ? count : 0,
                CoverImageUrl = projectCoverLookup.TryGetValue(p.ProjectId, out var cover) ? cover : null,
                CreatedAt = p.CreatedAt
            }).ToList();

            var ratings = await _context.DeveloperRatings
                .Where(r => r.DeveloperId == developerId)
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(new DeveloperProfileDto
            {
                DeveloperId = developer.AccountId,
                FirstName = profile?.CompanyName ?? "Unknown Developer",
                LastName = "",
                Email = developer.Email,
                PhoneNumber = developer.PhoneNumber,
                Bio = profile?.Bio,
                CompanyName = profile?.CompanyName,
                ProfileImageUrl = profile?.ProfileImageUrl,
                Rating = profile?.Rating ?? 0,
                TotalRatings = profile?.TotalRatings ?? 0,
                PortfolioDescription = profile?.PortfolioDescription,
                ActiveProjectsCount = projectSummaries.Count,
                TotalPropertiesCount = totalProperties,
                SoldPropertiesCount = soldProperties,
                Projects = projectSummaries,
                Properties = propertySummaries,
                Ratings = ratings.Select(r => new DeveloperRatingDto
                {
                    RatingId = r.RatingId,
                    UserId = r.UserId,
                    UserName = $"{r.User.FirstName} {r.User.LastName}",
                    Rating = r.Rating,
                    Comment = r.Comment,
                    RatingType = r.RatingType.ToString(),
                    CreatedAt = r.CreatedAt
                }).ToList()
            });
        }

        // PUT: api/developer/profile - Update own profile (Developers only)
        [HttpPut("profile")]
        [Authorize]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateDeveloperProfileDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.Type != AccountType.Developer)
                return Forbid("Only developers can update developer profiles");

            var profile = await _context.DeveloperProfiles
                .FirstOrDefaultAsync(p => p.AccountId == accountId.Value);

            if (profile == null)
            {
                // Create new profile
                profile = new DeveloperProfile
                {
                    AccountId = accountId.Value,
                    CreatedAt = DateTime.UtcNow
                };
                _context.DeveloperProfiles.Add(profile);
            }

            profile.Bio = dto.Bio;
            profile.CompanyName = dto.CompanyName;
            profile.ProfileImageUrl = dto.ProfileImageUrl;
            profile.PortfolioDescription = dto.PortfolioDescription;
            profile.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/developer/analytics - Get developer analytics (Own data)
        [HttpGet("analytics")]
        [Authorize]
        public async Task<ActionResult<DeveloperAnalyticsDto>> GetAnalytics()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.Type != AccountType.Developer)
                return Forbid("Only developers can view analytics");

            var projects = await _context.Projects
                .Where(p => p.DeveloperId == accountId.Value)
                .ToListAsync();

            var properties = await _context.ChildProperties
                .Where(cp => projects.Select(p => p.ProjectId).Contains(cp.ProjectId.Value))
                .ToListAsync();
            var auctions = properties.SelectMany(p => p.Auctions).ToList();
            
            var activeAuctions = auctions.Count(a => a.Status == "Active");
            var totalBids = await _context.Bids
                .Where(b => properties.Select(p => p.PropertyId).Contains(b.Auction.PropertyId))
                .CountAsync();

            var soldProperties = properties.Count(p => p.Auctions.Any(a => a.Status == "Sold"));
            var totalRevenue = auctions.Where(a => a.Status == "Sold").Sum(a => a.CurrentPrice);

            var chats = await _context.Chats
                .Where(c => c.DeveloperId == accountId.Value)
                .ToListAsync();

            var chatInquiries = chats.Count;
            var chatConversionRate = chatInquiries > 0 
                ? Math.Round((double)soldProperties / chatInquiries * 100, 2) 
                : 0;

            // Property-level analytics
            var propertyAnalytics = properties.Select(p => new PropertyAnalyticsDto
            {
                PropertyId = p.PropertyId,
                PropertyName = p.Name,
                PropertyLocation = p.Location,
                Views = 0, // TODO: Implement view tracking
                ChatInquiries = chats.Count(c => c.Messages.Any(m => m.PropertyId == p.PropertyId)),
                TotalBids = p.Auctions.SelectMany(a => a.Bids).Count(),
                CurrentPrice = p.Auctions.FirstOrDefault(a => a.Status == "Active")?.CurrentPrice ?? 0,
                Status = p.Status.ToString()
            }).ToList();

            return Ok(new DeveloperAnalyticsDto
            {
                TotalProjects = projects.Count(),
                TotalProperties = properties.Count(),
                ActiveAuctions = activeAuctions,
                SoldProperties = soldProperties,
                TotalRevenue = totalRevenue,
                TotalBids = totalBids,
                ChatInquiries = chatInquiries,
                ChatConversionRate = chatConversionRate,
                PropertyAnalytics = propertyAnalytics
            });
        }

        // GET: api/developer/projects - Get developer's projects with properties
        [HttpGet("projects")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<ProjectWithPropertiesDto>>> GetProjects()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.Type != AccountType.Developer)
                return Forbid("Only developers can view their projects");

            // Return projects explicitly owned by developer OR any project that contains properties owned by the developer
            var projects = await _context.Projects
                .Where(p => p.DeveloperId == accountId.Value)
                .ToListAsync();

            var projectDtos = new List<ProjectWithPropertiesDto>();
            foreach (var p in projects)
            {
                var propertiesCount = await _context.ChildProperties.Where(cp => cp.ProjectId == p.ProjectId).CountAsync();
                var properties = await _context.ChildProperties.Where(cp => cp.ProjectId == p.ProjectId).Select(prop => new PropertySummaryDto
                {
                    PropertyId = prop.PropertyId,
                    ProjectId = prop.ProjectId,
                    Name = prop.Name,
                    Location = prop.Location,
                    ImageUrl = prop.ImageUrl ?? string.Empty,
                    Status = prop.Status.ToString(),
                    Type = prop.Type.ToDisplayName(),
                    Bedrooms = prop.Bedrooms,
                    Bathrooms = prop.Bathrooms,
                    SquareFeet = prop.SquareFeet
                }).ToListAsync();

                projectDtos.Add(new ProjectWithPropertiesDto
                {
                    ProjectId = p.ProjectId,
                    Name = p.Name,
                    Description = p.Description,
                    Location = p.Location,
                    CreatedAt = p.CreatedAt,
                    IsActive = p.IsActive,
                    PropertiesCount = propertiesCount,
                    Properties = properties
                });
            }

            return Ok(projectDtos);
        }

        // GET: api/developer/properties - Get all properties owned by the developer (including standalone)
        [HttpGet("properties")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<PropertySummaryDto>>> GetDeveloperProperties()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.Type != AccountType.Developer)
                return Forbid("Only developers can view their properties");

            var properties = await _context.ChildProperties
                .Where(p => p.OwnerId == accountId.Value)
                .Include(p => p.PropertyImages)
                .ToListAsync();

            var result = properties.Select(prop => new PropertySummaryDto
            {
                PropertyId = prop.PropertyId,
                ProjectId = prop.ProjectId,
                Name = prop.Name,
                Location = prop.Location,
                ImageUrl = prop.ImageUrl ?? string.Empty,
                Status = prop.Status.ToString(),
                Type = prop.Type.ToDisplayName(),
                Bedrooms = prop.Bedrooms,
                Bathrooms = prop.Bathrooms,
                SquareFeet = prop.SquareFeet
            }).ToList();

            return Ok(result);
        }

        // POST: api/developer/rating - Rate a developer
        [HttpPost("rating")]
        [Authorize]
        public async Task<ActionResult> RateDeveloper([FromBody] CreateRatingDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var developer = await _context.Accounts
                .FirstOrDefaultAsync(a => a.AccountId == dto.DeveloperId && a.Type == AccountType.Developer);

            if (developer == null)
                return NotFound("Developer not found");

            // Check if user already rated this developer
            var existingRating = await _context.DeveloperRatings
                .FirstOrDefaultAsync(r => r.DeveloperId == dto.DeveloperId && r.UserId == accountId.Value);

            if (existingRating != null)
                return BadRequest("You have already rated this developer");

            // Create rating
            var rating = new DeveloperRating
            {
                DeveloperId = dto.DeveloperId,
                UserId = accountId.Value,
                Rating = dto.Rating,
                Comment = dto.Comment,
                RatingType = dto.RatingType,
                CreatedAt = DateTime.UtcNow
            };

            _context.DeveloperRatings.Add(rating);

            // Update developer profile rating
            var profile = await _context.DeveloperProfiles
                .FirstOrDefaultAsync(p => p.AccountId == dto.DeveloperId);

            if (profile == null)
            {
                profile = new DeveloperProfile
                {
                    AccountId = dto.DeveloperId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.DeveloperProfiles.Add(profile);
            }

            // Recalculate average rating
            var allRatings = await _context.DeveloperRatings
                .Where(r => r.DeveloperId == dto.DeveloperId)
                .Select(r => r.Rating)
                .ToListAsync();

            allRatings.Add(dto.Rating);

            profile.Rating = (decimal)allRatings.Average();
            profile.TotalRatings = allRatings.Count;
            profile.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "Rating submitted successfully" });
        }

        // GET: api/developer/featured - Get featured developers
        [HttpGet("featured")]
        public async Task<ActionResult<IEnumerable<FeaturedDeveloperDto>>> GetFeaturedDevelopers()
        {
            var developers = await _context.Accounts
                .Where(a => a.Type == AccountType.Developer)
                .ToListAsync();

            var developerIds = developers.Select(d => d.AccountId).ToList();

            var profiles = await _context.DeveloperProfiles
                .Where(p => developerIds.Contains(p.AccountId))
                .ToListAsync();

            var projectCounts = await _context.Projects
                .Where(p => developerIds.Contains(p.DeveloperId) && p.IsActive)
                .GroupBy(p => p.DeveloperId)
                .Select(g => new { DeveloperId = g.Key, Count = g.Count() })
                .ToListAsync();

            var featuredDevelopers = developers
                .Select(d =>
                {
                    var profile = profiles.FirstOrDefault(p => p.AccountId == d.AccountId);
                    var projectCount = projectCounts.FirstOrDefault(pc => pc.DeveloperId == d.AccountId)?.Count ?? 0;

                    return new FeaturedDeveloperDto
                    {
                        DeveloperId = d.AccountId,
                        FirstName = profile?.CompanyName ?? "Unknown Developer",
                        LastName = "",
                        CompanyName = profile?.CompanyName,
                        ProfileImageUrl = profile?.ProfileImageUrl,
                        Rating = profile?.Rating ?? 0,
                        TotalRatings = profile?.TotalRatings ?? 0,
                        Bio = profile?.Bio,
                        ActiveProjectsCount = projectCount
                    };
                })
                .Where(d => d.ActiveProjectsCount > 0 || d.TotalRatings > 0)
                .OrderByDescending(d => d.Rating)
                .ThenByDescending(d => d.ActiveProjectsCount)
                .Take(10)
                .ToList();

            return Ok(featuredDevelopers);
        }
    }

    // DTOs
    public class DeveloperProfileDto
    {
        public long DeveloperId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? Bio { get; set; }
        public string? CompanyName { get; set; }
        public string? ProfileImageUrl { get; set; }
        public decimal Rating { get; set; }
        public int TotalRatings { get; set; }
        public string? PortfolioDescription { get; set; }
        public int ActiveProjectsCount { get; set; }
        public int TotalPropertiesCount { get; set; }
        public int SoldPropertiesCount { get; set; }
        public List<ProjectSummaryDto> Projects { get; set; } = new();
        public List<PropertySummaryDto> Properties { get; set; } = new();
        public List<DeveloperRatingDto> Ratings { get; set; } = new();
    }

    public class DeveloperRatingDto
    {
        public long RatingId { get; set; }
        public long UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public string RatingType { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class UpdateDeveloperProfileDto
    {
        public string? Bio { get; set; }
        public string? CompanyName { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? PortfolioDescription { get; set; }
    }

    public class DeveloperAnalyticsDto
    {
        public int TotalProjects { get; set; }
        public int TotalProperties { get; set; }
        public int ActiveAuctions { get; set; }
        public int SoldProperties { get; set; }
        public decimal TotalRevenue { get; set; }
        public int TotalBids { get; set; }
        public int ChatInquiries { get; set; }
        public double ChatConversionRate { get; set; }
        public List<PropertyAnalyticsDto> PropertyAnalytics { get; set; } = new();
    }

    public class PropertyAnalyticsDto
    {
        public long PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string? PropertyLocation { get; set; }
        public int Views { get; set; }
        public int ChatInquiries { get; set; }
        public int TotalBids { get; set; }
        public decimal CurrentPrice { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    public class ProjectWithPropertiesDto
    {
        public long ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
        public int PropertiesCount { get; set; }
        public List<PropertySummaryDto> Properties { get; set; } = new();
    }

    public class PropertySummaryDto
    {
        public long PropertyId { get; set; }
        public long? ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Location { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // Primary or Resale
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
    }

    public class CreateRatingDto
    {
        public long DeveloperId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public RatingType RatingType { get; set; }
    }

    public class FeaturedDeveloperDto
    {
        public long DeveloperId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? CompanyName { get; set; }
        public string? ProfileImageUrl { get; set; }
        public decimal Rating { get; set; }
        public int TotalRatings { get; set; }
        public string? Bio { get; set; }
        public int ActiveProjectsCount { get; set; }
    }

    public class ProjectSummaryDto
    {
        public long ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Location { get; set; }
        public int PropertiesCount { get; set; }
        public string? CoverImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

