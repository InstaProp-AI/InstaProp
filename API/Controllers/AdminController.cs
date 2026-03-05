using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using Microsoft.AspNetCore.Authorization;
using InstapropAPI.Services;
using BCrypt.Net;
using System.Linq;
using InstapropAPI.Models.Financial;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [AdminAuthorize]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ImageFixService _imageFixService;
        private readonly GlobalSeedingService _seedingService;
        private readonly IFinancialService _financialService;
        private readonly FeatureFlagService _featureFlagService;

        public AdminController(
            AppDbContext context,
            ImageFixService imageFixService,
            GlobalSeedingService seedingService,
            IFinancialService financialService,
            FeatureFlagService featureFlagService)
        {
            _context = context;
            _imageFixService = imageFixService;
            _seedingService = seedingService;
            _financialService = financialService;
            _featureFlagService = featureFlagService;
        }

        // GET: api/Admin/users - Get paginated users for admin dashboard
        [HttpGet("users")]
        public async Task<ActionResult<object>> GetAllUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 10, [FromQuery] Guid? roleId = null)
        {
            try
            {
                // Validate pagination parameters
                if (page < 1) page = 1;
                if (pageSize < 1) pageSize = 10;
                if (pageSize > 100) pageSize = 100; // Limit max page size to prevent abuse

                // Build query with optional roleId filter
                var query = _context.Accounts.AsQueryable();
                if (roleId.HasValue)
                {
                    query = query.Where(a => a.RoleId == roleId.Value);
                }

                // Get total count
                var totalCount = await query.CountAsync();

                // Get paginated users with AssignedDeveloper info
                var users = await query
                    .Include(a => a.Role)
                    .OrderByDescending(a => a.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var userDtos = users.Select(a =>
                {
                    var salesAccount = a as SalesAccount;
                    var assignedDeveloper = salesAccount?.AssignedDeveloper;
                    return new
                    {
                        a.AccountId,
                        a.FirstName,
                        a.LastName,
                        a.Email,
                        a.PhoneNumber,
                        RoleId = a.RoleId, // SECURITY: Return non-guessable RoleId
                        RoleName = a.Role != null ? a.Role.RoleName : "Unknown", // Role name for display
                        Status = a.Status.ToString(), // Convert enum to string
                        a.EmailVerified,
                        a.PhoneVerified,
                        a.IsSuspended,
                        a.SuspendedUntil,
                        a.SuspensionReason,
                        a.CreatedAt,
                        a.UpdatedAt,
                        AssignedDeveloperId = salesAccount?.AssignedDeveloperId,
                        AssignedDeveloperName = assignedDeveloper != null 
                            ? $"{assignedDeveloper.FirstName} {assignedDeveloper.LastName}" 
                            : null
                    };
                }).ToList();

                // Return paginated response (also include items for backward compatibility)
                return Ok(new
                {
                    data = userDtos,
                    items = userDtos, // For backward compatibility
                    pagination = new
                    {
                        page = page,
                        pageSize = pageSize,
                        totalCount = totalCount,
                        totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                        hasNextPage = page * pageSize < totalCount,
                        hasPreviousPage = page > 1
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/developers - Get paginated developers for admin dashboard
        [HttpGet("developers")]
        public async Task<ActionResult<object>> GetDevelopers([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                // Validate pagination parameters
                if (page < 1) page = 1;
                if (pageSize < 1) pageSize = 10;
                if (pageSize > 100) pageSize = 100;

                // Get total count of developers only
                var totalCount = await _context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .CountAsync();

                // Get paginated developers
                var developers = await _context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .Include(a => a.Role)
                    .OrderByDescending(a => a.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(a => new
                    {
                        a.AccountId,
                        a.FirstName,
                        a.LastName,
                        a.Email,
                        a.PhoneNumber,
                        RoleId = a.RoleId,
                        RoleName = a.Role != null ? a.Role.RoleName : "Developer",
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

                // Return paginated response
                return Ok(new
                {
                    data = developers,
                    pagination = new
                    {
                        page = page,
                        pageSize = pageSize,
                        totalCount = totalCount,
                        totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                        hasNextPage = page * pageSize < totalCount,
                        hasPreviousPage = page > 1
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/users/{id} - Get specific user details
        [HttpGet("users/{id}")]
        public async Task<ActionResult<object>> GetUser(Guid id)
        {
            try
            {
                var user = await _context.Accounts
                    .Include(a => a.Role) // Include Role for role name
                    .Include(a => a.Projects)
                        .ThenInclude(p => p.Developer)
                    .Include(a => a.Bids)
                        .ThenInclude(b => b.Auction)
                            .ThenInclude(a => a.Property)
                    .Include(a => a.Projects)
                    .FirstOrDefaultAsync(a => a.AccountId == id);

                if (user == null)
                    return NotFound(new { error = "User not found" });

                var userDto = new
                {
                    user.AccountId,
                    user.FirstName,
                    user.LastName,
                    user.Email,
                    user.PhoneNumber,
                    RoleId = user.RoleId, // SECURITY: Return non-guessable RoleId
                    RoleName = user.Role != null ? user.Role.RoleName : "Unknown", // Role name for display
                    Status = user.Status.ToString(),
                    user.EmailVerified,
                    user.PhoneVerified,
                    user.IsSuspended,
                    user.SuspendedUntil,
                    user.SuspensionReason,
                    user.CreatedAt,
                    user.UpdatedAt,
                    Properties = _context.ChildProperties.Where(cp => cp.OwnerId == user.AccountId).Select(p => new
                    {
                        p.PropertyId,
                        p.OwnerId,
                        p.Name,
                        p.Description,
                        p.Location,
                        Type = p.Type.ToDisplayName(),
                        Status = p.Status.ToString(),
                        p.Bedrooms,
                        p.Bathrooms,
                        p.SquareFeet,
                        p.YearBuilt,
                        p.ImageUrl,
                        p.CreatedAt,
                        Project = p.Project != null ? new
                        {
                            p.Project.ProjectId,
                            p.Project.Name
                        } : null
                    }).ToList(),
                    Bids = user.Bids.Select(b => new
                    {
                        b.BidId,
                        b.AuctionId,
                        b.BidderId,
                        b.BidAmount,
                        b.CreatedAt,
                        Auction = b.Auction != null ? new
                        {
                            b.Auction.AuctionId,
                            b.Auction.CurrentPrice,
                            b.Auction.Status,
                            Property = b.Auction.Property != null ? new
                            {
                                b.Auction.Property.PropertyId,
                                b.Auction.Property.Name,
                                b.Auction.Property.Location
                            } : null
                        } : null
                    }).ToList(),
                    PropertiesCount = await _context.ChildProperties.Where(cp => cp.OwnerId == user.AccountId).CountAsync(),
                    BidsCount = user.Bids.Count,
                    ProjectsCount = user.Projects.Count
                };

                return Ok(userDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/verify - Verify a user
        [HttpPut("users/{id}/verify")]
        public async Task<IActionResult> VerifyUser(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.Status = VerificationStatus.Verified;
                user.EmailVerified = true;
                user.PhoneVerified = true;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "User verified successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/reject - Reject a user
        [HttpPut("users/{id}/reject")]
        public async Task<IActionResult> RejectUser(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.Status = VerificationStatus.NotVerified;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "User rejected successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Admin/users/{id} - Delete a user (ban)
        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                _context.Accounts.Remove(user);
                await _context.SaveChangesAsync();

                return Ok(new { message = "User deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/suspend - Suspend a user
        [HttpPut("users/{id}/suspend")]
        public async Task<IActionResult> SuspendUser(Guid id, [FromBody] SuspendUserDto dto)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.IsSuspended = true;
                user.SuspendedUntil = dto.SuspendedUntil;
                user.SuspensionReason = dto.Reason ?? "Account suspended by administrator";
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "User suspended successfully",
                    suspendedUntil = user.SuspendedUntil,
                    reason = user.SuspensionReason
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/unsuspend - Unsuspend a user
        [HttpPut("users/{id}/unsuspend")]
        public async Task<IActionResult> UnsuspendUser(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.IsSuspended = false;
                user.SuspendedUntil = null;
                user.SuspensionReason = null;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "User unsuspended successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/update - Update user details
        [HttpPut("users/{id}/update")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserDto dto)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                // Update fields if provided
                if (!string.IsNullOrEmpty(dto.FirstName))
                    user.FirstName = dto.FirstName;
                
                if (!string.IsNullOrEmpty(dto.LastName))
                    user.LastName = dto.LastName;
                
                if (!string.IsNullOrEmpty(dto.Email))
                    user.Email = dto.Email;
                
                if (!string.IsNullOrEmpty(dto.PhoneNumber))
                    user.PhoneNumber = dto.PhoneNumber;
                
                // Update AssignedDeveloperId if provided (for Sales accounts)
                if (dto.AssignedDeveloperId.HasValue)
                {
                    // Validate developer exists
                    var developer = await _context.Accounts
                        .OfType<DeveloperAccount>()
                        .FirstOrDefaultAsync(a => a.AccountId == dto.AssignedDeveloperId.Value);
                    
                    if (developer == null)
                        return BadRequest(new { error = "Developer not found" });
                    
                    if (user is SalesAccount salesAccount)
                    {
                        salesAccount.AssignedDeveloperId = dto.AssignedDeveloperId.Value;
                    }
                }
                else if (dto.AssignedDeveloperId == null && user.RoleId == Role.SALES_ROLE_ID)
                {
                    // Allow clearing assignment by passing null explicitly
                    if (user is SalesAccount salesAccount)
                    {
                        salesAccount.AssignedDeveloperId = null;
                    }
                }
                
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "User updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/verify-email - Manually verify email
        [HttpPut("users/{id}/verify-email")]
        public async Task<IActionResult> VerifyEmail(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.EmailVerified = true;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Email verified successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/verify-phone - Manually verify phone
        [HttpPut("users/{id}/verify-phone")]
        public async Task<IActionResult> VerifyPhone(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.PhoneVerified = true;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Phone verified successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/change-type - Change user role (SECURITY: Only admins can change roles)
        [HttpPut("users/{id}/change-type")]
        public async Task<IActionResult> ChangeUserType(Guid id, [FromBody] ChangeTypeDto dto)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                // SECURITY: Validate that the roleId exists in the Roles table
                var roleExists = await _context.Roles.AnyAsync(r => r.RoleId == dto.RoleId);
                if (!roleExists)
                    return BadRequest(new { error = "Invalid role ID. Role does not exist." });

                // SECURITY: Update RoleId instead of Type - uses non-guessable GUID
                user.RoleId = dto.RoleId;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "User role changed successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/reset-password - Force password reset
        [HttpPut("users/{id}/reset-password")]
        public async Task<IActionResult> AdminResetPassword(Guid id)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.RequiresPasswordChange = true;
                user.PasswordResetRequestedEmail = user.Email;
                user.PasswordResetTokenExpiry = DateTime.UtcNow.AddDays(7);
                user.UpdatedAt = DateTime.UtcNow;
                
                await _context.SaveChangesAsync();

                return Ok(new { message = "Password reset flag set. User will be prompted on next login." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DTOs
        public class SuspendUserDto
        {
            public DateTime? SuspendedUntil { get; set; }
            public string? Reason { get; set; }
        }

        public class UpdateUserDto
        {
            public string? FirstName { get; set; }
            public string? LastName { get; set; }
            public string? Email { get; set; }
            public string? PhoneNumber { get; set; }
            public Guid? AssignedDeveloperId { get; set; } // For Sales accounts
        }

        public class ChangeTypeDto
        {
            public Guid RoleId { get; set; } // SECURITY: Use non-guessable GUID RoleId instead of Type enum
        }
    

        // GET: api/Admin/properties - Get paginated properties for admin dashboard
        [HttpGet("properties")]
        public async Task<ActionResult<object>> GetAllProperties([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                // Validate pagination parameters
                if (page < 1) page = 1;
                if (pageSize < 1) pageSize = 10;
                if (pageSize > 100) pageSize = 100; // Limit max page size to prevent abuse

                // Get total count
                var totalCount = await _context.ChildProperties.CountAsync();

                // Get paginated properties
                var properties = await _context.ChildProperties
                    .Include(p => p.Owner)
                        .ThenInclude(o => o.Role) // Include Role for role name
                    .Include(p => p.Project)
                    .Include(p => p.ParentProperty) // Include parent property
                    .OrderByDescending(p => p.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(p => new
                    {
                        p.PropertyId,
                        p.ParentPropertyId, // Include ParentPropertyId
                        p.OwnerId,
                        p.ProjectId,
                        p.Name,
                        p.Description,
                        p.Location,
                        Type = PropertyTypeHelper.ToDisplayName(p.Type),
                        Status = p.Status.ToString(), // Convert enum to string
                        p.Bedrooms,
                        p.Bathrooms,
                        p.SquareFeet,
                        p.YearBuilt,
                        p.ImageUrl,
                        p.CreatedAt,
                        p.UpdatedAt,
                        Owner = p.Owner != null ? new
                        {
                            p.Owner.AccountId,
                            p.Owner.FirstName,
                            p.Owner.LastName,
                            p.Owner.Email,
                            RoleId = p.Owner.RoleId, // SECURITY: Non-guessable RoleId
                            RoleName = p.Owner.Role != null ? p.Owner.Role.RoleName : "Unknown"
                        } : null,
                        Project = p.Project != null ? new
                        {
                            p.Project.ProjectId,
                            p.Project.Name
                        } : null,
                        ParentProperty = p.ParentProperty != null ? new
                        {
                            p.ParentProperty.ParentPropertyId,
                            ProjectName = !string.IsNullOrWhiteSpace(p.ParentProperty.ProjectName) 
                                ? p.ParentProperty.ProjectName 
                                : (p.Project != null ? p.Project.Name : "N/A"),
                            Type = p.ParentProperty.Type,
                            Bedrooms = p.ParentProperty.Bedrooms,
                            Bathrooms = p.ParentProperty.Bathrooms,
                            AreaSqm = p.ParentProperty.AreaSqm,
                            FinishingType = p.ParentProperty.FinishingType.ToString()
                        } : null
                    })
                    .ToListAsync();

                // Return paginated response
                return Ok(new
                {
                    data = properties,
                    pagination = new
                    {
                        page = page,
                        pageSize = pageSize,
                        totalCount = totalCount,
                        totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                        hasNextPage = page * pageSize < totalCount,
                        hasPreviousPage = page > 1
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/properties/{id}/approve - Approve a property
        [HttpPut("properties/{id}/approve")]
        public async Task<IActionResult> ApproveProperty(Guid id)
        {
            try
            {
                var property = await _context.ChildProperties.FindAsync(id);
                if (property == null)
                    return NotFound(new { error = "Property not found" });

                property.Status = PropertyStatus.Approved;
                property.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Property approved successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/properties/{id}/reject - Reject a property
        [HttpPut("properties/{id}/reject")]
        public async Task<IActionResult> RejectProperty(Guid id)
        {
            try
            {
                var property = await _context.ChildProperties.FindAsync(id);
                if (property == null)
                    return NotFound(new { error = "Property not found" });

                property.Status = PropertyStatus.NotApproved;
                property.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Property rejected successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/properties/{id}/update - Update property details (including projectId)
        [HttpPut("properties/{id}/update")]
        public async Task<IActionResult> UpdateProperty(Guid id, [FromBody] UpdatePropertyDto dto)
        {
            try
            {
                var property = await _context.ChildProperties.FindAsync(id);
                if (property == null)
                    return NotFound(new { error = "Property not found" });

                // Update fields if provided
                if (!string.IsNullOrEmpty(dto.Name))
                    property.Name = dto.Name;
                
                if (dto.Description != null)
                    property.Description = dto.Description;
                
                if (dto.Location != null)
                    property.Location = dto.Location;
                
                // Update projectId - this is the key field for attaching/detaching properties to projects
                if (dto.ProjectId.HasValue)
                {
                    // Validate project exists if assigning to a project
                    if (dto.ProjectId.HasValue && dto.ProjectId.Value != Guid.Empty)
                    {
                        var projectExists = await _context.Projects.AnyAsync(p => p.ProjectId == dto.ProjectId.Value);
                        if (!projectExists)
                            return BadRequest(new { error = "Project not found" });
                        
                        property.ProjectId = dto.ProjectId.Value;
                    }
                    else
                    {
                        // Detach from project (set to null)
                        property.ProjectId = null;
                    }
                }
                
                property.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Property updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        public class UpdatePropertyDto
        {
            public string? Name { get; set; }
            public string? Description { get; set; }
            public string? Location { get; set; }
            public Guid? ProjectId { get; set; } // Use Guid? to allow setting to null (detach)
        }

        // GET: api/Admin/auctions - Get all auctions
        [HttpGet("auctions")]
        public async Task<ActionResult<IEnumerable<object>>> GetAllAuctions()
        {
            try
            {
                var auctions = await _context.Auctions
                    .Include(a => a.Property)
                        .ThenInclude(p => p.Owner)
                            .ThenInclude(o => o.Role) // Include Role for role name
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new
                    {
                        a.AuctionId,
                        a.PropertyId,
                        a.StartPrice,
                        a.CurrentPrice,
                        a.StartAt,
                        a.Duration,
                        a.Status,
                        a.BidCount,
                        a.CreatedAt,
                        Property = a.Property != null ? new
                        {
                            a.Property.PropertyId,
                            a.Property.OwnerId,
                            a.Property.Name,
                            a.Property.Description,
                            a.Property.Location,
                            a.Property.Status,
                            a.Property.Bedrooms,
                            a.Property.Bathrooms,
                            a.Property.SquareFeet,
                            a.Property.YearBuilt,
                            Type = PropertyTypeHelper.ToDisplayName(a.Property.Type),
                            a.Property.ImageUrl,
                            Owner = a.Property.Owner != null ? new
                            {
                                a.Property.Owner.AccountId,
                                a.Property.Owner.FirstName,
                                a.Property.Owner.LastName,
                                a.Property.Owner.Email,
                                RoleId = a.Property.Owner.RoleId, // SECURITY: Non-guessable RoleId
                                RoleName = a.Property.Owner.Role != null ? a.Property.Owner.Role.RoleName : "Unknown"
                            } : null
                        } : null
                    })
                    .ToListAsync();

                return Ok(auctions);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/auctions/{id}/start - Start an auction
        [HttpPut("auctions/{id}/start")]
        public async Task<IActionResult> StartAuction(Guid id)
        {
            try
            {
                var auction = await _context.Auctions.FindAsync(id);
                if (auction == null)
                    return NotFound(new { error = "Auction not found" });

                auction.Status = "Active";
                auction.StartAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Auction started successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/auctions/{id}/end - End an auction
        [HttpPut("auctions/{id}/end")]
        public async Task<IActionResult> EndAuction(Guid id)
        {
            try
            {
                var auction = await _context.Auctions.FindAsync(id);
                if (auction == null)
                    return NotFound(new { error = "Auction not found" });

                auction.Status = "Ended";

                await _context.SaveChangesAsync();

                return Ok(new { message = "Auction ended successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/bids - Get all bids
        [HttpGet("bids")]
        public async Task<ActionResult<IEnumerable<object>>> GetAllBids()
        {
            try
            {
                var bids = await _context.Bids
                    .Include(b => b.Bidder)
                    .Include(b => b.Auction)
                    .ThenInclude(a => a.Property)
                    .OrderByDescending(b => b.CreatedAt)
                    .Select(b => new
                    {
                        b.BidId,
                        b.AuctionId,
                        b.BidderId,
                        b.BidAmount,
                        b.CreatedAt,
                        Bidder = new
                        {
                            b.Bidder.AccountId,
                            b.Bidder.FirstName,
                            b.Bidder.LastName,
                            b.Bidder.Email
                        },
                        Auction = new
                        {
                            b.Auction.AuctionId,
                            b.Auction.StartPrice,
                            b.Auction.CurrentPrice,
                            b.Auction.Status,
                            Property = b.Auction.Property != null ? new
                            {
                                b.Auction.Property.PropertyId,
                                b.Auction.Property.Name,
                                b.Auction.Property.Location,
                                Type = b.Auction.Property != null ? PropertyTypeHelper.ToDisplayName(b.Auction.Property.Type) : "Unknown",
                                Status = b.Auction.Property.Status.ToString()
                            } : null
                        }
                    })
                    .ToListAsync();

                return Ok(bids);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/stats - Get comprehensive admin statistics
        [HttpGet("stats")]
        public async Task<ActionResult<object>> GetAdminStats()
        {
            try
            {
                // SECURITY: User statistics using non-guessable RoleId
                var totalUsers = await _context.Accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).CountAsync();
                var verifiedUsers = await _context.Accounts
                    .Where(a => a.RoleId == Role.USER_ROLE_ID && a.Status == VerificationStatus.Verified)
                    .CountAsync();
                var pendingUsers = await _context.Accounts
                    .Where(a => a.RoleId == Role.USER_ROLE_ID && a.Status == VerificationStatus.Pending)
                    .CountAsync();
                var notVerifiedUsers = await _context.Accounts
                    .Where(a => a.RoleId == Role.USER_ROLE_ID && a.Status == VerificationStatus.NotVerified)
                    .CountAsync();
                var suspendedUsers = await _context.Accounts
                    .Where(a => a.RoleId == Role.USER_ROLE_ID && a.IsSuspended)
                    .CountAsync();
                
                // Developer and Admin counts using non-guessable RoleId
                var totalDevelopers = await _context.Accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).CountAsync();
                var totalAdmins = await _context.Accounts.Where(a => a.RoleId == Role.ADMIN_ROLE_ID).CountAsync();
                
                // Property statistics
                var totalProperties = await _context.ChildProperties.CountAsync();
                var approvedProperties = await _context.ChildProperties.Where(p => p.Status == PropertyStatus.Approved).CountAsync();
                var pendingProperties = await _context.ChildProperties.Where(p => p.Status == PropertyStatus.Pending).CountAsync();
                var notApprovedProperties = await _context.ChildProperties.Where(p => p.Status == PropertyStatus.NotApproved).CountAsync();
                
                // Auction statistics
                var totalAuctions = await _context.Auctions.CountAsync();
                var activeAuctions = await _context.Auctions.Where(a => a.Status == "Active").CountAsync();
                var endedAuctionsCount = await _context.Auctions.Where(a => a.Status == "Closed" || a.Status == "Completed").CountAsync();
                
                // Bid statistics
                var totalBids = await _context.Bids.CountAsync();
                
                // Revenue calculation (sum of all ended auction current prices)
                var endedAuctionsList = await _context.Auctions
                    .Where(a => a.Status == "Closed" || a.Status == "Completed")
                    .ToListAsync();
                var totalRevenue = endedAuctionsList.Sum(a => a.CurrentPrice);
                
                // Monthly revenue (last 30 days) - based on auction end date
                var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
                var recentEndedAuctions = endedAuctionsList
                    .Where(a => a.CreatedAt >= thirtyDaysAgo)
                    .ToList();
                var monthlyRevenue = recentEndedAuctions.Sum(a => a.CurrentPrice);

                // Calculate average bid value
                var averageBidValue = totalBids > 0 
                    ? (await _context.Bids.ToListAsync()).Average(b => b.BidAmount)
                    : 0;

                var stats = new
                {
                    users = new
                    {
                        total = totalUsers,
                        verified = verifiedUsers,
                        pending = pendingUsers,
                        notVerified = notVerifiedUsers,
                        suspended = suspendedUsers,
                        developers = totalDevelopers,
                        admins = totalAdmins
                    },
                    properties = new
                    {
                        total = totalProperties,
                        approved = approvedProperties,
                        pending = pendingProperties,
                        notApproved = notApprovedProperties
                    },
                    auctions = new
                    {
                        total = totalAuctions,
                        active = activeAuctions,
                        ended = endedAuctionsCount
                    },
                    bids = new
                    {
                        total = totalBids,
                        averageValue = averageBidValue
                    },
                    revenue = new
                    {
                        total = totalRevenue,
                        monthly = monthlyRevenue
                    }
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/analytics - Get comprehensive analytics with all data arrays
        [HttpGet("analytics")]
        public async Task<ActionResult<object>> GetDetailedAnalytics()
        {
            try
            {
                var now = DateTime.UtcNow;
                var last30Days = now.AddDays(-30);
                var last7Days = now.AddDays(-7);

                // Get users array (limited to 100 for performance)
                var users = await _context.Accounts
                    .Where(a => a.RoleId == Role.USER_ROLE_ID)
                    .OrderByDescending(a => a.CreatedAt)
                    .Take(100)
                    .Select(a => new
                    {
                        a.AccountId,
                        a.FirstName,
                        a.LastName,
                        a.Email,
                        a.Status,
                        a.CreatedAt
                    })
                    .ToListAsync();

                // Get properties array (limited to 100 for performance)
                var properties = await _context.ChildProperties
                    .Include(p => p.Owner)
                    .Include(p => p.Project)
                    .OrderByDescending(p => p.CreatedAt)
                    .Take(100)
                    .Select(p => new
                    {
                        p.PropertyId,
                        p.Name,
                        p.Location,
                        Type = PropertyTypeHelper.ToDisplayName(p.Type),
                        Status = p.Status.ToString(),
                        p.Bedrooms,
                        p.Bathrooms,
                        p.SquareFeet,
                        p.CreatedAt,
                        Owner = p.Owner != null ? new
                        {
                            p.Owner.AccountId,
                            p.Owner.FirstName,
                            p.Owner.LastName
                        } : null,
                        Project = p.Project != null ? new
                        {
                            p.Project.ProjectId,
                            p.Project.Name
                        } : null
                    })
                    .ToListAsync();

                // Get auctions array (limited to 100 for performance)
                var auctions = await _context.Auctions
                    .Include(a => a.Property)
                    .OrderByDescending(a => a.CreatedAt)
                    .Take(100)
                    .Select(a => new
                    {
                        a.AuctionId,
                        a.PropertyId,
                        a.StartPrice,
                        a.CurrentPrice,
                        a.Status,
                        a.BidCount,
                        a.StartAt,
                        a.Duration,
                        a.CreatedAt,
                        Property = a.Property != null ? new
                        {
                            a.Property.PropertyId,
                            a.Property.Name,
                            a.Property.Location
                        } : null
                    })
                    .ToListAsync();

                // Get bids array (limited to 100 for performance)
                var bids = await _context.Bids
                    .Include(b => b.Auction)
                    .ThenInclude(a => a.Property)
                    .OrderByDescending(b => b.CreatedAt)
                    .Take(100)
                    .Select(b => new
                    {
                        b.BidId,
                        b.AuctionId,
                        b.BidderId,
                        b.BidAmount,
                        b.CreatedAt,
                        Auction = b.Auction != null ? new
                        {
                            b.Auction.AuctionId,
                            b.Auction.Status,
                            Property = b.Auction.Property != null ? new
                            {
                                b.Auction.Property.PropertyId,
                                b.Auction.Property.Name
                            } : null
                        } : null
                    })
                    .ToListAsync();

                // Daily bid trends (last 30 days)
                var allBids = await _context.Bids
                    .Where(b => b.CreatedAt >= last30Days)
                    .ToListAsync();
                
                var dailyBids = allBids
                    .GroupBy(b => b.CreatedAt.Date)
                    .Select(g => new
                    {
                        date = g.Key,
                        count = g.Count(),
                        totalValue = g.Sum(b => b.BidAmount)
                    })
                    .OrderBy(x => x.date)
                    .ToList();

                // Daily revenue from ended auctions (last 30 days)
                var allEndedAuctions = await _context.Auctions
                    .Where(a => (a.Status == "Closed" || a.Status == "Completed" || a.Status == "Ended") && a.CreatedAt >= last30Days)
                    .ToListAsync();
                
                var dailyRevenue = allEndedAuctions
                    .GroupBy(a => a.CreatedAt.Date)
                    .Select(g => new
                    {
                        date = g.Key,
                        count = g.Count(),
                        revenue = g.Sum(a => a.CurrentPrice)
                    })
                    .OrderBy(x => x.date)
                    .ToList();

                // Top properties by bid count
                var topProperties = await _context.Auctions
                    .Include(a => a.Property)
                    .Where(a => a.BidCount > 0)
                    .OrderByDescending(a => a.BidCount)
                    .Take(10)
                    .Select(a => new
                    {
                        propertyId = a.PropertyId,
                        propertyName = a.Property != null ? a.Property.Name : "Unknown",
                        bidCount = a.BidCount,
                        currentPrice = a.CurrentPrice,
                        status = a.Status
                    })
                    .ToListAsync();

                var analytics = new
                {
                    // Main data arrays that AnalyticsPage expects
                    users = users,
                    properties = properties,
                    auctions = auctions,
                    bids = bids,
                    // Trends for charts
                    trends = new
                    {
                        dailyBids,
                        dailyRevenue
                    },
                    topProperties,
                    categoryDistribution = (await _context.ChildProperties
                        .Select(p => new { p.Type, p.Status })
                        .ToListAsync())
                        .GroupBy(p => PropertyTypeHelper.ToDisplayName(p.Type))
                        .Select(g => new
                        {
                            category = g.Key,
                            count = g.Count(),
                            approved = g.Count(p => p.Status == PropertyStatus.Approved)
                        })
                        .ToList()
                };

                return Ok(analytics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Admin/fix-images - Fix all broken image URLs in database
        [HttpPost("fix-images")]
        public async Task<ActionResult<object>> FixBrokenImages()
        {
            try
            {
                var result = await _imageFixService.FixAllBrokenImagesAsync();
                
                return Ok(new
                {
                    success = true,
                    message = "Image fix process completed",
                    totalChecked = result.TotalChecked,
                    totalBroken = result.TotalBroken,
                    totalFixed = result.TotalFixed,
                    details = new
                    {
                        fixedProperties = result.FixedProperties,
                        fixedPropertyImages = result.FixedPropertyImages,
                        fixedPropertyDocs = result.FixedPropertyDocs,
                        fixedUserDocs = result.FixedUserDocs,
                        fixedProjectUpdates = result.FixedProjectUpdates,
                        fixedNewsImages = result.FixedNewsImages,
                        // fixedCommunityPosts removed (community feature)
                        fixedDeveloperProfiles = result.FixedDeveloperProfiles,
                        fixedEventImages = result.FixedEventImages
                    },
                    error = result.ErrorMessage
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Admin/seed-data
        [HttpPost("seed-data")]
        [AllowAnonymous] // Allow anonymous for local development
        public async Task<ActionResult<object>> SeedData([FromQuery] bool skipClear = false)
        {
            try
            {
                Console.WriteLine("🌱 Starting data seeding...");
                await _seedingService.PreSeedTestDataAsync(skipClear: skipClear);
                
                return Ok(new
                {
                    success = true,
                    message = "Data seeding completed successfully"
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Seeding error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        // ─────────────────────────────────────────────
        // FINANCIAL MANAGEMENT (internal, admin-only)
        // ─────────────────────────────────────────────

        /// <summary>GET /api/admin/finance/balances — List all user balances (paginated).</summary>
        [HttpGet("finance/balances")]
        public async Task<IActionResult> GetAllBalances([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            var balances = await _financialService.GetAllBalancesAsync(page, pageSize);
            return Ok(new { success = true, data = balances });
        }

        /// <summary>GET /api/admin/finance/balances/{accountId} — Get balance for a specific user.</summary>
        [HttpGet("finance/balances/{accountId}")]
        public async Task<IActionResult> GetUserBalance(Guid accountId)
        {
            var balance = await _financialService.GetBalanceAsync(accountId);
            if (balance == null) return Ok(new { success = true, data = (object?)null, message = "No balance record found." });
            return Ok(new { success = true, data = balance });
        }

        /// <summary>GET /api/admin/finance/transactions/{accountId} — List transactions for a user.</summary>
        [HttpGet("finance/transactions/{accountId}")]
        public async Task<IActionResult> GetUserTransactions(Guid accountId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var transactions = await _financialService.GetTransactionsAsync(accountId, page, pageSize);
            return Ok(new { success = true, data = transactions });
        }

        /// <summary>GET /api/admin/finance/pending — List all pending transactions across all users.</summary>
        [HttpGet("finance/pending")]
        public async Task<IActionResult> GetPendingTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            var pending = await _financialService.GetPendingTransactionsAsync(page, pageSize);
            return Ok(new { success = true, data = pending, count = pending.Count });
        }

        /// <summary>POST /api/admin/finance/transactions/{id}/confirm — Confirm a pending transaction.</summary>
        [HttpPost("finance/transactions/{transactionId}/confirm")]
        public async Task<IActionResult> ConfirmTransaction(Guid transactionId, [FromBody] AdminConfirmRequest request)
        {
            try
            {
                var adminId = GetCurrentAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
                var tx = await _financialService.ConfirmTransactionAsync(transactionId, adminId, request.GatewayReference, ip);
                return Ok(new { success = true, message = "Transaction confirmed.", data = tx });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        /// <summary>POST /api/admin/finance/transactions/{id}/reject — Reject a pending transaction.</summary>
        [HttpPost("finance/transactions/{transactionId}/reject")]
        public async Task<IActionResult> RejectTransaction(Guid transactionId, [FromBody] AdminRejectRequest request)
        {
            try
            {
                var adminId = GetCurrentAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
                var tx = await _financialService.RejectTransactionAsync(transactionId, adminId, request.Reason, ip);
                return Ok(new { success = true, message = "Transaction rejected.", data = tx });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        /// <summary>POST /api/admin/finance/transactions/{id}/reverse — Reverse a confirmed transaction.</summary>
        [HttpPost("finance/transactions/{transactionId}/reverse")]
        public async Task<IActionResult> ReverseTransaction(Guid transactionId, [FromBody] AdminRejectRequest request)
        {
            try
            {
                var adminId = GetCurrentAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
                var tx = await _financialService.ReverseTransactionAsync(transactionId, adminId, request.Reason, ip);
                return Ok(new { success = true, message = "Transaction reversed.", data = tx });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        /// <summary>POST /api/admin/finance/adjust — Apply a manual credit or debit to a user's balance.</summary>
        [HttpPost("finance/adjust")]
        public async Task<IActionResult> ManualAdjustment([FromBody] ManualAdjustmentRequest request)
        {
            try
            {
                var adminId = GetCurrentAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();

                if (request.Type != TransactionType.ManualCredit && request.Type != TransactionType.ManualDebit)
                    return BadRequest(new { success = false, message = "Type must be ManualCredit or ManualDebit." });

                var tx = await _financialService.ApplyManualAdjustmentAsync(
                    request.AccountId, request.Amount, request.Type, request.Description, adminId, ip);

                return Ok(new { success = true, message = "Adjustment applied.", data = tx });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // ─────────────────────────────────────────────
        // FEATURE FLAGS (admin-only)
        // ─────────────────────────────────────────────

        /// <summary>GET /api/admin/flags — List all feature flags with current state.</summary>
        [HttpGet("flags")]
        public async Task<IActionResult> GetFeatureFlags()
        {
            var flags = await _context.FeatureFlags.OrderBy(f => f.FeatureKey).ToListAsync();
            return Ok(new { success = true, data = flags });
        }

        /// <summary>PUT /api/admin/flags/{key} — Toggle a feature flag on or off.</summary>
        [HttpPut("flags/{key}")]
        public async Task<IActionResult> SetFeatureFlag(string key, [FromBody] SetFlagRequest request)
        {
            try
            {
                var adminId = GetCurrentAdminId();
                var flag = await _featureFlagService.SetFlagAsync(key, request.IsEnabled, adminId);
                return Ok(new
                {
                    success = true,
                    message = $"Feature '{key}' is now {(request.IsEnabled ? "enabled" : "disabled")}.",
                    data = flag
                });
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { success = false, message = ex.Message });
            }
        }

        private Guid GetCurrentAdminId()
        {
            var claim = User.Claims.FirstOrDefault(c => c.Type == "uid")?.Value;
            return claim != null ? Guid.Parse(claim) : Guid.Empty;
        }
    }
}

public class AdminConfirmRequest { public string? GatewayReference { get; set; } }
public class AdminRejectRequest { public string Reason { get; set; } = string.Empty; }
public class ManualAdjustmentRequest
{
    public Guid AccountId { get; set; }
    public decimal Amount { get; set; }
    public InstapropAPI.Models.Financial.TransactionType Type { get; set; }
    public string Description { get; set; } = string.Empty;
}
public class SetFlagRequest { public bool IsEnabled { get; set; } }
