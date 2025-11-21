using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Attributes;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Extensions;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DeveloperPermissionController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly DeveloperPermissionService _permissionService;

        public DeveloperPermissionController(
            AppDbContext context,
            DeveloperPermissionService permissionService)
        {
            _context = context;
            _permissionService = permissionService;
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

        /// <summary>
        /// GET: api/developerpermission/my-permissions
        /// Get current developer's permissions
        /// </summary>
        [HttpGet("my-permissions")]
        public async Task<ActionResult<Dictionary<string, bool>>> GetMyPermissions()
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized("User not authenticated");

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized("User not found");

            // Check if user is a developer
            if (!account.IsDeveloperOrAdmin())
                return Forbid("Only developers can check their permissions");

            // Admins have all permissions
            if (account.IsAdmin())
            {
                var allPermissions = new Dictionary<string, bool>();
                foreach (var feature in FeaturePermission.AllFeatures)
                {
                    allPermissions[feature] = true;
                }
                return Ok(allPermissions);
            }

            // Get developer permissions
            var permissions = await _permissionService.GetDeveloperPermissions(accountId.Value);
            return Ok(permissions);
        }

        /// <summary>
        /// GET: api/admin/developers/{id}/permissions
        /// Get developer permissions (admin-only)
        /// </summary>
        [HttpGet("~/api/admin/developers/{id}/permissions")]
        [AdminAuthorize]
        public async Task<ActionResult<Dictionary<string, bool>>> GetDeveloperPermissions(long id)
        {
            var account = await _context.Accounts.FindAsync(id);
            if (account == null)
                return NotFound(new { error = "Developer not found" });

            // Check if account is a developer
            if (!account.IsDeveloperOrAdmin() || account.IsAdmin())
            {
                return BadRequest(new { error = "Account is not a developer" });
            }

            var permissions = await _permissionService.GetDeveloperPermissions(id);
            return Ok(permissions);
        }

        /// <summary>
        /// PUT: api/admin/developers/{id}/permissions
        /// Update developer permissions (admin-only)
        /// </summary>
        [HttpPut("~/api/admin/developers/{id}/permissions")]
        [AdminAuthorize]
        public async Task<IActionResult> UpdateDeveloperPermissions(long id, [FromBody] UpdatePermissionsDto dto)
        {
            var account = await _context.Accounts.FindAsync(id);
            if (account == null)
                return NotFound(new { error = "Developer not found" });

            // Check if account is a developer
            if (!account.IsDeveloperOrAdmin() || account.IsAdmin())
            {
                return BadRequest(new { error = "Account is not a developer" });
            }

            try
            {
                // Validate permissions
                if (dto.Permissions == null)
                {
                    return BadRequest(new { error = "Permissions object is required" });
                }

                // Ensure only optional features are being updated
                foreach (var feature in dto.Permissions.Keys)
                {
                    if (!FeaturePermission.IsOptionalFeature(feature))
                    {
                        return BadRequest(new { error = $"Cannot update default feature: {feature}" });
                    }
                }

                // Bulk update permissions
                await _permissionService.BulkUpdatePermissions(id, dto.Permissions);

                // Return updated permissions
                var updatedPermissions = await _permissionService.GetDeveloperPermissions(id);
                return Ok(new { message = "Permissions updated successfully", permissions = updatedPermissions });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// POST: api/admin/developers/{id}/permissions/initialize
        /// Initialize permissions for a developer (admin-only)
        /// Creates default permission records for all optional features
        /// </summary>
        [HttpPost("~/api/admin/developers/{id}/permissions/initialize")]
        [AdminAuthorize]
        public async Task<IActionResult> InitializeDeveloperPermissions(long id)
        {
            var account = await _context.Accounts.FindAsync(id);
            if (account == null)
                return NotFound(new { error = "Developer not found" });

            // Check if account is a developer
            if (!account.IsDeveloperOrAdmin() || account.IsAdmin())
            {
                return BadRequest(new { error = "Account is not a developer" });
            }

            try
            {
                await _permissionService.InitializeDeveloperPermissions(id);
                var permissions = await _permissionService.GetDeveloperPermissions(id);
                return Ok(new { message = "Permissions initialized successfully", permissions });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// GET: api/admin/developers/permissions/all
        /// Get permissions for all developers (admin-only)
        /// </summary>
        [HttpGet("~/api/admin/developers/permissions/all")]
        [AdminAuthorize]
        public async Task<ActionResult<Dictionary<long, Dictionary<string, bool>>>> GetAllDeveloperPermissions()
        {
            try
            {
                // Get all developers
                var developers = await _context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .Select(a => a.AccountId)
                    .ToListAsync();

                var result = new Dictionary<long, Dictionary<string, bool>>();

                foreach (var developerId in developers)
                {
                    var permissions = await _permissionService.GetDeveloperPermissions(developerId);
                    result[developerId] = permissions;
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    /// <summary>
    /// DTO for updating permissions
    /// </summary>
    public class UpdatePermissionsDto
    {
        public Dictionary<string, bool> Permissions { get; set; } = new Dictionary<string, bool>();
    }
}

