using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System.Security.Claims;
using PropertyFlipperAPI.Attributes;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProjectController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProjectController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/project
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<IEnumerable<Project>>> GetProjects()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
            {
                return Unauthorized("User not found");
            }

            // Allow both Developers and Admins to access projects
            if (account.Type != Models.AccountType.Developer && account.Type != Models.AccountType.Admin)
            {
                return StatusCode(403, new { message = "Only developers and admins can access projects" });
            }

            // Admins can see all projects, developers can only see their own
            var projects = account.Type == Models.AccountType.Admin
                ? await _context.Projects.ToListAsync()
                : await _context.Projects
                    .Where(p => p.DeveloperId == accountId)
                    .ToListAsync();

            return Ok(projects);
        }

        // GET: api/project/{id}
        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<Project>> GetProject(long id)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
            {
                return Unauthorized("User not found");
            }

            // Admins can access any project, developers can only access their own
            var project = account.Type == Models.AccountType.Admin
                ? await _context.Projects
                    .FirstOrDefaultAsync(p => p.ProjectId == id)
                : await _context.Projects
                    .FirstOrDefaultAsync(p => p.ProjectId == id && p.DeveloperId == accountId);

            if (project == null)
            {
                return NotFound("Project not found");
            }

            return Ok(project);
        }

        // POST: api/project
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Project>> CreateProject([FromBody] CreateProjectDto projectDto)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
            {
                return Unauthorized("User not found");
            }

            // Allow both Developers and Admins to create projects
            if (account.Type != Models.AccountType.Developer && account.Type != Models.AccountType.Admin)
            {
                return StatusCode(403, new { message = "Only developers and admins can create projects" });
            }

            var project = new Project
            {
                DeveloperId = accountId,
                Name = projectDto.Name,
                Description = projectDto.Description,
                Location = projectDto.Location,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Projects.Add(project);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProject), new { id = project.ProjectId }, project);
        }

        // PUT: api/project/{id}
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateProject(long id, [FromBody] UpdateProjectDto projectDto)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
            {
                return Unauthorized("User not found");
            }

            // Admins can update any project, developers can only update their own
            var project = account.Type == Models.AccountType.Admin
                ? await _context.Projects.FirstOrDefaultAsync(p => p.ProjectId == id)
                : await _context.Projects
                    .FirstOrDefaultAsync(p => p.ProjectId == id && p.DeveloperId == accountId);

            if (project == null)
            {
                return NotFound("Project not found");
            }

            project.Name = projectDto.Name;
            project.Description = projectDto.Description;
            project.Location = projectDto.Location;
            project.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/project/{id}
        [HttpDelete("{id}")]
        [AdminAuthorize]
        public async Task<IActionResult> DeleteProject(long id)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            // Admins can delete any project
            var project = await _context.Projects.FirstOrDefaultAsync(p => p.ProjectId == id);

            if (project == null)
            {
                return NotFound("Project not found");
            }

            _context.Projects.Remove(project);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/project/{id}/properties
        [HttpGet("{id}/properties")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<ChildProperty>>> GetProjectProperties(long id)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
            {
                return Unauthorized("User not found");
            }

            // Admins can view properties of any project, developers can only view their own
            var project = account.Type == Models.AccountType.Admin
                ? await _context.Projects.FirstOrDefaultAsync(p => p.ProjectId == id)
                : await _context.Projects
                    .FirstOrDefaultAsync(p => p.ProjectId == id && p.DeveloperId == accountId);

            if (project == null)
            {
                return NotFound("Project not found");
            }

            var properties = await _context.ChildProperties
                .Where(p => p.ProjectId == id)
                .Include(p => p.Owner)
                .ToListAsync();

            return Ok(properties);
        }

        // GET: api/project/public - Get all active projects (Public endpoint for Flutter)
        [HttpGet("public")]
        public async Task<ActionResult<IEnumerable<PublicProjectDto>>> GetPublicProjects()
        {
            var projects = await _context.Projects
                .Where(p => p.IsActive)
                .Include(p => p.Developer)
                .ToListAsync();

            var developerIds = projects.Select(p => p.DeveloperId).Distinct().ToList();
            var developerProfiles = await _context.DeveloperProfiles
                .Where(dp => developerIds.Contains(dp.AccountId))
                .ToListAsync();

            var publicProjects = new List<PublicProjectDto>();
            foreach (var p in projects)
            {
                var profile = developerProfiles.FirstOrDefault(dp => dp.AccountId == p.DeveloperId);
                var featuredProperty = await _context.ChildProperties
                    .Where(cp => cp.ProjectId == p.ProjectId)
                    .FirstOrDefaultAsync();
                
                var propertiesCount = await _context.ChildProperties
                    .Where(cp => cp.ProjectId == p.ProjectId)
                    .CountAsync();

                publicProjects.Add(new PublicProjectDto
                {
                    ProjectId = p.ProjectId,
                    Name = p.Name,
                    Description = p.Description,
                    Location = p.Location,
                    CreatedAt = p.CreatedAt,
                    PropertiesCount = propertiesCount,
                    FeaturedImageUrl = featuredProperty?.ImageUrl,
                    DeveloperId = p.DeveloperId,
                    DeveloperName = profile?.CompanyName ?? "Unknown Developer",
                    DeveloperCompany = profile?.CompanyName,
                    DeveloperRating = profile?.Rating ?? 0,
                    DeveloperProfileImage = profile?.ProfileImageUrl
                });
            }

            return Ok(publicProjects);
        }

        // GET: api/project/public/{id} - Get project details (Public endpoint)
        [HttpGet("public/{id}")]
        public async Task<ActionResult<PublicProjectDetailsDto>> GetPublicProjectDetails(long id)
        {
            var project = await _context.Projects
                .Include(p => p.Developer)
                .FirstOrDefaultAsync(p => p.ProjectId == id && p.IsActive);

            if (project == null)
                return NotFound("Project not found");

            var profile = await _context.DeveloperProfiles
                .FirstOrDefaultAsync(dp => dp.AccountId == project.DeveloperId);

            var projectDetails = new PublicProjectDetailsDto
            {
                ProjectId = project.ProjectId,
                Name = project.Name,
                Description = project.Description,
                Location = project.Location,
                CreatedAt = project.CreatedAt,
                DeveloperId = project.DeveloperId,
                DeveloperName = profile?.CompanyName ?? "Unknown Developer",
                DeveloperCompany = profile?.CompanyName,
                DeveloperRating = profile?.Rating ?? 0,
                DeveloperProfileImage = profile?.ProfileImageUrl,
                DeveloperBio = profile?.Bio,
                Properties = _context.ChildProperties.Where(cp => cp.ProjectId == project.ProjectId).Select(p => new PublicPropertyDto
                {
                    PropertyId = p.PropertyId,
                    Name = p.Name,
                    Description = p.Description,
                    Location = p.Location,
                    Bedrooms = p.Bedrooms,
                    Bathrooms = p.Bathrooms,
                    SquareFeet = p.SquareFeet,
                    Type = PropertyTypeHelper.ToDisplayName(p.Type),
                    ImageUrl = p.ImageUrl,
                    Images = new List<string>(), // TODO: Get images from ChildProperty
                    HasActiveAuction = p.Auctions.Any(a => a.Status == "Active"),
                    AuctionPrice = p.Auctions.FirstOrDefault(a => a.Status == "Active") != null ? p.Auctions.FirstOrDefault(a => a.Status == "Active").CurrentPrice : 0
                }).ToList()
            };

            return Ok(projectDetails);
        }

        // GET: api/project/by-developer/{developerId} - Get projects by developer (Public endpoint)
        [HttpGet("by-developer/{developerId}")]
        public async Task<ActionResult<IEnumerable<PublicProjectDto>>> GetProjectsByDeveloper(long developerId)
        {
            var projects = await _context.Projects
                .Where(p => p.DeveloperId == developerId && p.IsActive)
                .Include(p => p.Developer)
                .ToListAsync();

            var profile = await _context.DeveloperProfiles
                .FirstOrDefaultAsync(dp => dp.AccountId == developerId);

            var publicProjects = new List<PublicProjectDto>();
            foreach (var p in projects)
            {
                var featuredProperty = await _context.ChildProperties
                    .Where(cp => cp.ProjectId == p.ProjectId)
                    .FirstOrDefaultAsync();
                
                var propertiesCount = await _context.ChildProperties
                    .Where(cp => cp.ProjectId == p.ProjectId)
                    .CountAsync();

                publicProjects.Add(new PublicProjectDto
                {
                    ProjectId = p.ProjectId,
                    Name = p.Name,
                    Description = p.Description,
                    Location = p.Location,
                    CreatedAt = p.CreatedAt,
                    PropertiesCount = propertiesCount,
                    FeaturedImageUrl = featuredProperty?.ImageUrl,
                    DeveloperId = p.DeveloperId,
                    DeveloperName = profile?.CompanyName ?? "Unknown Developer",
                    DeveloperCompany = profile?.CompanyName,
                    DeveloperRating = profile?.Rating ?? 0,
                    DeveloperProfileImage = profile?.ProfileImageUrl
                });
            }

            return Ok(publicProjects);
        }
    }

    public class CreateProjectDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
    }

    public class UpdateProjectDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
    }

    public class PublicProjectDto
    {
        public long ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
        public DateTime CreatedAt { get; set; }
        public int PropertiesCount { get; set; }
        public string? FeaturedImageUrl { get; set; }
        public long DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public string? DeveloperCompany { get; set; }
        public decimal DeveloperRating { get; set; }
        public string? DeveloperProfileImage { get; set; }
    }

    public class PublicProjectDetailsDto
    {
        public long ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
        public DateTime CreatedAt { get; set; }
        public long DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public string? DeveloperCompany { get; set; }
        public decimal DeveloperRating { get; set; }
        public string? DeveloperProfileImage { get; set; }
        public string? DeveloperBio { get; set; }
        public List<PublicPropertyDto> Properties { get; set; } = new();
    }

    public class PublicPropertyDto
    {
        public long PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Location { get; set; }
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public string? Type { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public List<string> Images { get; set; } = new();
        public bool HasActiveAuction { get; set; }
        public decimal? AuctionPrice { get; set; }
    }
}

