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
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;
        private readonly EmailVerificationService _emailVerificationService;
        private readonly PhoneVerificationService _phoneVerificationService;
        private readonly FirestoreService _firestoreService;
        private readonly FileValidationService _fileValidationService;
        private readonly RewardService _rewardService;

        public AccountController(
            AppDbContext context, 
            IConfiguration config,
            EmailVerificationService emailVerificationService,
            PhoneVerificationService phoneVerificationService,
            FirestoreService firestoreService,
            FileValidationService fileValidationService,
            RewardService rewardService)
        {
            _context = context;
            _config = config;
            _emailVerificationService = emailVerificationService;
            _phoneVerificationService = phoneVerificationService;
            _firestoreService = firestoreService;
            _fileValidationService = fileValidationService;
            _rewardService = rewardService;
        }

        // Check if email exists
        [HttpGet("check-email")]
        public async Task<IActionResult> CheckEmail([FromQuery] string email)
        {
            var exists = await _context.Accounts.AnyAsync(a => a.Email == email);
            return Ok(new { exists });
        }

        // Check if phone exists
        [HttpGet("check-phone")]
        public async Task<IActionResult> CheckPhone([FromQuery] string phone)
        {
            var exists = await _context.Accounts.AnyAsync(a => a.PhoneNumber == phone);
            return Ok(new { exists });
        }

        // Signup - Create account without KYC
        [HttpPost("signup")]
        public async Task<IActionResult> Signup([FromBody] SignupRequest signupRequest)
        {
            if (await _context.Accounts.AnyAsync(a => a.Email == signupRequest.Email))
                return BadRequest("Email already exists.");

            if (await _context.Accounts.AnyAsync(a => a.PhoneNumber == signupRequest.PhoneNumber))
                return BadRequest("Phone number already exists.");

            // Validate password
            var passwordError = ValidatePassword(signupRequest.Password);
            if (passwordError != null)
                return BadRequest(passwordError);

            var account = new Account
            {
                FirstName = signupRequest.FirstName,
                LastName = signupRequest.LastName,
                Email = signupRequest.Email,
                PhoneNumber = signupRequest.PhoneNumber,
                Type = signupRequest.Type,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword(signupRequest.Password),
                Status = VerificationStatus.NotVerified, // Will be verified by admin after KYC review
                CreatedAt = DateTime.UtcNow
            };

            _context.Accounts.Add(account);
            await _context.SaveChangesAsync();

            // Sync new user to Firestore for real-time dashboard updates
            await _firestoreService.SyncUserAsync(account.AccountId, account);

            var token = GenerateJwtToken(account);
            return Ok(new AuthResponse { Token = token, Account = account });
        }

        // Google OAuth Sign-In/Sign-Up
        [HttpPost("google-auth")]
        public async Task<IActionResult> GoogleAuth([FromBody] GoogleAuthRequest request)
        {
            // Check if account exists with this Google ID
            var existingAccount = await _context.Accounts
                .FirstOrDefaultAsync(a => a.GoogleId == request.GoogleId || a.Email == request.Email);

            if (existingAccount != null)
            {
                // User exists - login
                
                // Check if account is locked due to failed login attempts
                if (existingAccount.LockedUntil.HasValue && existingAccount.LockedUntil.Value > DateTime.UtcNow)
                {
                    var remainingMinutes = Math.Ceiling((existingAccount.LockedUntil.Value - DateTime.UtcNow).TotalMinutes);
                    return StatusCode(423, new {
                        message = $"Account is locked due to too many failed login attempts. Please try again in {remainingMinutes} minute(s).",
                        lockedUntil = existingAccount.LockedUntil,
                        remainingMinutes = remainingMinutes
                    });
                }
                
                // Check if account is suspended
                if (existingAccount.IsSuspended && existingAccount.SuspendedUntil > DateTime.UtcNow)
                {
                    return StatusCode(403, new {
                        message = "Your account has been suspended.",
                        suspendedUntil = existingAccount.SuspendedUntil,
                        reason = existingAccount.SuspensionReason
                    });
                }

                // Successful OAuth login - reset failed attempts and lockout
                existingAccount.FailedLoginAttempts = 0;
                existingAccount.LockedUntil = null;

                // Update GoogleId if not set
                if (string.IsNullOrEmpty(existingAccount.GoogleId))
                {
                    existingAccount.GoogleId = request.GoogleId;
                    existingAccount.AuthProvider = "google";
                }
                
                await _context.SaveChangesAsync();

                var token = GenerateJwtToken(existingAccount);
                return Ok(new AuthResponse { Token = token, Account = existingAccount });
            }

            // Create new account - minimal info from Google
            var newAccount = new Account
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                PhoneNumber = "", // Will be filled later
                Type = AccountType.User,
                GoogleId = request.GoogleId,
                AuthProvider = "google",
                EmailVerified = true, // Google emails are verified
                Status = VerificationStatus.NotVerified, // Still needs KYC
                CreatedAt = DateTime.UtcNow
            };

            _context.Accounts.Add(newAccount);
            await _context.SaveChangesAsync();

            // Sync new user to Firestore
            await _firestoreService.SyncUserAsync(newAccount.AccountId, newAccount);

            var newToken = GenerateJwtToken(newAccount);
            return Ok(new AuthResponse { 
                Token = newToken, 
                Account = newAccount,
                RequiresProfileCompletion = true // Indicate that profile needs completion
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

            var account = await _context.Accounts.FindAsync((long)userId);
            
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
            var existingDocs = await _context.UserDocs.Where(d => d.UserId == (long)userId).ToListAsync();
            _context.UserDocs.RemoveRange(existingDocs);

            // Add new KYC documents
            foreach (var kycDoc in kycRequest.KycDocuments)
            {
                var userDoc = new UserDoc
                {
                    UserId = (long)userId,
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
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == req.Email);
            
            // Check if account exists
            if (account == null)
            {
                return Unauthorized("Invalid credentials.");
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

            var token = GenerateJwtToken(account);
            return Ok(new AuthResponse { Token = token, Account = account });
        }

        // Forgot Password - Generate temporary password and send via email
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

        private string GenerateJwtToken(Account account)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? ""));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, account.AccountId.ToString()),
                new Claim("uid", account.AccountId.ToString()), // Keep for backward compatibility
                new Claim(ClaimTypes.Email, account.Email),
                new Claim("email", account.Email), // Keep for backward compatibility
                new Claim("type", account.Type.ToString()),
                new Claim(ClaimTypes.Name, account.Email),
                new Claim(ClaimTypes.Role, account.Type.ToString()) // Add proper Role claim: "User", "Developer", or "Admin"
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

        // GET: api/Account/current
        [HttpGet("current")]
        [Authorize]
        public async Task<ActionResult> GetCurrentAccount()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            // Return account without sensitive PIN data
            var totalEarnedPoints = account.TotalEarnedPoints;
            var currentPoints = account.CurrentPoints;
            var topBadge = await _context.UserBadges.Where(b => b.AccountId == account.AccountId).OrderByDescending(b => b.AwardedAt).FirstOrDefaultAsync();

            var accountResponse = new
            {
                account.AccountId,
                account.FirstName,
                account.LastName,
                account.PhoneNumber,
                account.Email,
                account.Type,
                account.Status,
                account.EmailVerified,
                account.PhoneVerified,
                account.IsSuspended,
                account.SuspendedUntil,
                account.SuspensionReason,
                account.FailedLoginAttempts,
                account.LockedUntil,
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

        // GET: api/Account/me (alias for current)
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult> GetMe()
        {
            return await GetCurrentAccount();
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
                account.Type,
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
        public async Task<ActionResult<IEnumerable<UserDoc>>> GetUserKycDocuments(long userId)
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
        public async Task<ActionResult> VerifyUserKyc(long userId)
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
                .Where(a => a.Status == VerificationStatus.Pending && a.Type == AccountType.User)
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
            await _emailVerificationService.SendVerificationEmail(
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
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound("Account not found");

            // Generate PIN and set expiry
            var pin = _phoneVerificationService.GeneratePhonePin();
            account.PhoneVerificationPin = pin;
            account.PhoneVerificationPinExpiry = _phoneVerificationService.GetPinExpiry();

            await _context.SaveChangesAsync();

            // Send SMS
            await _phoneVerificationService.SendVerificationSMS(
                account.PhoneNumber, 
                pin, 
                account.FirstName);

            return Ok(new { message = "Verification PIN sent to your phone" });
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
                    account.Type,
                    account.CreatedAt,
                    account.UpdatedAt
                },
                Verification = new
                {
                    account.EmailVerified,
                    account.PhoneVerified,
                    account.Status
                },
                Properties = _context.ChildProperties.Where(p => p.OwnerId == accountId).Select(p => new
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
            var activeProperties = await _context.ChildProperties
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
            account.GoogleId = null;
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

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
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
        public AccountType Type { get; set; } = AccountType.User;
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
        public Account? Account { get; set; }
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
}

