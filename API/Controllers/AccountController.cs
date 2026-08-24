using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using InstapropAPI.Services;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AccountController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;
        private readonly EmailVerificationService _emailVerificationService;
        private readonly PhoneVerificationService _phoneVerificationService;
        private readonly FirestoreService _firestoreService;
        private readonly FileValidationService _fileValidationService;
        private readonly RewardService _rewardService;
        private readonly RoleSeederService _roleSeederService;

        public AccountController(
            AppDbContext context, 
            IConfiguration config,
            EmailVerificationService emailVerificationService,
            PhoneVerificationService phoneVerificationService,
            FirestoreService firestoreService,
            FileValidationService fileValidationService,
            RewardService rewardService,
            RoleSeederService roleSeederService)
        {
            _context = context;
            _config = config;
            _emailVerificationService = emailVerificationService;
            _phoneVerificationService = phoneVerificationService;
            _firestoreService = firestoreService;
            _fileValidationService = fileValidationService;
            _rewardService = rewardService;
            _roleSeederService = roleSeederService;
        }


        // Get timezone options
        [AllowAnonymous]
        [HttpGet("timezones")]
        public IActionResult GetTimeZones()
        {
            var timezones = Helpers.TimeZoneHelper.GetTimeZoneOptions();
            return Ok(timezones);
        }

        // Check if email exists
        [AllowAnonymous]
        [HttpGet("check-email")]
        public async Task<IActionResult> CheckEmail([FromQuery] string email)
        {
            var exists = await _context.Accounts.AnyAsync(a => a.Email == email);
            return Ok(new { exists });
        }

        // Check if phone exists
        [AllowAnonymous]
        [HttpGet("check-phone")]
        public async Task<IActionResult> CheckPhone([FromQuery] string phone)
        {
            var exists = await _context.Accounts.AnyAsync(a => a.PhoneNumber == phone);
            return Ok(new { exists });
        }

        // User Signup - Create regular user account
        [AllowAnonymous]
        [HttpPost("signup")]
        public async Task<IActionResult> Signup([FromBody] SignupRequest signupRequest)
        {
            // Normalize email and phone for comparison
            var normalizedEmail = signupRequest.Email?.Trim().ToLowerInvariant();
            var normalizedPhone = signupRequest.PhoneNumber?.Trim();
            
            if (string.IsNullOrWhiteSpace(normalizedEmail))
                return BadRequest("Email is required.");
            
            if (string.IsNullOrWhiteSpace(normalizedPhone))
                return BadRequest("Phone number is required.");
            
            // Check for existing email (case-insensitive)
            if (await _context.Accounts.AnyAsync(a => a.Email.ToLower() == normalizedEmail))
                return BadRequest("Email already exists.");

            // Check for existing phone number
            if (await _context.Accounts.AnyAsync(a => a.PhoneNumber == normalizedPhone))
                return BadRequest("Phone number already exists.");

            // Validate password
            var passwordError = ValidatePassword(signupRequest.Password);
            if (passwordError != null)
                return BadRequest(passwordError);

            // Ensure roles exist (never insert inline — avoids PK_Roles duplicate errors)
            await _roleSeederService.SeedRolesAsync();

            var userRole = await _context.Roles.FindAsync(Role.USER_ROLE_ID);
            if (userRole == null)
            {
                return StatusCode(500, new { 
                    error = "Database configuration error",
                    message = "User role does not exist in database. Please run migrations and seed roles.",
                    details = $"RoleId {Role.USER_ROLE_ID} not found"
                });
            }

            // SECURITY FIX: Always create User accounts with UUID RoleId
            var account = new UserAccount
            {
                FirstName = signupRequest.FirstName?.Trim() ?? string.Empty,
                LastName = signupRequest.LastName?.Trim() ?? string.Empty,
                Email = normalizedEmail,
                PhoneNumber = normalizedPhone,
                RoleId = Role.USER_ROLE_ID, // Always User role - UUID
                HashedPassword = BCrypt.Net.BCrypt.HashPassword(signupRequest.Password),
                Status = VerificationStatus.NotVerified, // Will be verified by admin after KYC review
                TimeZone = signupRequest.TimeZone?.Trim(), // User's preferred timezone
                CreatedAt = DateTime.UtcNow
            };

            _context.UserAccounts.Add(account);
            
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException ex)
            {
                // Log the full exception for debugging
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Database error during signup: {Message}", ex.Message);
                
                // Get detailed error message from inner exception
                var innerException = ex.InnerException;
                var errorMessage = ex.Message;
                var detailedMessage = innerException?.Message ?? errorMessage;
                
                // Check for specific constraint violations
                if (detailedMessage.Contains("duplicate key") || detailedMessage.Contains("UNIQUE constraint"))
                {
                    if (detailedMessage.Contains("Email") || detailedMessage.Contains("email"))
                    {
                        return BadRequest("Email already exists.");
                    }
                    if (detailedMessage.Contains("PhoneNumber") || detailedMessage.Contains("phone"))
                    {
                        return BadRequest("Phone number already exists.");
                    }
                    return BadRequest("An account with this information already exists.");
                }
                
                if (detailedMessage.Contains("foreign key") || detailedMessage.Contains("FOREIGN KEY"))
                {
                    return StatusCode(500, new { 
                        error = "Database configuration error",
                        message = "Required system data is missing. Please contact support.",
                        details = detailedMessage
                    });
                }
                
                // Return detailed error for debugging
                return StatusCode(500, new { 
                    error = "An error occurred while creating your account",
                    message = detailedMessage,
                    type = ex.GetType().Name,
                    innerType = innerException?.GetType().Name
                });
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Unexpected error during signup: {Message}", ex.Message);
                return StatusCode(500, new { 
                    error = "An unexpected error occurred",
                    message = ex.Message
                });
            }

            // Load role name for response without attaching navigation (prevents duplicate Role inserts)
            var roleName = await GetRoleNameAsync(account.RoleId);

            // Sync new user to Firestore for real-time dashboard updates (don't fail signup if this fails)
            try
            {
                await _firestoreService.SyncUserAsync(account.AccountId, account);
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogWarning(ex, "Firestore sync failed for account {AccountId}, but signup succeeded", account.AccountId);
            }

            var token = GenerateJwtToken(account);
            
            // Return account with roleId and roleName explicitly for Flutter compatibility
            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = roleName,
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.CreatedAt,
                account.UpdatedAt
            };
            
            return Ok(new { Token = token, Account = accountResponse });
        }

        // Developer Signup - Create developer account (Admin only)
        [HttpPost("signup-developer")]
        [AdminAuthorize]
        public async Task<IActionResult> SignupDeveloper([FromBody] SignupRequest signupRequest)
        {
            // Normalize email and phone for comparison
            var normalizedEmail = signupRequest.Email?.Trim().ToLowerInvariant();
            var normalizedPhone = signupRequest.PhoneNumber?.Trim();
            
            if (string.IsNullOrWhiteSpace(normalizedEmail))
                return BadRequest("Email is required.");
            
            if (string.IsNullOrWhiteSpace(normalizedPhone))
                return BadRequest("Phone number is required.");
            
            // Check for existing email (case-insensitive)
            if (await _context.Accounts.AnyAsync(a => a.Email.ToLower() == normalizedEmail))
                return BadRequest("Email already exists.");

            // Check for existing phone number
            if (await _context.Accounts.AnyAsync(a => a.PhoneNumber == normalizedPhone))
                return BadRequest("Phone number already exists.");

            // Validate password
            var passwordError = ValidatePassword(signupRequest.Password);
            if (passwordError != null)
                return BadRequest(passwordError);

            await _roleSeederService.SeedRolesAsync();

            var developerRole = await _context.Roles.FindAsync(Role.DEVELOPER_ROLE_ID);
            if (developerRole == null)
            {
                return StatusCode(500, new { 
                    error = "Database configuration error",
                    message = "Developer role does not exist in database. Please run migrations and seed roles.",
                    details = $"RoleId {Role.DEVELOPER_ROLE_ID} not found"
                });
            }

            // Create Developer account
            var account = new DeveloperAccount
            {
                FirstName = signupRequest.FirstName?.Trim() ?? string.Empty,
                LastName = signupRequest.LastName?.Trim() ?? string.Empty,
                Email = normalizedEmail,
                PhoneNumber = normalizedPhone,
                RoleId = Role.DEVELOPER_ROLE_ID, // Developer role
                HashedPassword = BCrypt.Net.BCrypt.HashPassword(signupRequest.Password),
                Status = VerificationStatus.NotVerified, // Will be verified by admin after KYC review
                CreatedAt = DateTime.UtcNow
            };

            _context.DeveloperAccounts.Add(account);
            
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException ex)
            {
                // Log the full exception for debugging
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Database error during developer signup: {Message}", ex.Message);
                
                // Get detailed error message from inner exception
                var innerException = ex.InnerException;
                var errorMessage = ex.Message;
                var detailedMessage = innerException?.Message ?? errorMessage;
                
                // Check for specific constraint violations
                if (detailedMessage.Contains("duplicate key") || detailedMessage.Contains("UNIQUE constraint"))
                {
                    if (detailedMessage.Contains("Email") || detailedMessage.Contains("email"))
                    {
                        return BadRequest("Email already exists.");
                    }
                    if (detailedMessage.Contains("PhoneNumber") || detailedMessage.Contains("phone"))
                    {
                        return BadRequest("Phone number already exists.");
                    }
                    return BadRequest("An account with this information already exists.");
                }
                
                if (detailedMessage.Contains("foreign key") || detailedMessage.Contains("FOREIGN KEY"))
                {
                    return StatusCode(500, new { 
                        error = "Database configuration error",
                        message = "Required system data is missing. Please contact support.",
                        details = detailedMessage
                    });
                }
                
                // Return detailed error for debugging
                return StatusCode(500, new { 
                    error = "An error occurred while creating your developer account",
                    message = detailedMessage,
                    type = ex.GetType().Name,
                    innerType = innerException?.GetType().Name
                });
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Unexpected error during developer signup: {Message}", ex.Message);
                return StatusCode(500, new { 
                    error = "An unexpected error occurred",
                    message = ex.Message
                });
            }

            // Load Role separately using AsNoTracking to avoid Type column reference and tracking conflicts
            var devSignupRole = await _context.Roles
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.RoleId == account.RoleId);
            
            if (devSignupRole != null)
            {
                // Set navigation property - EF Core will handle the relationship through RoleId
                account.Role = devSignupRole;
            }

            // Sync new developer to Firestore for real-time dashboard updates (don't fail signup if this fails)
            try
            {
                await _firestoreService.SyncUserAsync(account.AccountId, account);
            }
            catch (Exception ex)
            {
                // Log but don't fail signup if Firestore sync fails
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogWarning(ex, "Firestore sync failed for developer account {AccountId}, but signup succeeded", account.AccountId);
            }

            var token = GenerateJwtToken(account);
            
            // Return account with roleId and roleName explicitly for Flutter compatibility
            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = account.Role?.RoleName ?? "Developer",
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.CreatedAt,
                account.UpdatedAt
            };
            
            return Ok(new { Token = token, Account = accountResponse });
        }

        // Sales Signup - Create sales account (Admin or Developer only)
        [HttpPost("signup-sales")]
        [DeveloperOrAdminAuthorize]
        public async Task<IActionResult> SignupSales([FromBody] SalesSignupRequest signupRequest)
        {
            var currentAccountId = GetCurrentAccountId();
            if (currentAccountId == null)
                return Unauthorized();

            var currentAccount = await _context.Accounts.FindAsync(currentAccountId.Value);
            if (currentAccount == null)
                return Unauthorized("Current account not found");

            // Determine developer assignment
            Guid? assignedDeveloperId = null;
            
            // If current user is admin, require developerId in request
            if (currentAccount.RoleId == Role.ADMIN_ROLE_ID)
            {
                if (!signupRequest.DeveloperId.HasValue)
                    return BadRequest("Developer ID is required when creating sales account as admin.");

                // Verify developer exists and is actually a developer
                var developer = await _context.DeveloperAccounts
                    .FirstOrDefaultAsync(a => a.AccountId == signupRequest.DeveloperId.Value);
                
                if (developer == null)
                    return BadRequest("Invalid developer ID. Developer not found.");

                assignedDeveloperId = signupRequest.DeveloperId.Value;
            }
            // If current user is developer, auto-assign to themselves
            else if (currentAccount.RoleId == Role.DEVELOPER_ROLE_ID)
            {
                assignedDeveloperId = currentAccountId.Value;
            }
            else
            {
                return Forbid();
            }

            // Normalize email and phone for comparison
            var normalizedEmail = signupRequest.Email?.Trim().ToLowerInvariant();
            var normalizedPhone = signupRequest.PhoneNumber?.Trim();
            
            if (string.IsNullOrWhiteSpace(normalizedEmail))
                return BadRequest("Email is required.");
            
            if (string.IsNullOrWhiteSpace(normalizedPhone))
                return BadRequest("Phone number is required.");
            
            // Check for existing email (case-insensitive)
            if (await _context.Accounts.AnyAsync(a => a.Email.ToLower() == normalizedEmail))
                return BadRequest("Email already exists.");

            // Check for existing phone number
            if (await _context.Accounts.AnyAsync(a => a.PhoneNumber == normalizedPhone))
                return BadRequest("Phone number already exists.");

            // Validate password
            var passwordError = ValidatePassword(signupRequest.Password);
            if (passwordError != null)
                return BadRequest(passwordError);

            await _roleSeederService.SeedRolesAsync();

            var salesRole = await _context.Roles.FindAsync(Role.SALES_ROLE_ID);
            if (salesRole == null)
            {
                return StatusCode(500, new { 
                    error = "Database configuration error",
                    message = "Sales role does not exist in database. Please run migrations and seed roles.",
                    details = $"RoleId {Role.SALES_ROLE_ID} not found"
                });
            }

            // If SalesTeamId is provided, verify it belongs to the assigned developer
            Guid? salesTeamId = signupRequest.SalesTeamId;
            if (salesTeamId.HasValue)
            {
                var team = await _context.SalesTeams
                    .FirstOrDefaultAsync(t => t.TeamId == salesTeamId.Value && t.DeveloperId == assignedDeveloperId);
                if (team == null)
                {
                    return BadRequest("Invalid sales team ID or team does not belong to the assigned developer.");
                }
            }
            else
            {
                // Auto-assign to first team of developer if exists
                var firstTeam = await _context.SalesTeams
                    .Where(t => t.DeveloperId == assignedDeveloperId)
                    .OrderBy(t => t.CreatedAt)
                    .FirstOrDefaultAsync();
                if (firstTeam != null)
                {
                    salesTeamId = firstTeam.TeamId;
                }
            }

            // Create Sales account (skip email/phone verification requirements)
            var account = new SalesAccount
            {
                FirstName = signupRequest.FirstName?.Trim() ?? string.Empty,
                LastName = signupRequest.LastName?.Trim() ?? string.Empty,
                Email = normalizedEmail,
                PhoneNumber = normalizedPhone,
                RoleId = Role.SALES_ROLE_ID,
                AssignedDeveloperId = assignedDeveloperId,
                SalesTeamId = salesTeamId,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword(signupRequest.Password),
                Status = VerificationStatus.Verified, // Sales accounts are auto-verified
                EmailVerified = true, // Skip email verification for sales
                PhoneVerified = true, // Skip phone verification for sales
                CreatedAt = DateTime.UtcNow
            };

            _context.SalesAccounts.Add(account);
            
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Database error during sales signup: {Message}", ex.Message);
                
                var innerException = ex.InnerException;
                var detailedMessage = innerException?.Message ?? ex.Message;
                
                if (detailedMessage.Contains("duplicate key") || detailedMessage.Contains("UNIQUE constraint"))
                {
                    if (detailedMessage.Contains("Email") || detailedMessage.Contains("email"))
                        return BadRequest("Email already exists.");
                    if (detailedMessage.Contains("PhoneNumber") || detailedMessage.Contains("phone"))
                        return BadRequest("Phone number already exists.");
                    return BadRequest("An account with this information already exists.");
                }
                
                if (detailedMessage.Contains("foreign key") || detailedMessage.Contains("FOREIGN KEY"))
                {
                    return StatusCode(500, new { 
                        error = "Database configuration error",
                        message = "Required system data is missing. Please contact support.",
                        details = detailedMessage
                    });
                }
                
                return StatusCode(500, new { 
                    error = "An error occurred while creating the sales account",
                    message = detailedMessage
                });
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogError(ex, "Unexpected error during sales signup: {Message}", ex.Message);
                return StatusCode(500, new { 
                    error = "An unexpected error occurred",
                    message = ex.Message
                });
            }

            // Load Role
            var loadedRole = await _context.Roles
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.RoleId == account.RoleId);
            
            if (loadedRole != null)
            {
                account.Role = loadedRole;
            }

            // Sync to Firestore (optional, don't fail if it fails)
            try
            {
                await _firestoreService.SyncUserAsync(account.AccountId, account);
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogWarning(ex, "Firestore sync failed for sales account {AccountId}, but signup succeeded", account.AccountId);
            }

            var token = GenerateJwtToken(account);
            
            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = account.Role?.RoleName ?? "Sales",
                AssignedDeveloperId = account.AssignedDeveloperId,
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.CreatedAt,
                account.UpdatedAt
            };
            
            return Ok(new { Token = token, Account = accountResponse });
        }

        // Google OAuth Sign-In/Sign-Up
        [AllowAnonymous]
        [HttpPost("google-auth")]
        public async Task<IActionResult> GoogleAuth([FromBody] GoogleAuthRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) && string.IsNullOrWhiteSpace(request.GoogleId))
                return BadRequest("Email or Google ID is required.");

            var normalizedEmail = request.Email?.Trim().ToLowerInvariant() ?? string.Empty;

            // Existing user: match by Google ID or email (case-insensitive)
            var existingAccount = await _context.UserAccounts
                .FirstOrDefaultAsync(a =>
                    (!string.IsNullOrEmpty(request.GoogleId) && a.GoogleId == request.GoogleId) ||
                    (normalizedEmail != "" && a.Email.ToLower() == normalizedEmail));

            if (existingAccount != null)
            {
                if (existingAccount.LockedUntil.HasValue && existingAccount.LockedUntil.Value > DateTime.UtcNow)
                {
                    var remainingMinutes = Math.Ceiling((existingAccount.LockedUntil.Value - DateTime.UtcNow).TotalMinutes);
                    return StatusCode(423, new {
                        message = $"Account is locked due to too many failed login attempts. Please try again in {remainingMinutes} minute(s).",
                        lockedUntil = existingAccount.LockedUntil,
                        remainingMinutes = remainingMinutes
                    });
                }

                if (existingAccount.IsSuspended && existingAccount.SuspendedUntil > DateTime.UtcNow)
                {
                    return StatusCode(403, new {
                        message = "Your account has been suspended.",
                        suspendedUntil = existingAccount.SuspendedUntil,
                        reason = existingAccount.SuspensionReason
                    });
                }

                existingAccount.FailedLoginAttempts = 0;
                existingAccount.LockedUntil = null;

                if (string.IsNullOrEmpty(existingAccount.GoogleId))
                {
                    existingAccount.GoogleId = request.GoogleId;
                    existingAccount.AuthProvider = "google";
                }

                await _context.SaveChangesAsync();

                var roleName = await GetRoleNameAsync(existingAccount.RoleId);
                var token = GenerateJwtToken(existingAccount);

                var accountResponse = new
                {
                    existingAccount.AccountId,
                    existingAccount.FirstName,
                    existingAccount.LastName,
                    existingAccount.PhoneNumber,
                    existingAccount.Email,
                    RoleId = existingAccount.RoleId,
                    RoleName = roleName,
                    existingAccount.Status,
                    existingAccount.EmailVerified,
                    existingAccount.PhoneVerified,
                    existingAccount.CreatedAt,
                    existingAccount.UpdatedAt
                };

                return Ok(new { Token = token, Account = accountResponse });
            }

            // Email already registered under another account type — don't create duplicates
            if (normalizedEmail != "" &&
                await _context.Accounts.AnyAsync(a => a.Email.ToLower() == normalizedEmail))
            {
                return Conflict(new {
                    message = "An account with this email already exists. Please sign in with your email and password."
                });
            }

            await _roleSeederService.SeedRolesAsync();

            var newAccount = new UserAccount
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = normalizedEmail != "" ? normalizedEmail : request.Email.Trim(),
                PhoneNumber = "",
                RoleId = Role.USER_ROLE_ID,
                GoogleId = request.GoogleId,
                AuthProvider = "google",
                EmailVerified = true,
                Status = VerificationStatus.NotVerified,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserAccounts.Add(newAccount);
            await _context.SaveChangesAsync();

            try
            {
                await _firestoreService.SyncUserAsync(newAccount.AccountId, newAccount);
            }
            catch (Exception ex)
            {
                var logger = HttpContext.RequestServices.GetRequiredService<ILogger<AccountController>>();
                logger.LogWarning(ex, "Firestore sync failed for Google account {AccountId}", newAccount.AccountId);
            }

            var newRoleName = await GetRoleNameAsync(newAccount.RoleId);
            var newToken = GenerateJwtToken(newAccount);

            var newAccountResponse = new
            {
                newAccount.AccountId,
                newAccount.FirstName,
                newAccount.LastName,
                newAccount.PhoneNumber,
                newAccount.Email,
                RoleId = newAccount.RoleId,
                RoleName = newRoleName,
                newAccount.Status,
                newAccount.EmailVerified,
                newAccount.PhoneVerified,
                newAccount.CreatedAt,
                newAccount.UpdatedAt
            };

            return Ok(new {
                Token = newToken,
                Account = newAccountResponse,
                RequiresProfileCompletion = true
            });
        }

        // Upload single file (for KYC documents, property images, etc.)
        [HttpPost("upload-file")]
        [Authorize]
        public async Task<IActionResult> UploadFile(IFormFile file, [FromForm] string docType)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file provided");

            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            // Validate file type and content
            var validationResult = await _fileValidationService.ValidateFileAsync(file);
            if (!validationResult.IsValid)
            {
                return BadRequest(new { 
                    success = false, 
                    message = validationResult.ErrorMessage,
                    error = "FILE_VALIDATION_FAILED"
                });
            }

            try
            {
                // Create uploads directory if it doesn't exist
                var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "kyc");
                Directory.CreateDirectory(uploadsPath);

                // Generate unique, safe filename
                var fileName = _fileValidationService.GenerateUniqueFileName(file.FileName, userId.Value, docType);
                var filePath = Path.Combine(uploadsPath, fileName);

                // Save file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Return URL
                var fileUrl = $"/uploads/kyc/{fileName}";
                return Ok(new { success = true, url = fileUrl, docType });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    success = false, 
                    message = $"Error uploading file: {ex.Message}" 
                });
            }
        }

        // Upload KYC Documents for existing user
        [HttpPost("upload-kyc")]
        [Authorize]
        public async Task<IActionResult> UploadKycDocuments([FromBody] KycUploadRequest kycRequest)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(userId);
            
            if (account == null)
                return NotFound("Account not found.");

            // Validate KYC documents
            if (kycRequest.KycDocuments == null || kycRequest.KycDocuments.Count == 0)
                return BadRequest("KYC documents are required.");

            var docTypes = kycRequest.KycDocuments.Select(d => d.DocType).ToList();
            bool hasIdDocs = docTypes.Contains("ID_Front") && docTypes.Contains("ID_Back");
            bool hasPassport = docTypes.Contains("Passport");
            
            if (!hasIdDocs && !hasPassport)
                return BadRequest("Please provide either ID (front and back) or Passport.");

            // Check if email and phone are verified first
            if (!account.EmailVerified || !account.PhoneVerified)
            {
                return BadRequest(new { 
                    message = "Please verify your " + 
                        (!account.EmailVerified && !account.PhoneVerified 
                            ? "email and phone" 
                            : (!account.EmailVerified ? "email" : "phone")) + 
                        " before uploading KYC documents.",
                    emailVerified = account.EmailVerified,
                    phoneVerified = account.PhoneVerified
                });
            }

            // Remove existing KYC documents for this user
            var existingDocs = await _context.UserDocs.Where(d => d.UserId == userId).ToListAsync();
            _context.UserDocs.RemoveRange(existingDocs);

            // Add new KYC documents
            foreach (var kycDoc in kycRequest.KycDocuments)
            {
                var userDoc = new UserDoc
                {
                    UserId = userId.Value,
                    DocType = kycDoc.DocType,
                    ImgUrl = kycDoc.ImageUrl,
                    UploadedAt = DateTime.UtcNow
                };
                _context.UserDocs.Add(userDoc);
            }

            // Update account status to Pending after uploading documents
            // (only if email and phone are verified)
            account.Status = VerificationStatus.Pending;
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { 
                success = true, 
                message = "KYC documents uploaded successfully. Status set to Pending.",
                emailVerified = account.EmailVerified,
                phoneVerified = account.PhoneVerified,
                status = account.Status
            });
        }

        // Login
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var normalizedEmail = req.Email?.Trim().ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(normalizedEmail))
                return BadRequest("Email is required.");

            // Case-insensitive lookup; no Role Include (prevents duplicate Role inserts on SaveChanges)
            var account = await _context.Accounts
                .FirstOrDefaultAsync(a => a.Email.ToLower() == normalizedEmail);
            
            // Check if account exists
            if (account == null)
            {
                return Unauthorized(new { message = "Invalid credentials." });
            }

            // Check if account is locked due to failed login attempts
            if (account.LockedUntil.HasValue)
            {
                if (account.LockedUntil.Value > DateTime.UtcNow)
                {
                    // Account is still locked
                    var remainingMinutes = Math.Ceiling((account.LockedUntil.Value - DateTime.UtcNow).TotalMinutes);
                    return StatusCode(423, new {
                        message = $"Account is locked due to too many failed login attempts. Please try again in {remainingMinutes} minute(s).",
                        lockedUntil = account.LockedUntil,
                        remainingMinutes = remainingMinutes
                    });
                }
                else
                {
                    // Lockout period has expired, unlock the account
                    account.LockedUntil = null;
                    account.FailedLoginAttempts = 0;
                    await _context.SaveChangesAsync();
                }
            }

            // Verify password
            if (!BCrypt.Net.BCrypt.Verify(req.Password, account.HashedPassword))
            {
                // Increment failed login attempts
                account.FailedLoginAttempts++;
                
                // Check if we've reached the lockout threshold (5 attempts)
                if (account.FailedLoginAttempts >= 5)
                {
                    // Lock the account for 30 minutes
                    account.LockedUntil = DateTime.UtcNow.AddMinutes(30);
                    await _context.SaveChangesAsync();

                    // Send lockout notification email
                    try
                    {
                        await _emailVerificationService.SendAccountLockoutEmail(
                            account.Email, 
                            account.FirstName, 
                            account.LockedUntil.Value);
                    }
                    catch (Exception ex)
                    {
                        // Log error but don't expose it to user
                        Console.WriteLine($"Error sending lockout email: {ex.Message}");
                    }

                    return StatusCode(423, new {
                        message = "Account has been locked due to too many failed login attempts. An email has been sent with details.",
                        lockedUntil = account.LockedUntil
                    });
                }
                
                await _context.SaveChangesAsync();
                
                var attemptsRemaining = 5 - account.FailedLoginAttempts;
                return Unauthorized(new {
                    message = "Invalid credentials.",
                    attemptsRemaining = attemptsRemaining
                });
            }

            // Successful login - reset failed attempts
            account.FailedLoginAttempts = 0;
            account.LockedUntil = null;

            // Check if account is suspended and auto-unsuspend if expired
            if (account.IsSuspended)
            {
                // Check if suspension period has expired
                if (account.SuspendedUntil.HasValue && account.SuspendedUntil.Value <= DateTime.UtcNow)
                {
                    // Auto-unsuspend if suspension period is over
                    account.IsSuspended = false;
                    account.SuspendedUntil = null;
                    account.SuspensionReason = null;
                }
                // Note: We allow suspended users to login, but they can't place bids
                // Suspension info is included in the account response
            }

            // If password reset was requested, validate the email matches and token hasn't expired
            if (account.RequiresPasswordChange && account.PasswordResetRequestedEmail != null)
            {
                // Check if the email matches the one that requested the reset
                if (account.PasswordResetRequestedEmail != req.Email)
                {
                    return Unauthorized("Password reset was requested for a different email address.");
                }

                // Check if the reset token has expired
                if (account.PasswordResetTokenExpiry.HasValue && account.PasswordResetTokenExpiry.Value < DateTime.UtcNow)
                {
                    // Clear expired reset data
                    account.PasswordResetRequestedEmail = null;
                    account.PasswordResetTokenExpiry = null;
                    account.RequiresPasswordChange = false;
                }
            }

            await _context.SaveChangesAsync();

            var roleName = await GetRoleNameAsync(account.RoleId);
            var token = GenerateJwtToken(account);
            
            // Return account with roleId and roleName explicitly for Flutter compatibility
            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = roleName,
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.RequiresPasswordChange,
                account.IsSuspended,
                account.SuspendedUntil,
                account.SuspensionReason,
                account.CreatedAt,
                account.UpdatedAt
            };
            
            return Ok(new { Token = token, Account = accountResponse });
        }

        // Forgot Password - Generate temporary password and send via email
        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest req)
        {
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == req.Email);
            if (account == null)
            {
                // For security, don't reveal if email exists
                return Ok(new { message = "If the email exists, a temporary password has been sent." });
            }

            // Generate a random temporary password
            var tempPassword = GenerateTemporaryPassword();
            
            // Hash and save the temporary password
            account.HashedPassword = BCrypt.Net.BCrypt.HashPassword(tempPassword);
            account.RequiresPasswordChange = true;
            account.PasswordResetRequestedEmail = req.Email; // Store the email that requested the reset
            account.PasswordResetTokenExpiry = DateTime.UtcNow.AddHours(24); // 24 hour expiry
            account.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();

            // Send email with temporary password
            try
            {
                await _emailVerificationService.SendPasswordResetEmail(account.Email, account.FirstName, tempPassword);
            }
            catch (Exception ex)
            {
                // Log error but don't expose it to user
                Console.WriteLine($"Error sending password reset email: {ex.Message}");
            }

            return Ok(new { message = "If the email exists, a temporary password has been sent." });
        }

        // Force Change Password - After logging in with temporary password
        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.AccountId == userId);
            if (account == null)
                return NotFound("Account not found.");

            // If this is NOT a password reset (RequiresPasswordChange is false),
            // then verify the old password
            if (!account.RequiresPasswordChange)
            {
                if (string.IsNullOrEmpty(req.OldPassword))
                    return BadRequest("Current password is required.");
                
                if (!BCrypt.Net.BCrypt.Verify(req.OldPassword, account.HashedPassword))
                    return BadRequest("Current password is incorrect.");
            }
            // If RequiresPasswordChange is true (temporary password reset),
            // skip old password verification since they already logged in with it

            // Validate new password
            if (req.NewPassword != req.ConfirmPassword)
                return BadRequest("New password and confirmation do not match.");

            var passwordError = ValidatePassword(req.NewPassword);
            if (passwordError != null)
                return BadRequest(passwordError);

            // Update password
            account.HashedPassword = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
            account.RequiresPasswordChange = false;
            account.PasswordResetRequestedEmail = null; // Clear reset tracking
            account.PasswordResetTokenExpiry = null; // Clear reset expiry
            account.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully." });
        }

        private string GenerateTemporaryPassword()
        {
            // Generate a secure random password (8 characters, no special characters)
            const string upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string lowerCase = "abcdefghijklmnopqrstuvwxyz";
            const string numbers = "0123456789";
            
            var random = new Random();
            var password = new char[8];
            
            // Ensure at least one of each type
            password[0] = upperCase[random.Next(upperCase.Length)];
            password[1] = lowerCase[random.Next(lowerCase.Length)];
            password[2] = numbers[random.Next(numbers.Length)];
            
            // Fill the rest randomly
            var allChars = upperCase + lowerCase + numbers;
            for (int i = 3; i < 8; i++)
            {
                password[i] = allChars[random.Next(allChars.Length)];
            }
            
            // Shuffle the password
            return new string(password.OrderBy(x => random.Next()).ToArray());
        }

        private async Task<string> GetRoleNameAsync(Guid roleId)
        {
            return await _context.Roles
                .AsNoTracking()
                .Where(r => r.RoleId == roleId)
                .Select(r => r.RoleName)
                .FirstOrDefaultAsync() ?? "User";
        }

        private string GenerateJwtToken(AccountBase account)
        {
            // Load role from database to get role name
            var role = _context.Roles.FirstOrDefault(r => r.RoleId == account.RoleId);
            var roleName = role?.RoleName ?? "User"; // Fallback to "User" if role not found

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? ""));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, account.AccountId.ToString()),
                new Claim("uid", account.AccountId.ToString()), // Keep for backward compatibility
                new Claim(ClaimTypes.Email, account.Email),
                new Claim("email", account.Email), // Keep for backward compatibility
                new Claim("roleId", account.RoleId.ToString()), // SECURITY: Store non-guessable RoleId
                new Claim("role", roleName), // Role name for backward compatibility
                new Claim(ClaimTypes.Name, account.Email),
                new Claim(ClaimTypes.Role, roleName) // Role name claim
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddHours(24),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        // GET: api/Account/debug-auth (for debugging authentication issues)
        [HttpGet("debug-auth")]
        public ActionResult DebugAuth()
        {
            var authHeader = Request.Headers["Authorization"].ToString();
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
            
            return Ok(new
            {
                hasAuthHeader = !string.IsNullOrEmpty(authHeader),
                authHeaderFormat = string.IsNullOrEmpty(authHeader) ? "Missing" : 
                    (authHeader.StartsWith("Bearer ") ? "Correct (Bearer)" : "Incorrect (should start with 'Bearer ')"),
                isAuthenticated,
                claimsCount = claims.Count,
                claims = claims,
                userId = GetCurrentAccountId(),
                message = isAuthenticated 
                    ? "Authentication successful" 
                    : "Authentication failed - Check Authorization header format: 'Bearer {token}'"
            });
        }

        // GET: api/Account/current or api/Account/me
        [HttpGet("current")]
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult> GetCurrentAccount()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            // SECURITY: Return minimal information - no role names, account types, or internal status details
            // Only return RoleId (non-guessable GUID) to avoid revealing system architecture
            var totalEarnedPoints = account.TotalEarnedPoints;
            var currentPoints = account.CurrentPoints;
            var topBadge = await _context.UserBadges.Where(b => b.AccountId == account.AccountId).OrderByDescending(b => b.AwardedAt).FirstOrDefaultAsync();
            var roleName = await GetRoleNameAsync(account.RoleId);

            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = roleName,
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.RequiresPasswordChange,
                account.IsSuspended,
                account.SuspendedUntil,
                account.SuspensionReason,
                account.CreatedAt,
                account.UpdatedAt,
                TotalEarnedPoints = totalEarnedPoints,
                CurrentPoints = currentPoints,
                TopBadgeIcon = topBadge?.BadgeIcon,
                TopBadgeName = topBadge?.BadgeName
            };

            return Ok(accountResponse);
        }

        // GET: api/Account/rewards
        [HttpGet("rewards")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<UserReward>>> GetMyRewards()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null) return Unauthorized();
            var rewards = await _context.UserRewards
                .Where(r => r.AccountId == accountId)
                .OrderByDescending(r => r.EarnedAt)
                .Take(200)
                .ToListAsync();
            return Ok(rewards);
        }

        // GET: api/Account/badges
        [HttpGet("badges")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<UserBadge>>> GetMyBadges()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null) return Unauthorized();
            var badges = await _context.UserBadges
                .Where(b => b.AccountId == accountId)
                .OrderByDescending(b => b.AwardedAt)
                .ToListAsync();
            return Ok(badges);
        }


        // PUT: api/Account/current
        [HttpPut("current")]
        [Authorize]
        public async Task<ActionResult> UpdateAccount([FromBody] AccountUpdateDto updateDto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            bool emailChanged = false;
            bool phoneChanged = false;

            // Update fields and detect changes
            if (!string.IsNullOrEmpty(updateDto.FirstName))
                account.FirstName = updateDto.FirstName;
            if (!string.IsNullOrEmpty(updateDto.LastName))
                account.LastName = updateDto.LastName;
            
            // Check if phone number changed
            if (!string.IsNullOrEmpty(updateDto.PhoneNumber) && updateDto.PhoneNumber != account.PhoneNumber)
            {
                account.PhoneNumber = updateDto.PhoneNumber;
                account.PhoneVerified = false; // Invalidate phone verification
                account.PhoneVerificationPin = null;
                account.PhoneVerificationPinExpiry = null;
                phoneChanged = true;
            }
            
            // Check if email changed
            if (!string.IsNullOrEmpty(updateDto.Email) && updateDto.Email != account.Email)
            {
                account.Email = updateDto.Email;
                account.EmailVerified = false; // Invalidate email verification
                account.EmailVerificationPin = null;
                account.EmailVerificationPinExpiry = null;
                emailChanged = true;
            }

            // Mark account as not verified when profile is updated (for KYC purposes)
            account.Status = VerificationStatus.NotVerified;
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            
            // Return updated account with verification status (excluding sensitive PIN data)
            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                RoleId = account.RoleId,
                RoleName = account.Role != null ? account.Role.RoleName : "Unknown",
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.IsSuspended,
                account.SuspendedUntil,
                account.SuspensionReason,
                account.FailedLoginAttempts,
                account.LockedUntil,
                account.CreatedAt,
                account.UpdatedAt
            };
            
            return Ok(new { 
                account = accountResponse, 
                emailChanged,
                phoneChanged,
                message = (emailChanged || phoneChanged) 
                    ? "Profile updated. Please verify your " + 
                      (emailChanged && phoneChanged ? "email and phone" : 
                       emailChanged ? "email" : "phone") + "."
                    : "Profile updated successfully."
            });
        }

        // PUT: api/Account/change-password
        [HttpPut("change-password")]
        [Authorize]
        public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordDto changePasswordDto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            // Verify current password
            if (!BCrypt.Net.BCrypt.Verify(changePasswordDto.CurrentPassword, account.HashedPassword))
                return BadRequest("Current password is incorrect.");

            // Validate new password
            var passwordError = ValidatePassword(changePasswordDto.NewPassword);
            if (passwordError != null)
                return BadRequest(passwordError);

            // Update password (does NOT affect verification status)
            account.HashedPassword = BCrypt.Net.BCrypt.HashPassword(changePasswordDto.NewPassword);
            account.RequiresPasswordChange = false;
            account.PasswordResetRequestedEmail = null; // Clear reset tracking
            account.PasswordResetTokenExpiry = null; // Clear reset expiry
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            
            return Ok(new { message = "Password changed successfully" });
        }

        // POST: api/Account/kyc
        [HttpPost("kyc")]
        [Authorize]
        public async Task<ActionResult> UploadKycDocument([FromBody] KycUploadDto kycDto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            // Check if document type already exists for this user
            var existingDoc = await _context.UserDocs
                .FirstOrDefaultAsync(d => d.UserId == accountId && d.DocType == kycDto.DocType);

            if (existingDoc != null)
            {
                // Update existing document
                existingDoc.ImgUrl = kycDto.ImageUrl;
                existingDoc.UploadedAt = DateTime.UtcNow;
            }
            else
            {
                // Create new document
                var userDoc = new UserDoc
                {
                    UserId = accountId.Value,
                    DocType = kycDto.DocType,
                    ImgUrl = kycDto.ImageUrl,
                    UploadedAt = DateTime.UtcNow
                };
                _context.UserDocs.Add(userDoc);
            }

            // Check if user has uploaded sufficient documents to mark as Pending
            var userDocs = await _context.UserDocs.Where(d => d.UserId == accountId).ToListAsync();
            var docTypes = userDocs.Select(d => d.DocType).ToList();
            bool hasIdDocs = docTypes.Contains("ID_Front") && docTypes.Contains("ID_Back");
            bool hasPassport = docTypes.Contains("Passport");
            
            // Update status to Pending ONLY if user has:
            // 1. Uploaded complete documents (ID or Passport)
            // 2. Verified email
            // 3. Verified phone
            if ((hasIdDocs || hasPassport) && account.EmailVerified && account.PhoneVerified)
            {
                account.Status = VerificationStatus.Pending;
                account.UpdatedAt = DateTime.UtcNow;
            }
            else if ((hasIdDocs || hasPassport) && (!account.EmailVerified || !account.PhoneVerified))
            {
                // Documents uploaded but email/phone not verified
                account.Status = VerificationStatus.NotVerified;
                account.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            
            var message = (hasIdDocs || hasPassport)
                ? (account.EmailVerified && account.PhoneVerified
                    ? "KYC documents uploaded successfully. Status set to Pending."
                    : "KYC documents uploaded. Please verify your " +
                      (!account.EmailVerified && !account.PhoneVerified 
                        ? "email and phone" 
                        : (!account.EmailVerified ? "email" : "phone")) + 
                      " to submit for review.")
                : "KYC document uploaded successfully";
            
            return Ok(new { 
                success = true, 
                message,
                emailVerified = account.EmailVerified,
                phoneVerified = account.PhoneVerified,
                status = account.Status
            });
        }

        // GET: api/Account/kyc
        [HttpGet("kyc")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<UserDoc>>> GetKycDocuments()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var documents = await _context.UserDocs
                .Where(d => d.UserId == accountId)
                .ToListAsync();

            return Ok(documents);
        }

        // GET: api/Account/kyc/{userId}
        [HttpGet("kyc/{userId}")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<UserDoc>>> GetUserKycDocuments(Guid userId)
        {
            var documents = await _context.UserDocs
                .Include(d => d.User)
                .Where(d => d.UserId == userId)
                .ToListAsync();

            return Ok(documents);
        }

        // PUT: api/Account/kyc/{userId}/verify
        [HttpPut("kyc/{userId}/verify")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult> VerifyUserKyc(Guid userId)
        {
            var account = await _context.Accounts.FindAsync(userId);
            if (account == null)
                return NotFound("User not found");

            // Check if email and phone are verified
            if (!account.EmailVerified)
                return BadRequest("User must verify their email before KYC approval");
            
            if (!account.PhoneVerified)
                return BadRequest("User must verify their phone before KYC approval");

            // Verify the user's KYC (only if email and phone are verified)
            account.Status = VerificationStatus.Verified;
            account.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "User KYC verified successfully",
                emailVerified = account.EmailVerified,
                phoneVerified = account.PhoneVerified,
                status = account.Status
            });
        }

        // GET: api/Account/kyc/pending
        [HttpGet("kyc/pending")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<object>>> GetPendingKycUsers()
        {
            var pendingUsers = await _context.Accounts
                .Where(a => a.Status == VerificationStatus.Pending && a.RoleId == Role.USER_ROLE_ID)
                .Select(a => new
                {
                    a.AccountId,
                    a.FirstName,
                    a.LastName,
                    a.Email,
                    a.Status,
                    KycDocumentsCount = _context.UserDocs.Count(d => d.UserId == a.AccountId)
                })
                .ToListAsync();

            return Ok(pendingUsers);
        }

        // POST: api/Account/send-email-verification
        [HttpPost("send-email-verification")]
        [Authorize]
        public async Task<ActionResult> SendEmailVerification()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound("Account not found");

            // Generate PIN and set expiry
            var pin = _emailVerificationService.GenerateEmailPin();
            account.EmailVerificationPin = pin;
            account.EmailVerificationPinExpiry = _emailVerificationService.GetPinExpiry();

            await _context.SaveChangesAsync();

            // Send email
            var emailSent = await _emailVerificationService.SendVerificationEmail(
                account.Email, 
                pin, 
                account.FirstName);

            return Ok(new { message = "Verification PIN sent to your email" });
        }

        // POST: api/Account/verify-email
        [HttpPost("verify-email")]
        [Authorize]
        public async Task<ActionResult> VerifyEmail([FromBody] VerifyPinDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound("Account not found");

            // Check if PIN is valid
            if (!_emailVerificationService.IsPinValid(account.EmailVerificationPinExpiry))
                return BadRequest("PIN has expired. Please request a new one.");

            // Verify PIN
            if (account.EmailVerificationPin != dto.Pin)
                return BadRequest("Invalid PIN");

            // Mark email as verified
            account.EmailVerified = true;
            account.EmailVerificationPin = null;
            account.EmailVerificationPinExpiry = null;
            account.PreviousEmail = account.Email; // Store verified email
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Email verified successfully", 
                emailVerified = true 
            });
        }

        // POST: api/Account/send-phone-verification
        [HttpPost("send-phone-verification")]
        [Authorize]
        public async Task<ActionResult> SendPhoneVerification()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
            {
                return Unauthorized(new { 
                    message = "Authentication failed. Please ensure you are logged in and your token is valid.",
                    error = "UNAUTHORIZED"
                });
            }

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound(new { 
                    message = "Account not found",
                    error = "ACCOUNT_NOT_FOUND"
                });

            // Validate phone number exists
            if (string.IsNullOrWhiteSpace(account.PhoneNumber))
            {
                return BadRequest(new { 
                    message = "Phone number is required. Please update your profile with a phone number first.",
                    error = "PHONE_NUMBER_MISSING",
                    requiresPhoneNumber = true
                });
            }

            // Validate phone number format (basic check)
            var phoneDigits = account.PhoneNumber.Where(char.IsDigit).Count();
            if (phoneDigits < 10)
            {
                return BadRequest(new { 
                    message = "Phone number appears to be invalid. Please ensure it includes country code (e.g., +1234567890 or +201234567890).",
                    error = "PHONE_NUMBER_INVALID",
                    phoneNumber = account.PhoneNumber,
                    digitCount = phoneDigits
                });
            }

            // Generate PIN and set expiry
            var pin = _phoneVerificationService.GeneratePhonePin();
            account.PhoneVerificationPin = pin;
            account.PhoneVerificationPinExpiry = _phoneVerificationService.GetPinExpiry();

            await _context.SaveChangesAsync();

            // Send SMS
            var smsSent = await _phoneVerificationService.SendVerificationSMS(
                account.PhoneNumber, 
                pin, 
                account.FirstName);

            if (!smsSent)
            {
                return StatusCode(500, new { 
                    message = "Failed to send verification SMS. Please try again later or contact support.",
                    error = "SMS_SEND_FAILED"
                });
            }

            return Ok(new { 
                message = "Verification PIN sent to your phone",
                phoneNumber = account.PhoneNumber // Return masked phone number for confirmation
            });
        }

        // POST: api/Account/verify-phone
        [HttpPost("verify-phone")]
        [Authorize]
        public async Task<ActionResult> VerifyPhone([FromBody] VerifyPinDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound("Account not found");

            // Check if PIN is valid
            if (!_phoneVerificationService.IsPinValid(account.PhoneVerificationPinExpiry))
                return BadRequest("PIN has expired. Please request a new one.");

            // Verify PIN
            if (account.PhoneVerificationPin != dto.Pin)
                return BadRequest("Invalid PIN");

            // Mark phone as verified
            account.PhoneVerified = true;
            account.PhoneVerificationPin = null;
            account.PhoneVerificationPinExpiry = null;
            account.PreviousPhoneNumber = account.PhoneNumber; // Store verified phone
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Phone verified successfully", 
                phoneVerified = true 
            });
        }

        // GET: api/Account/export-data (GDPR Compliance)
        [HttpGet("export-data")]
        [Authorize]
        public async Task<ActionResult> ExportData()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts
                .Include(a => a.Bids)
                .FirstOrDefaultAsync(a => a.AccountId == accountId);

            if (account == null)
                return NotFound("Account not found");

            // Compile all user data for export
            var exportData = new
            {
                PersonalInformation = new
                {
                    account.FirstName,
                    account.LastName,
                    account.Email,
                    account.PhoneNumber,
                    RoleId = account.RoleId,
                RoleName = account.Role != null ? account.Role.RoleName : "Unknown",
                    account.CreatedAt,
                    account.UpdatedAt
                },
                Verification = new
                {
                    account.EmailVerified,
                    account.PhoneVerified,
                    account.Status
                },
                Properties = _context.Properties.Where(p => p.OwnerId == accountId).Select(p => new
                {
                    p.PropertyId,
                    p.Name,
                    p.Description,
                    p.Location,
                    p.Type,
                    p.Status,
                    p.CreatedAt
                }).ToList(),
                Bids = account.Bids?.Select(b => new
                {
                    b.BidId,
                    b.AuctionId,
                    b.BidAmount,
                    b.CreatedAt
                }).ToList(),
                AccountStatus = new
                {
                    account.IsSuspended,
                    account.SuspensionReason,
                    IsLocked = account.LockedUntil.HasValue && account.LockedUntil.Value > DateTime.UtcNow,
                    account.LockedUntil,
                    account.FailedLoginAttempts
                }
            };

            return Ok(new
            {
                message = "User data export completed",
                exportDate = DateTime.UtcNow,
                data = exportData
            });
        }

        // DELETE: api/Account/delete-account (GDPR Compliance)
        [HttpDelete("delete-account")]
        [Authorize]
        public async Task<ActionResult> DeleteAccount([FromBody] DeleteAccountDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts
                .Include(a => a.Bids)
                .FirstOrDefaultAsync(a => a.AccountId == accountId);

            if (account == null)
                return NotFound("Account not found");

            // Verify password before deletion (skip for OAuth users)
            if (account.HashedPassword != null && !BCrypt.Net.BCrypt.Verify(dto.Password, account.HashedPassword))
                return BadRequest("Invalid password. Account deletion failed.");

            // Check for active auctions or pending transactions
            var activeProperties = await _context.Properties
                .Where(p => p.OwnerId == accountId && 
                    (p.Status == PropertyStatus.Pending || p.Status == PropertyStatus.Approved))
                .ToListAsync();
            
            if (activeProperties != null && activeProperties.Any())
            {
                return BadRequest(new
                {
                    message = "Cannot delete account with active properties. Please complete or cancel all active listings first.",
                    activePropertyCount = activeProperties.Count()
                });
            }

            // Soft delete: Mark account as deleted but keep for legal retention
            account.Email = $"deleted_{account.AccountId}@deleted.local";
            account.PhoneNumber = $"deleted_{account.AccountId}";
            account.HashedPassword = null;
            account.FirstName = "Deleted";
            account.LastName = "User";
            // Clear GoogleId if it's a UserAccount
            if (account is UserAccount userAccount)
            {
                userAccount.GoogleId = null;
            }
            account.IsSuspended = true;
            account.SuspensionReason = "Account deleted by user request";
            account.UpdatedAt = DateTime.UtcNow;
            account.EmailVerified = false;
            account.PhoneVerified = false;
            account.Status = VerificationStatus.NotVerified;
            
            // Clear sensitive data
            account.EmailVerificationPin = null;
            account.PhoneVerificationPin = null;
            account.PasswordResetRequestedEmail = null;
            account.PasswordResetTokenExpiry = null;

            await _context.SaveChangesAsync();

            // Update Firestore
            try
            {
                // Firestore sync removed for now - can be re-added if needed
                // await _firestoreService.SyncAccountAsync(account);
            }
            catch (Exception)
            {
                // Log error but don't fail the deletion
            }

            return Ok(new
            {
                message = "Account deleted successfully. Your data has been anonymized.",
                deletedAt = DateTime.UtcNow
            });
        }

        private Guid? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null && Guid.TryParse(uidClaim.Value, out var guid) ? guid : null;
        }

        /// <summary>
        /// Validates password strength and security requirements
        /// </summary>
        private string? ValidatePassword(string password)
        {
            // Check minimum length
            if (password.Length < 8)
                return "Password must be at least 8 characters long.";

            // Check maximum length (prevent DoS via excessive hashing time)
            if (password.Length > 128)
                return "Password must not exceed 128 characters.";

            // Check for letters
            if (!System.Text.RegularExpressions.Regex.IsMatch(password, @"[a-zA-Z]"))
                return "Password must contain at least one letter.";

            // Check for numbers
            if (!System.Text.RegularExpressions.Regex.IsMatch(password, @"[0-9]"))
                return "Password must contain at least one number.";

            // Password is valid
            return null;
        }
    }

    public class SignupRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? TimeZone { get; set; } // User's preferred timezone (IANA timezone ID)
        // SECURITY: Type removed - all signups create User accounts only. Only admins can promote to Developer/Admin.
    }

    public class GoogleAuthRequest
    {
        public string GoogleId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }

    public class KycUploadRequest
    {
        public List<KycDocumentDto> KycDocuments { get; set; } = new List<KycDocumentDto>();
    }

    public class KycDocumentDto
    {
        public string DocType { get; set; } = string.Empty; // ID_Front, ID_Back, Passport
        public string ImageUrl { get; set; } = string.Empty;
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    public class ChangePasswordRequest
    {
        public string? OldPassword { get; set; }
        public string NewPassword { get; set; } = string.Empty;
        public string ConfirmPassword { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public AccountBase? Account { get; set; }
        public bool RequiresProfileCompletion { get; set; } = false;
    }

    public class AccountUpdateDto
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
    }

    public class KycUploadDto
    {
        public string DocType { get; set; } = string.Empty; // ID_Front, ID_Back, Passport
        public string ImageUrl { get; set; } = string.Empty;
    }

    public class ChangePasswordDto
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class VerifyPinDto
    {
        public string Pin { get; set; } = string.Empty;
    }

    public class DeleteAccountDto
    {
        public string Password { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
    }

    public class SalesSignupRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public Guid? DeveloperId { get; set; } // Required if admin, ignored if developer (auto-assigned)
        public Guid? SalesTeamId { get; set; } // Optional: assign to specific team
    }
}

