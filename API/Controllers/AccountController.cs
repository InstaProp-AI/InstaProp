using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Attributes;
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

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public AccountController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
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

            var token = GenerateJwtToken(account);
            return Ok(new AuthResponse { Token = token, Account = account });
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

            try
            {
                // Create uploads directory if it doesn't exist
                var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "kyc");
                Directory.CreateDirectory(uploadsPath);

                // Generate unique filename
                var fileName = $"{userId}_{docType}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
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
                return StatusCode(500, $"Error uploading file: {ex.Message}");
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
            account.Status = VerificationStatus.Pending;
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "KYC documents uploaded successfully. Status set to Pending." });
        }

        // Login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == req.Email);
            if (account == null || !BCrypt.Net.BCrypt.Verify(req.Password, account.HashedPassword))
                return Unauthorized("Invalid credentials.");

            var token = GenerateJwtToken(account);
            return Ok(new AuthResponse { Token = token, Account = account });
        }

        private string GenerateJwtToken(Account account)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? ""));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim("uid", account.AccountId.ToString()),
                new Claim("email", account.Email),
                new Claim("type", account.Type.ToString()),
                new Claim(ClaimTypes.Name, account.Email)
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddDays(7),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        // GET: api/Account/current
        [HttpGet("current")]
        [Authorize]
        public async Task<ActionResult<Account>> GetCurrentAccount()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null)
                return NotFound();

            return Ok(account);
        }

        // GET: api/Account/me (alias for current)
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<Account>> GetMe()
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

            // Update fields
            if (!string.IsNullOrEmpty(updateDto.FirstName))
                account.FirstName = updateDto.FirstName;
            if (!string.IsNullOrEmpty(updateDto.LastName))
                account.LastName = updateDto.LastName;
            if (!string.IsNullOrEmpty(updateDto.PhoneNumber))
                account.PhoneNumber = updateDto.PhoneNumber;
            if (!string.IsNullOrEmpty(updateDto.Email))
                account.Email = updateDto.Email;

            // Mark account as not verified when profile is updated
            account.Status = VerificationStatus.NotVerified;
            account.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            
            // Return updated account
            return Ok(account);
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
            
            // Update status to Pending if user has uploaded complete documents
            if (hasIdDocs || hasPassport)
            {
                account.Status = VerificationStatus.Pending;
                account.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "KYC document uploaded successfully" });
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

            // Verify the user's KYC
            account.Status = VerificationStatus.Verified;
            account.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "User KYC verified successfully" });
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

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
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


    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public Account? Account { get; set; }
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
}

