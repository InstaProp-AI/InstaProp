using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DocumentController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ImgBBService _imgBBService;
        private readonly FileValidationService _fileValidationService;
        private readonly ILogger<DocumentController> _logger;

        public DocumentController(
            AppDbContext context,
            ImgBBService imgBBService,
            FileValidationService fileValidationService,
            ILogger<DocumentController> logger)
        {
            _context = context;
            _imgBBService = imgBBService;
            _fileValidationService = fileValidationService;
            _logger = logger;
        }

        // ==================== USER DOCUMENTS (KYC) ====================

        /// <summary>
        /// Upload a KYC document during registration (NO AUTH REQUIRED).
        /// Accepts: ID_Front, ID_Back, Passport (single document).
        /// Only allowed for accounts in NotVerified or Pending status — Verified accounts must use the authenticated endpoint.
        /// Status flow: NotVerified -> Pending (when any doc uploaded).
        /// Security: Error responses are intentionally vague to prevent email enumeration.
        /// </summary>
        [HttpPost("public/upload")]
        [AllowAnonymous]
        public async Task<IActionResult> UploadPublicDocument(
            IFormFile file, 
            [FromForm] string docType,
            [FromForm] string email)
        {
            try
            {
                if (string.IsNullOrEmpty(email))
                    return BadRequest(new { message = "Invalid request." });

                if (string.IsNullOrEmpty(docType))
                    return BadRequest(new { message = "Document type is required." });

                // Validate document type
                var validDocTypes = new[] { "ID_Front", "ID_Back", "Passport" };
                if (!validDocTypes.Contains(docType))
                    return BadRequest(new { message = $"Invalid document type. Allowed: {string.Join(", ", validDocTypes)}" });

                // Find user by email — use generic error to prevent email enumeration
                var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Email == email);
                if (account == null)
                    return BadRequest(new { message = "Invalid request. Please ensure your account is registered first." });

                // Block uploads for already-verified accounts — they must use authenticated endpoint
                if (account.Status == VerificationStatus.Verified)
                    return BadRequest(new { message = "Invalid request." });

                // Validate file
                var validationResult = await _fileValidationService.ValidateFileAsync(file);
                if (!validationResult.IsValid)
                    return BadRequest(new { message = validationResult.ErrorMessage });

                // Convert file to byte array
                byte[] fileBytes;
                using (var memoryStream = new MemoryStream())
                {
                    await file.CopyToAsync(memoryStream);
                    fileBytes = memoryStream.ToArray();
                }

                // Upload to ImgBB
                var uploadResult = await _imgBBService.UploadImageAsync(
                    fileBytes,
                    $"kyc_{account.AccountId}_{docType}_{DateTime.UtcNow.Ticks}",
                    0 // No expiration
                );

                // Check if document type already exists
                var existingDoc = await _context.UserDocs
                    .FirstOrDefaultAsync(d => d.UserId == account.AccountId && d.DocType == docType);

                if (existingDoc != null)
                {
                    // Delete old document reference and update
                    existingDoc.ImgUrl = uploadResult.DisplayUrl;
                    existingDoc.DeleteUrl = uploadResult.DeleteUrl;
                    existingDoc.UploadedAt = DateTime.UtcNow;
                    _logger.LogInformation($"Updated existing KYC document {docType} for user {account.AccountId}");
                }
                else
                {
                    // Create new document
                    var userDoc = new UserDoc
                    {
                        UserId = account.AccountId,
                        DocType = docType,
                        ImgUrl = uploadResult.DisplayUrl,
                        DeleteUrl = uploadResult.DeleteUrl,
                        UploadedAt = DateTime.UtcNow
                    };
                    _context.UserDocs.Add(userDoc);
                    _logger.LogInformation($"Added new KYC document {docType} for user {account.AccountId}");
                }

                await _context.SaveChangesAsync();

                // Auto-update status to Pending if user has uploaded any document
                if (account.Status == VerificationStatus.NotVerified)
                {
                    var docCount = await _context.UserDocs.CountAsync(d => d.UserId == account.AccountId);
                    if (docCount > 0)
                    {
                        account.Status = VerificationStatus.Pending;
                        await _context.SaveChangesAsync();
                        _logger.LogInformation($"Updated account {account.Email} status to Pending");
                    }
                }

                return Ok(new
                {
                    message = "Document uploaded successfully",
                    url = uploadResult.DisplayUrl,
                    docType = docType,
                    accountStatus = account.Status.ToString()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading public KYC document for email {Email}", email);
                return StatusCode(500, new { message = "Failed to upload document", error = ex.Message });
            }
        }

        /// <summary>
        /// Upload a KYC document for the authenticated user
        /// Accepts: ID_Front, ID_Back, Passport (single document)
        /// Status flow: NotVerified -> Pending (when any doc uploaded)
        /// </summary>
        [HttpPost("user/upload")]
        public async Task<IActionResult> UploadUserDocument(IFormFile file, [FromForm] string docType)
        {
            var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            try
            {
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                if (string.IsNullOrEmpty(docType))
                    return BadRequest(new { message = "Document type is required" });

                // Validate document type
                var validDocTypes = new[] { "ID_Front", "ID_Back", "Passport" };
                if (!validDocTypes.Contains(docType))
                    return BadRequest(new { message = $"Invalid document type. Allowed: {string.Join(", ", validDocTypes)}" });

                // Validate file
                var validationResult = await _fileValidationService.ValidateFileAsync(file);
                if (!validationResult.IsValid)
                    return BadRequest(new { message = validationResult.ErrorMessage });

                // Convert file to byte array
                byte[] fileBytes;
                using (var memoryStream = new MemoryStream())
                {
                    await file.CopyToAsync(memoryStream);
                    fileBytes = memoryStream.ToArray();
                }

                // Upload to ImgBB
                var uploadResult = await _imgBBService.UploadImageAsync(
                    fileBytes,
                    $"kyc_{accountId}_{docType}_{DateTime.UtcNow.Ticks}",
                    0 // No expiration
                );

                // Check if document type already exists
                var existingDoc = await _context.UserDocs
                    .FirstOrDefaultAsync(d => d.UserId == accountId && d.DocType == docType);

                if (existingDoc != null)
                {
                    // Update existing document
                    existingDoc.ImgUrl = uploadResult.DisplayUrl;
                    existingDoc.DeleteUrl = uploadResult.DeleteUrl;
                    existingDoc.UploadedAt = DateTime.UtcNow;
                    _logger.LogInformation($"Updated existing KYC document {docType} for user {accountId}");
                }
                else
                {
                    // Create new document
                    var userDoc = new UserDoc
                    {
                        UserId = accountId,
                        DocType = docType,
                        ImgUrl = uploadResult.DisplayUrl,
                        DeleteUrl = uploadResult.DeleteUrl,
                        UploadedAt = DateTime.UtcNow
                    };
                    _context.UserDocs.Add(userDoc);
                    _logger.LogInformation($"Added new KYC document {docType} for user {accountId}");
                }

                await _context.SaveChangesAsync();

                // Get account and auto-update status to Pending if any document uploaded
                var account = await _context.Accounts.FindAsync(accountId);
                if (account != null && account.Status == VerificationStatus.NotVerified)
                {
                    var docCount = await _context.UserDocs.CountAsync(d => d.UserId == accountId);
                    if (docCount > 0)
                    {
                        account.Status = VerificationStatus.Pending;
                        await _context.SaveChangesAsync();
                        _logger.LogInformation($"Updated account {accountId} status to Pending");
                    }
                }

                return Ok(new
                {
                    message = "Document uploaded successfully",
                    url = uploadResult.DisplayUrl,
                    docType = docType,
                    accountStatus = account?.Status.ToString()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading KYC document for user {UserId}", accountIdClaim);
                return StatusCode(500, new { message = "Failed to upload document", error = ex.Message });
            }
        }

        /// <summary>
        /// Get all KYC documents for the authenticated user
        /// </summary>
        [HttpGet("user/my-documents")]
        public async Task<IActionResult> GetMyDocuments()
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                var documents = await _context.UserDocs
                    .Where(d => d.UserId == accountId)
                    .OrderByDescending(d => d.UploadedAt)
                    .Select(d => new
                    {
                        docId = d.DocId,
                        userId = d.UserId,
                        docType = d.DocType,
                        imgUrl = d.ImgUrl,
                        uploadedAt = d.UploadedAt
                    })
                    .ToListAsync();

                return Ok(documents);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user documents");
                return StatusCode(500, new { message = "Error retrieving documents" });
            }
        }

        /// <summary>
        /// Get KYC documents for a specific user (Admin only)
        /// </summary>
        [HttpGet("user/{userId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetUserDocuments(Guid userId)
        {
            try
            {
                var documents = await _context.UserDocs
                    .Where(d => d.UserId == userId)
                    .OrderByDescending(d => d.UploadedAt)
                    .Select(d => new
                    {
                        docId = d.DocId,
                        userId = d.UserId,
                        docType = d.DocType,
                        imgUrl = d.ImgUrl,
                        uploadedAt = d.UploadedAt
                    })
                    .ToListAsync();

                return Ok(documents);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user documents");
                return StatusCode(500, new { message = "Error retrieving documents" });
            }
        }

        /// <summary>
        /// Delete a user document
        /// </summary>
        [HttpDelete("user/{docId}")]
        public async Task<IActionResult> DeleteUserDocument(Guid docId)
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                var document = await _context.UserDocs.FindAsync(docId);
                if (document == null)
                    return NotFound(new { message = "Document not found" });

                // Check ownership (or admin)
                var isAdmin = User.IsInRole("Admin");
                if (document.UserId != accountId && !isAdmin)
                    return StatusCode(403, new { message = "You don't have permission to delete this document" });

                // Note: We don't delete from ImgBB since deleteUrl requires visiting it in a browser
                // The DeleteUrl is stored in case manual cleanup is needed

                _context.UserDocs.Remove(document);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Document deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user document");
                return StatusCode(500, new { message = "Error deleting document" });
            }
        }

        // ==================== PROPERTY DOCUMENTS ====================

        /// <summary>
        /// Upload a property document
        /// </summary>
        [HttpPost("property/{propertyId}/upload")]
        public async Task<IActionResult> UploadPropertyDocument(Guid propertyId, IFormFile file, [FromForm] string docType)
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                // Check property ownership
                var property = await _context.Properties.FindAsync(propertyId);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                if (property.OwnerId != accountId && !User.IsInRole("Admin"))
                    return StatusCode(403, new { message = "You can only upload documents for your own properties" });

                // Validate file
                var validationResult = await _fileValidationService.ValidateFileAsync(file);
                if (!validationResult.IsValid)
                    return BadRequest(new { message = validationResult.ErrorMessage });

                // Convert file to byte array
                byte[] fileBytes;
                using (var memoryStream = new MemoryStream())
                {
                    await file.CopyToAsync(memoryStream);
                    fileBytes = memoryStream.ToArray();
                }

                // Upload to ImgBB
                var uploadResult = await _imgBBService.UploadImageAsync(
                    fileBytes,
                    $"property_{propertyId}_{docType}_{DateTime.UtcNow.Ticks}",
                    0
                );

                // Check if document type already exists
                var existingDoc = await _context.PropertyDocs
                    .FirstOrDefaultAsync(d => d.PropertyId == propertyId && d.DocType == docType);

                if (existingDoc != null)
                {
                    // Update existing document
                    existingDoc.ImgUrl = uploadResult.DisplayUrl;
                    existingDoc.DeleteUrl = uploadResult.DeleteUrl;
                    existingDoc.UploadedAt = DateTime.UtcNow;
                    _context.PropertyDocs.Update(existingDoc);
                }
                else
                {
                    // Create new document
                    var propertyDoc = new PropertyDoc
                    {
                        PropertyId = propertyId,
                        DocType = docType,
                        ImgUrl = uploadResult.DisplayUrl,
                        DeleteUrl = uploadResult.DeleteUrl,
                        UploadedAt = DateTime.UtcNow
                    };
                    _context.PropertyDocs.Add(propertyDoc);
                }

                // Update property status to Pending when first document is uploaded
                if (property.Status == PropertyStatus.NotApproved)
                {
                    property.Status = PropertyStatus.Pending;
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Property document uploaded successfully",
                    docId = existingDoc?.DocId ?? (await _context.PropertyDocs.FirstOrDefaultAsync(d => d.PropertyId == propertyId && d.DocType == docType))?.DocId,
                    url = uploadResult.DisplayUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading property document");
                return StatusCode(500, new { message = "Error uploading document", error = ex.Message });
            }
        }

        /// <summary>
        /// Get all documents for a property
        /// </summary>
        [HttpGet("property/{propertyId}")]
        public async Task<IActionResult> GetPropertyDocuments(Guid propertyId)
        {
            try
            {
                var documents = await _context.PropertyDocs
                    .Where(d => d.PropertyId == propertyId)
                    .OrderByDescending(d => d.UploadedAt)
                    .Select(d => new
                    {
                        d.DocId,
                        d.DocType,
                        d.ImgUrl,
                        d.UploadedAt
                    })
                    .ToListAsync();

                return Ok(documents);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving property documents");
                return StatusCode(500, new { message = "Error retrieving documents" });
            }
        }

        /// <summary>
        /// Delete a property document
        /// </summary>
        [HttpDelete("property/document/{docId}")]
        public async Task<IActionResult> DeletePropertyDocument(Guid docId)
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                var document = await _context.PropertyDocs
                    .Include(d => d.Property)
                    .FirstOrDefaultAsync(d => d.DocId == docId);

                if (document == null)
                    return NotFound(new { message = "Document not found" });

                // Check ownership (or admin)
                var isAdmin = User.IsInRole("Admin");
                if (document.Property.OwnerId != accountId && !isAdmin)
                    return StatusCode(403, new { message = "You don't have permission to delete this document" });

                _context.PropertyDocs.Remove(document);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Document deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting property document");
                return StatusCode(500, new { message = "Error deleting document" });
            }
        }

        // ==================== PROPERTY IMAGES ====================

        /// <summary>
        /// Upload a property image
        /// </summary>
        [HttpPost("property/{propertyId}/upload-image")]
        public async Task<IActionResult> UploadPropertyImage(
            Guid propertyId,
            IFormFile file,
            [FromForm] string imageType,
            [FromForm] bool isMainImage = false,
            [FromForm] int displayOrder = 0)
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                // Check property ownership
                var property = await _context.Properties.FindAsync(propertyId);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                if (property.OwnerId != accountId && !User.IsInRole("Admin"))
                    return StatusCode(403, new { message = "You can only upload images for your own properties" });

                // Validate file as image
                var validationResult = await _fileValidationService.ValidateFileAsync(file);
                if (!validationResult.IsValid)
                    return BadRequest(new { message = validationResult.ErrorMessage });

                // Convert file to byte array
                byte[] fileBytes;
                using (var memoryStream = new MemoryStream())
                {
                    await file.CopyToAsync(memoryStream);
                    fileBytes = memoryStream.ToArray();
                }

                // Upload to ImgBB
                var uploadResult = await _imgBBService.UploadImageAsync(
                    fileBytes,
                    $"property_{propertyId}_{imageType}_{DateTime.UtcNow.Ticks}",
                    0
                );

                // If this is set as main image, unset other main images
                if (isMainImage)
                {
                    var existingMainImages = await _context.PropertyImages
                        .Where(i => i.PropertyId == propertyId && i.IsMainImage)
                        .ToListAsync();

                    foreach (var img in existingMainImages)
                    {
                        img.IsMainImage = false;
                    }
                }

                // Create new image record
                var propertyImage = new PropertyImage
                {
                    PropertyId = propertyId,
                    ImageUrl = uploadResult.DisplayUrl,
                    ImageType = imageType,
                    IsMainImage = isMainImage,
                    DisplayOrder = displayOrder,
                    DeleteUrl = uploadResult.DeleteUrl,
                    CreatedAt = DateTime.UtcNow
                };

                _context.PropertyImages.Add(propertyImage);

                // Update property's main ImageUrl if this is the main image
                if (isMainImage)
                {
                    property.ImageUrl = uploadResult.DisplayUrl;
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Image uploaded successfully",
                    imageId = propertyImage.PropertyImageId,
                    url = uploadResult.DisplayUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading property image");
                return StatusCode(500, new { message = "Error uploading image", error = ex.Message });
            }
        }

        /// <summary>
        /// Get all images for a property
        /// </summary>
        [HttpGet("property/{propertyId}/images")]
        public async Task<IActionResult> GetPropertyImages(Guid propertyId)
        {
            try
            {
                var images = await _context.PropertyImages
                    .Where(i => i.PropertyId == propertyId)
                    .OrderBy(i => i.DisplayOrder)
                    .ThenByDescending(i => i.IsMainImage)
                    .ThenByDescending(i => i.CreatedAt)
                    .Select(i => new
                    {
                        i.PropertyImageId,
                        i.ImageUrl,
                        i.ImageType,
                        i.IsMainImage,
                        i.DisplayOrder,
                        i.CreatedAt
                    })
                    .ToListAsync();

                return Ok(images);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving property images");
                return StatusCode(500, new { message = "Error retrieving images" });
            }
        }

        /// <summary>
        /// Delete a property image
        /// </summary>
        [HttpDelete("property/image/{imageId}")]
        public async Task<IActionResult> DeletePropertyImage(Guid imageId)
        {
            try
            {
                var accountIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(accountIdClaim) || !Guid.TryParse(accountIdClaim, out var accountId))
                    return Unauthorized("Invalid or missing token");

                var image = await _context.PropertyImages
                    .Include(i => i.Property)
                    .FirstOrDefaultAsync(i => i.PropertyImageId == imageId);

                if (image == null)
                    return NotFound(new { message = "Image not found" });

                // Check ownership (or admin)
                var isAdmin = User.IsInRole("Admin");
                if (image.Property!.OwnerId != accountId && !isAdmin)
                    return StatusCode(403, new { message = "You don't have permission to delete this image" });

                _context.PropertyImages.Remove(image);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Image deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting property image");
                return StatusCode(500, new { message = "Error deleting image" });
            }
        }

        // ==================== BULK/UTILITY ENDPOINTS ====================

        /// <summary>
        /// Get document type statistics (Admin only)
        /// </summary>
        [HttpGet("statistics")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetDocumentStatistics()
        {
            try
            {
                var userDocStats = await _context.UserDocs
                    .GroupBy(d => d.DocType)
                    .Select(g => new { DocType = g.Key, Count = g.Count() })
                    .ToListAsync();

                var propertyDocStats = await _context.PropertyDocs
                    .GroupBy(d => d.DocType)
                    .Select(g => new { DocType = g.Key, Count = g.Count() })
                    .ToListAsync();

                var propertyImageStats = await _context.PropertyImages
                    .GroupBy(i => i.ImageType)
                    .Select(g => new { ImageType = g.Key, Count = g.Count() })
                    .ToListAsync();

                return Ok(new
                {
                    userDocuments = userDocStats,
                    propertyDocuments = propertyDocStats,
                    propertyImages = propertyImageStats,
                    totalUserDocs = await _context.UserDocs.CountAsync(),
                    totalPropertyDocs = await _context.PropertyDocs.CountAsync(),
                    totalPropertyImages = await _context.PropertyImages.CountAsync()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving document statistics");
                return StatusCode(500, new { message = "Error retrieving statistics" });
            }
        }
    }
}

