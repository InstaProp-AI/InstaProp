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
            if (account == null || account.Type != Models.AccountType.Developer)
            {
                return Forbid("Only developers can access projects");
            }

            var projects = await _context.Projects
                .Where(p => p.DeveloperId == accountId)
                .Include(p => p.Properties)
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

            var project = await _context.Projects
                .Include(p => p.Properties)
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
            if (account == null || account.Type != Models.AccountType.Developer)
            {
                return Forbid("Only developers can create projects");
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

            var project = await _context.Projects
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

            var project = await _context.Projects
                .FirstOrDefaultAsync(p => p.ProjectId == id && p.DeveloperId == accountId);

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
        public async Task<ActionResult<IEnumerable<Property>>> GetProjectProperties(long id)
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim == null || !long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return Unauthorized("User not authenticated");
            }

            var project = await _context.Projects
                .FirstOrDefaultAsync(p => p.ProjectId == id && p.DeveloperId == accountId);

            if (project == null)
            {
                return NotFound("Project not found");
            }

            var properties = await _context.Properties
                .Where(p => p.ProjectId == id)
                .Include(p => p.Owner)
                .ToListAsync();

            return Ok(properties);
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
}

