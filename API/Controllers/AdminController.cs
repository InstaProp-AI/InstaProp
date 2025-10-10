using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Attributes;
using Microsoft.AspNetCore.Authorization;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [AdminAuthorize]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AdminController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Admin/users - Get all users for admin dashboard
        [HttpGet("users")]
        public async Task<ActionResult<IEnumerable<object>>> GetAllUsers()
        {
            try
            {
                var users = await _context.Accounts
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new
                    {
                        a.AccountId,
                        a.FirstName,
                        a.LastName,
                        a.Email,
                        a.PhoneNumber,
                        Type = a.Type.ToString(), // Convert enum to string
                        Status = a.Status.ToString(), // Convert enum to string
                        a.EmailVerified,
                        a.PhoneVerified,
                        a.IsSuspended,
                        a.SuspendedUntil,
                        a.SuspensionReason,
                        a.CreatedAt,
                        a.UpdatedAt
                    })
                    .ToListAsync();

                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Admin/users/{id} - Get specific user details
        [HttpGet("users/{id}")]
        public async Task<ActionResult<object>> GetUser(long id)
        {
            try
            {
                var user = await _context.Accounts
                    .Include(a => a.Properties)
                        .ThenInclude(p => p.Project)
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
                    Type = user.Type.ToString(),
                    Status = user.Status.ToString(),
                    user.EmailVerified,
                    user.PhoneVerified,
                    user.IsSuspended,
                    user.SuspendedUntil,
                    user.SuspensionReason,
                    user.CreatedAt,
                    user.UpdatedAt,
                    Properties = user.Properties.Select(p => new
                    {
                        p.PropertyId,
                        p.OwnerId,
                        p.Name,
                        p.Description,
                        p.Location,
                        Type = p.Type.ToString(),
                        Status = p.Status.ToString(),
                        p.Bedrooms,
                        p.Bathrooms,
                        p.SquareFeet,
                        p.YearBuilt,
                        p.Category,
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
                    PropertiesCount = user.Properties.Count,
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
        public async Task<IActionResult> VerifyUser(long id)
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
        public async Task<IActionResult> RejectUser(long id)
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
        public async Task<IActionResult> DeleteUser(long id)
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
        public async Task<IActionResult> SuspendUser(long id, [FromBody] SuspendUserDto dto)
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
        public async Task<IActionResult> UnsuspendUser(long id)
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
        public async Task<IActionResult> UpdateUser(long id, [FromBody] UpdateUserDto dto)
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
        public async Task<IActionResult> VerifyEmail(long id)
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
        public async Task<IActionResult> VerifyPhone(long id)
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

        // PUT: api/Admin/users/{id}/change-type - Change user account type
        [HttpPut("users/{id}/change-type")]
        public async Task<IActionResult> ChangeUserType(long id, [FromBody] ChangeTypeDto dto)
        {
            try
            {
                var user = await _context.Accounts.FindAsync(id);
                if (user == null)
                    return NotFound(new { error = "User not found" });

                user.Type = dto.Type;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { message = "User type changed successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/users/{id}/reset-password - Force password reset
        [HttpPut("users/{id}/reset-password")]
        public async Task<IActionResult> AdminResetPassword(long id)
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
        }

        public class ChangeTypeDto
        {
            public AccountType Type { get; set; }
        }
    

        // GET: api/Admin/properties - Get all properties
        [HttpGet("properties")]
        public async Task<ActionResult<IEnumerable<object>>> GetAllProperties()
        {
            try
            {
                var properties = await _context.Properties
                    .Include(p => p.Owner)
                    .Include(p => p.Project)
                    .OrderByDescending(p => p.CreatedAt)
                    .Select(p => new
                    {
                        p.PropertyId,
                        p.OwnerId,
                        p.ProjectId,
                        p.Name,
                        p.Description,
                        p.Location,
                        p.Type,
                        Status = p.Status.ToString(), // Convert enum to string
                        p.Bedrooms,
                        p.Bathrooms,
                        p.SquareFeet,
                        p.YearBuilt,
                        p.Category,
                        p.ImageUrl,
                        p.CreatedAt,
                        p.UpdatedAt,
                        Owner = p.Owner != null ? new
                        {
                            p.Owner.AccountId,
                            p.Owner.FirstName,
                            p.Owner.LastName,
                            p.Owner.Email,
                            Type = p.Owner.Type.ToString()
                        } : null,
                        Project = p.Project != null ? new
                        {
                            p.Project.ProjectId,
                            p.Project.Name
                        } : null
                    })
                    .ToListAsync();

                return Ok(properties);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Admin/properties/{id}/approve - Approve a property
        [HttpPut("properties/{id}/approve")]
        public async Task<IActionResult> ApproveProperty(long id)
        {
            try
            {
                var property = await _context.Properties.FindAsync(id);
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
        public async Task<IActionResult> RejectProperty(long id)
        {
            try
            {
                var property = await _context.Properties.FindAsync(id);
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
        public async Task<IActionResult> UpdateProperty(long id, [FromBody] UpdatePropertyDto dto)
        {
            try
            {
                var property = await _context.Properties.FindAsync(id);
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
                    if (dto.ProjectId.Value > 0)
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
            public long? ProjectId { get; set; } // Use long? to allow setting to null (detach) or -1 to explicitly detach
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
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new
                    {
                        a.AuctionId,
                        a.PropertyId,
                        a.StartPrice,
                        a.CurrentPrice,
                        a.StartAt,
                        a.Duration,
                        a.BuyNowPrice,
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
                            a.Property.Type,
                            a.Property.Status,
                            a.Property.Bedrooms,
                            a.Property.Bathrooms,
                            a.Property.SquareFeet,
                            a.Property.YearBuilt,
                            a.Property.Category,
                            a.Property.ImageUrl,
                            Owner = a.Property.Owner != null ? new
                            {
                                a.Property.Owner.AccountId,
                                a.Property.Owner.FirstName,
                                a.Property.Owner.LastName,
                                a.Property.Owner.Email,
                                Type = a.Property.Owner.Type.ToString()
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
        public async Task<IActionResult> StartAuction(long id)
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
        public async Task<IActionResult> EndAuction(long id)
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
                                b.Auction.Property.Category,
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
                // User statistics (Type 0 only)
                var totalUsers = await _context.Accounts.Where(a => a.Type == AccountType.User).CountAsync();
                var verifiedUsers = await _context.Accounts
                    .Where(a => a.Type == AccountType.User && a.Status == VerificationStatus.Verified)
                    .CountAsync();
                var pendingUsers = await _context.Accounts
                    .Where(a => a.Type == AccountType.User && a.Status == VerificationStatus.Pending)
                    .CountAsync();
                var notVerifiedUsers = await _context.Accounts
                    .Where(a => a.Type == AccountType.User && a.Status == VerificationStatus.NotVerified)
                    .CountAsync();
                
                // Developer and Admin counts
                var totalDevelopers = await _context.Accounts.Where(a => a.Type == AccountType.Developer).CountAsync();
                var totalAdmins = await _context.Accounts.Where(a => a.Type == AccountType.Admin).CountAsync();
                
                // Property statistics
                var totalProperties = await _context.Properties.CountAsync();
                var approvedProperties = await _context.Properties.Where(p => p.Status == PropertyStatus.Approved).CountAsync();
                var pendingProperties = await _context.Properties.Where(p => p.Status == PropertyStatus.Pending).CountAsync();
                var notApprovedProperties = await _context.Properties.Where(p => p.Status == PropertyStatus.NotApproved).CountAsync();
                
                // Auction statistics
                var totalAuctions = await _context.Auctions.CountAsync();
                var activeAuctions = await _context.Auctions.Where(a => a.Status == "Active").CountAsync();
                var endedAuctions = await _context.Auctions.Where(a => a.Status == "Ended").CountAsync();
                
                // Bid statistics
                var totalBids = await _context.Bids.CountAsync();
                
                // Revenue calculation (sum of all ended auction current prices)
                var totalRevenue = await _context.Auctions
                    .Where(a => a.Status == "Ended")
                    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0;
                
                // Monthly revenue (last 30 days) - based on auction end date
                var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
                var monthlyRevenue = await _context.Auctions
                    .Where(a => a.Status == "Ended" && a.CreatedAt >= thirtyDaysAgo)
                    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0;

                // Calculate average bid value
                var averageBidValue = totalBids > 0 
                    ? await _context.Bids.AverageAsync(b => (decimal?)b.BidAmount) ?? 0
                    : 0;

                var stats = new
                {
                    users = new
                    {
                        total = totalUsers,
                        verified = verifiedUsers,
                        pending = pendingUsers,
                        notVerified = notVerifiedUsers,
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
                        ended = endedAuctions
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

        // GET: api/Admin/analytics - Get detailed analytics and trends
        [HttpGet("analytics")]
        public async Task<ActionResult<object>> GetDetailedAnalytics()
        {
            try
            {
                var now = DateTime.UtcNow;
                var last30Days = now.AddDays(-30);
                var last7Days = now.AddDays(-7);

                // Daily bid trends (last 30 days)
                var dailyBids = await _context.Bids
                    .Where(b => b.CreatedAt >= last30Days)
                    .GroupBy(b => b.CreatedAt.Date)
                    .Select(g => new
                    {
                        date = g.Key,
                        count = g.Count(),
                        totalValue = g.Sum(b => b.BidAmount)
                    })
                    .OrderBy(x => x.date)
                    .ToListAsync();

                // Daily revenue from ended auctions (last 30 days)
                var dailyRevenue = await _context.Auctions
                    .Where(a => a.Status == "Ended" && a.CreatedAt >= last30Days)
                    .GroupBy(a => a.CreatedAt.Date)
                    .Select(g => new
                    {
                        date = g.Key,
                        count = g.Count(),
                        revenue = g.Sum(a => a.CurrentPrice)
                    })
                    .OrderBy(x => x.date)
                    .ToListAsync();

                // Top properties by bid count
                var topProperties = await _context.Auctions
                    .Include(a => a.Property)
                    .Where(a => a.BidCount > 0)
                    .OrderByDescending(a => a.BidCount)
                    .Take(10)
                    .Select(a => new
                    {
                        propertyId = a.PropertyId,
                        propertyName = a.Property.Name,
                        bidCount = a.BidCount,
                        currentPrice = a.CurrentPrice,
                        status = a.Status
                    })
                    .ToListAsync();

                // Active users (users who placed bids in last 7 days)
                var activeUsers = await _context.Bids
                    .Where(b => b.CreatedAt >= last7Days)
                    .Select(b => b.BidderId)
                    .Distinct()
                    .CountAsync();

                // Property categories distribution
                var categoryDistribution = await _context.Properties
                    .GroupBy(p => p.Category ?? "Uncategorized")
                    .Select(g => new
                    {
                        category = g.Key,
                        count = g.Count(),
                        approved = g.Count(p => p.Status == PropertyStatus.Approved)
                    })
                    .ToListAsync();

                var analytics = new
                {
                    trends = new
                    {
                        dailyBids,
                        dailyRevenue
                    },
                    topProperties,
                    activeUsers,
                    categoryDistribution
                };

                return Ok(analytics);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}


