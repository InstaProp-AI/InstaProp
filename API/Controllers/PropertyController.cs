using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;
using InstapropAPI.Attributes;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PropertyController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ImgBBService _imgBBService;
        private readonly FileValidationService _fileValidationService;
        private readonly RewardService _rewardService;
        private readonly OpenAIService _openAIService;
        private readonly InstallmentSummaryService _installmentSummaryService;

        public PropertyController(
            AppDbContext context,
            ImgBBService imgBBService,
            FileValidationService fileValidationService,
            RewardService rewardService,
            OpenAIService openAIService,
            InstallmentSummaryService installmentSummaryService)
        {
            _context = context;
            _imgBBService = imgBBService;
            _fileValidationService = fileValidationService;
            _rewardService = rewardService;
            _openAIService = openAIService;
            _installmentSummaryService = installmentSummaryService;
        }

        // GET: api/Property (Public - only properties with auctions)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Property>>> GetProperties()
        {
            return await _context.Properties
                .Where(p => p.Auctions.Any()) // Only properties that have auctions
                .Include(p => p.Owner)
                .Include(p => p.InstallmentSummary)
                .Include(p => p.Auctions.Where(a => a.Status == "Active")) // Only active auctions
                .Include(p => p.PropertyImages)
                .ToListAsync();
        }

        // GET: api/Property/all (Admin only - all properties)
        [HttpGet("all")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<Property>>> GetAllProperties()
        {
            return await _context.Properties
                .Include(p => p.Owner)
                .Include(p => p.PropertyDocs)
                .Include(p => p.Auctions)
                .Include(p => p.PropertyImages)
                .Include(p => p.InstallmentSummary)
                .ToListAsync();
        }

        // GET: api/Property/my-properties (User's own properties)
        [HttpGet("my-properties")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<Property>>> GetMyProperties()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
            {
                return BadRequest("Invalid user ID");
            }

            return await _context.Properties
                .Where(p => p.OwnerId == userId)
                .Include(p => p.PropertyDocs)
                .Include(p => p.Auctions)
                .Include(p => p.PropertyImages)
                .Include(p => p.InstallmentSummary)
                .ToListAsync();
        }

        // GET: api/Property/5
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetProperty(Guid id)
        {
            var property = await _context.Properties
                .Include(p => p.Owner)
                .Include(p => p.Auctions)
                .Include(p => p.Project)
                .Include(p => p.PropertyDocs)
                .Include(p => p.PropertyImages)
                .Include(p => p.InstallmentSummary)
                .FirstOrDefaultAsync(p => p.PropertyId == id);

            if (property == null)
            {
                return NotFound();
            }

            // Return a DTO to avoid JsonIgnore issues and circular references
            return Ok(new
            {
                property.PropertyId,
                property.OwnerId,
                property.ProjectId,
                property.Name,
                property.Description,
                property.Location,
                Type = PropertyTypeHelper.ToDisplayName(property.Type),
                Status = property.Status.ToString(),
                property.Bedrooms,
                property.Bathrooms,
                property.SquareFeet,
                property.YearBuilt,
                property.ImageUrl,
                property.FinishingType,
                property.Phase,
                property.FloorNumber,
                property.UnitNumber,
                property.ViewType,
                property.Orientation,
                property.DeliveryDate,
                property.ParkingSlots,
                property.HasStorageRoom,
                property.BuyingPrice,
                property.BuyingDate,
                property.Quantity,
                property.HasPool,
                property.HasGym,
                property.HasSecurity,
                property.HasParking,
                property.HasPlayground,
                property.HasGarden,
                property.HasClubhouse,
                property.HasInfrastructure,
                property.HasUndergroundParking,
                property.HasMedicalCenter,
                property.HasCommercialStrip,
                property.HasBusinessHub,
                property.HasOutdoorPools,
                property.HasBicycleLanes,
                property.HasJoggingTrail,
                property.HasNannyRoom,
                property.HasDriverRoom,
                property.HasMaidRoom,
                property.HasPrivatePool,
                property.HasRoofAccess,
                property.HasBalcony,
                property.SmartHome,
                property.CentralAC,
                property.NaturalGas,
                property.HasGenerator,
                property.SeaView,
                property.NileView,
                property.PyramidView,
                property.GardenView,
                property.StreetView,
                ProjectName = property.Project?.Name ?? property.ProjectName ?? "N/A",
                property.CreatedAt,
                property.UpdatedAt,
                Owner = property.Owner != null ? new
                {
                    property.Owner.AccountId,
                    property.Owner.FirstName,
                    property.Owner.LastName,
                    property.Owner.Email,
                    property.Owner.PhoneNumber,
                    RoleId = property.Owner.RoleId,
                    RoleName = property.Owner.Role != null ? property.Owner.Role.RoleName : "Unknown",
                    Status = property.Owner.Status.ToString(),
                    property.Owner.EmailVerified,
                    property.Owner.PhoneVerified
                } : null,
                Auctions = property.Auctions.Select(a => new
                {
                    a.AuctionId,
                    a.PropertyId,
                    a.StartPrice,
                    a.CurrentPrice,
                    a.StartAt,
                    a.Duration,
                    a.Status,
                    a.BidCount,
                    a.CreatedAt
                }).ToList(),
                Project = property.Project != null ? new
                {
                    property.Project.ProjectId,
                    property.Project.Name,
                    property.Project.Description,
                    property.Project.Location
                } : null,
                PropertyDocs = property.PropertyDocs.Select(d => new
                {
                    d.DocId,
                    d.PropertyId,
                    d.DocType,
                    d.ImgUrl,
                    d.UploadedAt
                }).ToList(),
                PropertyImages = property.PropertyImages.OrderBy(img => img.DisplayOrder).Select(img => new
                {
                    img.PropertyImageId,
                    img.PropertyId,
                    img.ImageUrl,
                    img.ImageType,
                    img.IsMainImage,
                    img.DisplayOrder,
                    img.DeleteUrl,
                    img.CreatedAt
                }).ToList(),
                InstallmentSummary = property.InstallmentSummary != null ? new
                {
                    property.InstallmentSummary.SummaryId,
                    property.InstallmentSummary.PropertyId,
                    property.InstallmentSummary.ContractedPrice,
                    property.InstallmentSummary.TotalPaid,
                    property.InstallmentSummary.DownPaymentPercent,
                    DownPaymentAmount = InstallmentSummaryService.CalculateDownPaymentAmount(
                        property.InstallmentSummary.ContractedPrice,
                        property.InstallmentSummary.DownPaymentPercent),
                    property.InstallmentSummary.TermYears,
                    property.InstallmentSummary.InstallmentEndDate,
                    property.InstallmentSummary.IsFullyPaid,
                    property.InstallmentSummary.RemainingBalance,
                    property.InstallmentSummary.CreatedAt,
                    property.InstallmentSummary.UpdatedAt
                } : null
            });
        }

        // GET: api/Property/{id}/financials
        [HttpGet("{id}/financials")]
        [Authorize]
        public async Task<ActionResult<object>> GetPropertyFinancials(Guid id, [FromQuery] decimal? marketValue)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var property = await _context.Properties.FirstOrDefaultAsync(p => p.PropertyId == id);
            if (property == null)
                return NotFound();

            if (property.OwnerId != accountId)
                return StatusCode(403, new { message = "You can only view financials for your own properties" });

            var events = await _context.Events
                .Where(e => e.PropertyId == id && e.UserId == accountId && e.Type == EventType.Installment)
                .ToListAsync();

            var sumInstallments = events.Where(e => e.Amount.HasValue).Sum(e => e.Amount!.Value);
            
            // Installments are considered paid when manually marked as completed
            var paidSoFar = events.Where(e => e.Amount.HasValue && e.IsCompleted).Sum(e => e.Amount!.Value);
            
            // Remaining installments are those not yet completed
            var remainingInstallments = events.Where(e => e.Amount.HasValue && !e.IsCompleted)
                .Sum(e => e.Amount!.Value);

            // Buying price: use any schedule group's buying price if present; otherwise null
            var scheduleBuyingPrice = events
                .Where(e => e.ScheduleBuyingPrice.HasValue)
                .Select(e => e.ScheduleBuyingPrice!.Value)
                .Cast<decimal?>()
                .FirstOrDefault();

            var effectiveBuyingPrice = scheduleBuyingPrice ?? (decimal?)null;
            var remainingToPay = (effectiveBuyingPrice ?? sumInstallments) - paidSoFar;
            if (remainingToPay < 0) remainingToPay = 0;

            // Determine market value: use provided value, or get from AI valuation, or use contracted price as fallback
            decimal? finalMarketValue = marketValue;
            
            if (!finalMarketValue.HasValue)
            {
                // Try to get AI valuation
                var valuationService = new ValuationService(_context, _openAIService);
                var aiValuation = await valuationService.GetOrCalculatePropertyValuation(id);
                
                if (aiValuation.HasValue)
                {
                    finalMarketValue = aiValuation.Value;
                }
                else
                {
                    // Fallback to contracted price if AI valuation fails
                    finalMarketValue = effectiveBuyingPrice;
                }
            }

            decimal? roiPercent = null;
            if (finalMarketValue.HasValue && effectiveBuyingPrice.HasValue && effectiveBuyingPrice.Value > 0)
            {
                roiPercent = (finalMarketValue.Value - effectiveBuyingPrice.Value) / effectiveBuyingPrice.Value * 100m;
            }

            return Ok(new
            {
                propertyId = id,
                propertyName = !string.IsNullOrEmpty(property.Name) ? property.Name : $"Property #{id}",
                sumInstallments,
                paidSoFar,
                remainingInstallments,
                remainingToPay,
                buyingPrice = effectiveBuyingPrice,
                contractedPrice = effectiveBuyingPrice, // Alias for frontend
                marketValue = finalMarketValue,
                roiPercent
            });
        }

        // GET: api/Property/{id}/installment-summary
        [HttpGet("{id}/installment-summary")]
        [Authorize]
        public async Task<ActionResult<object>> GetInstallmentSummary(Guid id)
        {
            var property = await _context.Properties
                .Include(p => p.InstallmentSummary)
                .FirstOrDefaultAsync(p => p.PropertyId == id);

            if (property == null)
            {
                return NotFound(new { message = "Property not found" });
            }

            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();

            if (accountType != "Admin" && property.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only view installment data for your own properties" });
            }

            if (property.InstallmentSummary == null)
            {
                return NotFound(new { message = "Installment summary not available for this property" });
            }

            return Ok(ToInstallmentSummaryResponse(property.InstallmentSummary));
        }

        // PUT: api/Property/{id}/installment-summary
        [HttpPut("{id}/installment-summary")]
        [Authorize]
        public async Task<ActionResult<object>> UpsertInstallmentSummary(Guid id, [FromBody] InstallmentSummaryInputDto summaryDto)
        {
            var property = await _context.Properties
                .FirstOrDefaultAsync(p => p.PropertyId == id);

            if (property == null)
            {
                return NotFound(new { message = "Property not found" });
            }

            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();

            if (accountId == null)
            {
                return Unauthorized();
            }

            if (accountType != "Admin" && property.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only update installment data for your own properties" });
            }

            if (summaryDto == null || !summaryDto.ContractedPrice.HasValue)
            {
                return BadRequest(new { message = "Contracted price is required to update installment summary" });
            }

            var summary = await _installmentSummaryService.UpsertSummaryAsync(
                property.PropertyId,
                Math.Max(0, summaryDto.ContractedPrice.Value),
                Math.Max(0, summaryDto.TotalPaid ?? 0),
                ClampPercent(summaryDto.DownPaymentPercent),
                summaryDto.TermYears,
                summaryDto.InstallmentEndDate,
                summaryDto.IsFullyPaid);

            return Ok(ToInstallmentSummaryResponse(summary));
        }

        // POST: api/Property 
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Property>> PostProperty(PropertyDto propertyDto)
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
            {
                return BadRequest("Invalid user ID");
            }

            var account = await _context.Accounts.FindAsync(userId);
            if (account == null)
            {
                return BadRequest("Account not found");
            }

            var property = MapDtoToProperty(propertyDto, userId);
            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            await HandleInstallmentSummaryAsync(property.PropertyId, propertyDto.InstallmentSummary);
            await _rewardService.AwardPointsAsync(userId, "PropertyCreate", RewardPoints.AddProperty, $"Created property '{property.Name}'", property.PropertyId);

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // POST: api/Property/skip-documents
        [HttpPost("skip-documents")]
        [Authorize]
        public async Task<ActionResult<Property>> PostPropertySkipDocuments(PropertyDto propertyDto)
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
            {
                return BadRequest("Invalid user ID");
            }

            var account = await _context.Accounts.FindAsync(userId);
            if (account == null)
            {
                return BadRequest("Account not found");
            }

            var property = MapDtoToProperty(propertyDto, userId);
            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            await HandleInstallmentSummaryAsync(property.PropertyId, propertyDto.InstallmentSummary);

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // PUT: api/Property/5
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> PutProperty(Guid id, [FromBody] PropertyUpdateDto updateDto)
        {
            // Check if property is editable (only before approval)
            var existingProperty = await _context.Properties.FindAsync(id);
            if (existingProperty == null)
                return NotFound();

            if (existingProperty.Status == PropertyStatus.Approved)
            {
                return BadRequest(new { message = "Property cannot be edited after approval" });
            }

            // Check if user owns the property (unless admin)
            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();
            
            if (accountId == null)
                return Unauthorized();

            if (accountType != "Admin" && existingProperty.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only edit your own properties" });
            }

            // Update only the allowed fields
            existingProperty.Name = updateDto.Name;
            existingProperty.Description = updateDto.Description;
            existingProperty.Location = updateDto.Location;
            existingProperty.UpdatedAt = DateTime.UtcNow;

            try
            {
                await _context.SaveChangesAsync();
                await HandleInstallmentSummaryAsync(existingProperty.PropertyId, updateDto.InstallmentSummary);
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!PropertyExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Ok(existingProperty);
        }

        // DELETE: api/Property/5
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteProperty(Guid id)
        {
            var property = await _context.Properties
                .Include(p => p.Auctions)
                .FirstOrDefaultAsync(p => p.PropertyId == id);
                
            if (property == null)
            {
                return NotFound();
            }

            // Check if user owns the property (unless admin)
            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();
            
            if (accountId == null)
                return Unauthorized();

            if (accountType != "Admin" && property.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only delete your own properties" });
            }

            // Check if property has any active or pending auctions
            var hasActiveAuction = property.Auctions.Any(a => 
                a.Status == "Active" || 
                a.Status == "Requested" || 
                a.Status == "Approved");
            
            if (hasActiveAuction)
            {
                return BadRequest(new { message = "Cannot delete property. It is currently in auction or has a pending auction request." });
            }

            _context.Properties.Remove(property);
            await _context.SaveChangesAsync();

            return NoContent();
        }


        // PUT: api/Property/5/approve
        [HttpPut("{id}/approve")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> ApproveProperty(Guid id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
            {
                return NotFound();
            }

            // Check if property has documents before approval
            var hasDocuments = await _context.PropertyDocs
                .AnyAsync(d => d.PropertyId == id);
            
            if (!hasDocuments)
            {
                return BadRequest(new { message = "Property must have documents before approval" });
            }

            // Approve property
            property.Status = PropertyStatus.Approved;
            property.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Property approved successfully" });
        }

        // POST: api/Property/{id}/documents
        [HttpPost("{id}/documents")]
        [Authorize]
        public async Task<ActionResult> UploadPropertyDocument(Guid id, IFormFile file, [FromForm] string docType)
        {
            try
            {
                var property = await _context.Properties.FindAsync(id);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                // Check if user owns the property
                var accountId = GetCurrentAccountId();
                if (accountId == null)
                    return Unauthorized();

                if (property.OwnerId != accountId)
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
                    $"property_{id}_{docType}_{DateTime.UtcNow.Ticks}",
                    0
                );

                // Change status to Pending when first document is uploaded
                if (property.Status == PropertyStatus.NotApproved)
                {
                    property.Status = PropertyStatus.Pending;
                    property.UpdatedAt = DateTime.UtcNow;
                }

                // Check if document type already exists for this property
                var existingDoc = await _context.PropertyDocs
                    .FirstOrDefaultAsync(d => d.PropertyId == id && d.DocType == docType);

                if (existingDoc != null)
                {
                    // Update existing document
                    existingDoc.ImgUrl = uploadResult.DisplayUrl;
                    existingDoc.DeleteUrl = uploadResult.DeleteUrl;
                    existingDoc.UploadedAt = DateTime.UtcNow;
                }
                else
                {
                    // Create new document
                    var propertyDoc = new PropertyDoc
                    {
                        PropertyId = id,
                        DocType = docType,
                        ImgUrl = uploadResult.DisplayUrl,
                        DeleteUrl = uploadResult.DeleteUrl,
                        UploadedAt = DateTime.UtcNow
                    };
                    _context.PropertyDocs.Add(propertyDoc);
                }

                await _context.SaveChangesAsync();
                return Ok(new { 
                    message = "Property document uploaded successfully",
                    url = uploadResult.DisplayUrl,
                    docId = existingDoc?.DocId ?? (await _context.PropertyDocs.FirstOrDefaultAsync(d => d.PropertyId == id && d.DocType == docType))?.DocId
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading document", error = ex.Message });
            }
        }

        // GET: api/Property/{id}/documents
        [HttpGet("{id}/documents")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<PropertyDoc>>> GetPropertyDocuments(Guid id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
                return NotFound();

            var documents = await _context.PropertyDocs
                .Where(d => d.PropertyId == id)
                .ToListAsync();

            return Ok(documents);
        }

        // POST: api/Property/{id}/images
        [HttpPost("{id}/images")]
        [Authorize]
        public async Task<ActionResult> UploadPropertyImages(Guid id, List<IFormFile> images, [FromForm] string? imageType = "Gallery")
        {
            try
            {
                // Property primary key is Guid
                var property = await _context.Properties.FindAsync(id);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                // Check if user owns the property
                var accountId = GetCurrentAccountId();
                if (accountId == null)
                    return Unauthorized();

                if (property.OwnerId != accountId)
                    return StatusCode(403, new { message = "You can only upload images for your own properties" });

                if (images == null || images.Count == 0)
                    return BadRequest(new { message = "No images provided" });

                var uploadedImages = new List<object>();
                var currentOrder = await _context.PropertyImages
                    .Where(img => img.PropertyId == id)
                    .MaxAsync(img => (int?)img.DisplayOrder) ?? -1;

                foreach (var image in images)
                {
                    // Validate file
                    var validationResult = await _fileValidationService.ValidateFileAsync(image);
                    if (!validationResult.IsValid)
                        return BadRequest(new { message = validationResult.ErrorMessage });

                    // Convert file to byte array
                    byte[] fileBytes;
                    using (var memoryStream = new MemoryStream())
                    {
                        await image.CopyToAsync(memoryStream);
                        fileBytes = memoryStream.ToArray();
                    }

                    // Upload to ImgBB
                    var uploadResult = await _imgBBService.UploadImageAsync(
                        fileBytes,
                        $"property_{id}_image_{DateTime.UtcNow.Ticks}",
                        0
                    );

                    currentOrder++;

                    // Determine if this is the main image (first image or if no images exist)
                    var isMainImage = !await _context.PropertyImages.AnyAsync(img => img.PropertyId == id);

                    // Create new property image
                    var propertyImage = new PropertyImage
                    {
                        PropertyId = id,
                        ImageUrl = uploadResult.DisplayUrl,
                        ImageType = imageType ?? "Gallery",
                        IsMainImage = isMainImage,
                        DisplayOrder = currentOrder,
                        DeleteUrl = uploadResult.DeleteUrl,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.PropertyImages.Add(propertyImage);
                    await _context.SaveChangesAsync();

                    // Update property's ImageUrl if this is the main image
                    if (isMainImage)
                    {
                        property.ImageUrl = uploadResult.DisplayUrl;
                        property.UpdatedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                    }

                    uploadedImages.Add(new
                    {
                        propertyImageId = propertyImage.PropertyImageId,
                        imageUrl = propertyImage.ImageUrl,
                        isMainImage = propertyImage.IsMainImage,
                        displayOrder = propertyImage.DisplayOrder
                    });
                }

                return Ok(new
                {
                    message = $"{uploadedImages.Count} image(s) uploaded successfully",
                    images = uploadedImages
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading images", error = ex.Message });
            }
        }

        // GET: api/Property/{id}/images
        [HttpGet("{id}/images")]
        public async Task<ActionResult<IEnumerable<PropertyImage>>> GetPropertyImages(Guid id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
                return NotFound();

            var images = await _context.PropertyImages
                .Where(img => img.PropertyId == id)
                .OrderBy(img => img.DisplayOrder)
                .ToListAsync();

            return Ok(images);
        }

        // DELETE: api/Property/{propertyId}/images/{imageId}
        [HttpDelete("{propertyId}/images/{imageId}")]
        [Authorize]
        public async Task<ActionResult> DeletePropertyImage(Guid propertyId, Guid imageId)
        {
            try
            {
                var property = await _context.Properties.FindAsync(propertyId);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                // Check if user owns the property
                var accountId = GetCurrentAccountId();
                if (accountId == null)
                    return Unauthorized();

                if (property.OwnerId != accountId)
                    return StatusCode(403, new { message = "You can only delete images from your own properties" });

                var image = await _context.PropertyImages.FindAsync(imageId);
                if (image == null)
                    return NotFound(new { message = "Image not found" });

                if (image.PropertyId != propertyId)
                    return BadRequest(new { message = "Image does not belong to this property" });

                var wasMainImage = image.IsMainImage;

                // Delete from database
                _context.PropertyImages.Remove(image);
                await _context.SaveChangesAsync();

                // If this was the main image, set another image as main
                if (wasMainImage)
                {
                    var newMainImage = await _context.PropertyImages
                        .Where(img => img.PropertyId == propertyId)
                        .OrderBy(img => img.DisplayOrder)
                        .FirstOrDefaultAsync();

                    if (newMainImage != null)
                    {
                        newMainImage.IsMainImage = true;
                        property.ImageUrl = newMainImage.ImageUrl;
                        property.UpdatedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                    }
                    else
                    {
                        // No more images, clear property ImageUrl
                        property.ImageUrl = string.Empty;
                        property.UpdatedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                    }
                }

                return Ok(new { message = "Image deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting image", error = ex.Message });
            }
        }

        // PUT: api/Property/{propertyId}/images/{imageId}/set-main
        [HttpPut("{propertyId}/images/{imageId}/set-main")]
        [Authorize]
        public async Task<ActionResult> SetMainImage(Guid propertyId, Guid imageId)
        {
            try
            {
                var property = await _context.Properties.FindAsync(propertyId);
                if (property == null)
                    return NotFound(new { message = "Property not found" });

                // Check if user owns the property
                var accountId = GetCurrentAccountId();
                if (accountId == null)
                    return Unauthorized();

                if (property.OwnerId != accountId)
                    return StatusCode(403, new { message = "You can only modify your own properties" });

                var image = await _context.PropertyImages.FindAsync(imageId);
                if (image == null)
                    return NotFound(new { message = "Image not found" });

                if (image.PropertyId != propertyId)
                    return BadRequest(new { message = "Image does not belong to this property" });

                // Unset all other images as main
                var allImages = await _context.PropertyImages
                    .Where(img => img.PropertyId == propertyId)
                    .ToListAsync();

                foreach (var img in allImages)
                {
                    img.IsMainImage = img.PropertyImageId == imageId;
                }

                // Update property's ImageUrl
                property.ImageUrl = image.ImageUrl;
                property.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Main image updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error setting main image", error = ex.Message });
            }
        }

        // PUT: api/Property/{id}/verify (DEPRECATED - use /approve instead)
        // This endpoint is kept for backward compatibility but redirects to approve
        [HttpPut("{id}/verify")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> VerifyProperty(Guid id)
        {
            // Redirect to ApproveProperty method
            return await ApproveProperty(id);
        }

        private Property MapDtoToProperty(PropertyDto dto, Guid ownerId)
        {
            var propertyType = PropertyTypeHelper.FromDisplayName(dto.Type);
            var projectName = dto.ProjectName ?? "Property";
            var propertyTypeName = PropertyTypeHelper.ToDisplayName(propertyType);
            var unitInfo = !string.IsNullOrWhiteSpace(dto.UnitNumber)
                ? $" - Unit {dto.UnitNumber}"
                : "";

            return new Property
            {
                OwnerId = ownerId,
                ProjectId = dto.ProjectId,
                ProjectName = dto.ProjectName,
                Description = dto.Description ?? string.Empty,
                Location = dto.Location ?? string.Empty,
                Type = propertyType,
                Bedrooms = dto.Bedrooms,
                Bathrooms = dto.Bathrooms,
                SquareFeet = dto.SquareFeet,
                YearBuilt = dto.YearBuilt,
                FinishingType = dto.FinishingType ?? "Finished",
                HasPool = dto.HasPool,
                HasGym = dto.HasGym,
                HasSecurity = dto.HasSecurity,
                HasParking = dto.HasParking,
                HasPlayground = dto.HasPlayground,
                Phase = dto.Phase,
                FloorNumber = dto.FloorNumber,
                UnitNumber = dto.UnitNumber,
                ViewType = dto.ViewType,
                Orientation = dto.Orientation,
                DeliveryDate = dto.DeliveryDate,
                ParkingSlots = dto.ParkingSlots,
                HasStorageRoom = dto.HasStorageRoom,
                BuyingPrice = dto.BuyingPrice,
                BuyingDate = dto.BuyingDate,
                Quantity = dto.Quantity,
                HasGarden = dto.HasGarden,
                HasClubhouse = dto.HasClubhouse,
                HasInfrastructure = dto.HasInfrastructure,
                HasUndergroundParking = dto.HasUndergroundParking,
                HasMedicalCenter = dto.HasMedicalCenter,
                HasCommercialStrip = dto.HasCommercialStrip,
                HasBusinessHub = dto.HasBusinessHub,
                HasOutdoorPools = dto.HasOutdoorPools,
                HasBicycleLanes = dto.HasBicycleLanes,
                HasJoggingTrail = dto.HasJoggingTrail,
                HasNannyRoom = dto.HasNannyRoom,
                HasDriverRoom = dto.HasDriverRoom,
                HasMaidRoom = dto.HasMaidRoom,
                HasPrivatePool = dto.HasPrivatePool,
                HasRoofAccess = dto.HasRoofAccess,
                HasBalcony = dto.HasBalcony,
                SmartHome = dto.SmartHome,
                CentralAC = dto.CentralAC,
                NaturalGas = dto.NaturalGas,
                HasGenerator = dto.HasGenerator,
                SeaView = dto.SeaView,
                NileView = dto.NileView,
                PyramidView = dto.PyramidView,
                GardenView = dto.GardenView,
                StreetView = dto.StreetView,
                ImageUrl = dto.ImageUrl ?? string.Empty,
                Status = PropertyStatus.NotApproved,
                Name = $"{projectName} - {propertyTypeName}{unitInfo}",
                CreatedAt = DateTime.UtcNow
            };
        }

        private async Task HandleInstallmentSummaryAsync(Guid propertyId, InstallmentSummaryInputDto? summaryDto)
        {
            if (summaryDto == null || !summaryDto.ContractedPrice.HasValue)
            {
                return;
            }

            var contractedPrice = Math.Max(0, summaryDto.ContractedPrice.Value);
            var totalPaid = Math.Max(0, summaryDto.TotalPaid ?? 0);
            var downPaymentPercent = ClampPercent(summaryDto.DownPaymentPercent);

            await _installmentSummaryService.UpsertSummaryAsync(
                propertyId,
                contractedPrice,
                totalPaid,
                downPaymentPercent,
                summaryDto.TermYears,
                summaryDto.InstallmentEndDate,
                summaryDto.IsFullyPaid);
        }

        private decimal ClampPercent(decimal? value)
        {
            if (!value.HasValue)
            {
                return 0;
            }

            var percent = value.Value;
            if (percent < 0) percent = 0;
            if (percent > 100) percent = 100;
            return Math.Round(percent, 2);
        }

        private object ToInstallmentSummaryResponse(InstallmentSummary summary)
        {
            return new
            {
                summary.SummaryId,
                summary.PropertyId,
                summary.ContractedPrice,
                summary.TotalPaid,
                summary.DownPaymentPercent,
                DownPaymentAmount = InstallmentSummaryService.CalculateDownPaymentAmount(summary.ContractedPrice, summary.DownPaymentPercent),
                summary.TermYears,
                summary.InstallmentEndDate,
                summary.IsFullyPaid,
                summary.RemainingBalance,
                summary.CreatedAt,
                summary.UpdatedAt
            };
        }

        private bool PropertyExists(Guid id)
        {
            return _context.Properties.Any(e => e.PropertyId == id);
        }

        private Guid? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null && Guid.TryParse(uidClaim.Value, out var guid) ? guid : null;
        }

        // SECURITY: Check RoleId instead of Type - returns role name or null
        private string? GetCurrentAccountType()
        {
            var roleIdClaim = User.FindFirst("roleId");
            if (roleIdClaim == null || !Guid.TryParse(roleIdClaim.Value, out var roleId))
                return null;
            
            // Map role IDs to role names
            if (roleId == Role.ADMIN_ROLE_ID) return "Admin";
            if (roleId == Role.DEVELOPER_ROLE_ID) return "Developer";
            if (roleId == Role.USER_ROLE_ID) return "User";
            
            return null;
        }

        // POST: api/Property/estimate (Public - simple property valuation)
        [HttpPost("estimate")]
        public ActionResult<object> EstimateProperty([FromBody] PropertyEstimateDto estimateDto)
        {
            // Simple estimation algorithm based on basic factors
            double basePrice = 0;
            
            // Base price by location (simplified)
            var location = estimateDto.Location.ToLower();
            if (location.Contains("manhattan") || location.Contains("beverly hills") || location.Contains("miami beach"))
                basePrice = 800000; // High-end areas
            else if (location.Contains("downtown") || location.Contains("city center"))
                basePrice = 500000; // Urban areas
            else if (location.Contains("suburb") || location.Contains("residential"))
                basePrice = 350000; // Suburban areas
            else
                basePrice = 250000; // Default

            // Adjust by bedrooms
            basePrice += (estimateDto.Bedrooms - 1) * 50000;

            // Adjust by bathrooms
            basePrice += (estimateDto.Bathrooms - 1) * 30000;

            // Adjust by square feet
            basePrice += (estimateDto.SquareFeet - 1000) * 100;

            // Adjust by year built (newer = more expensive)
            var currentYear = DateTime.Now.Year;
            var age = currentYear - estimateDto.YearBuilt;
            if (age < 5) basePrice *= 1.2;
            else if (age < 10) basePrice *= 1.1;
            else if (age > 30) basePrice *= 0.9;

            var estimatedValue = Math.Max(basePrice, 100000); // Minimum $100k

            return Ok(new {
                estimatedValue = Math.Round(estimatedValue, 2),
                confidence = "Low - Basic estimation only",
                message = "For detailed valuation with market analysis, please log in",
                factors = new {
                    location = estimateDto.Location,
                    bedrooms = estimateDto.Bedrooms,
                    bathrooms = estimateDto.Bathrooms,
                    squareFeet = estimateDto.SquareFeet,
                    yearBuilt = estimateDto.YearBuilt
                }
            });
        }
    }

    public class PropertyDocUploadDto
    {
        public string DocType { get; set; } = string.Empty; // Ownership, Legal, FloorPlan, etc.
        public string ImageUrl { get; set; } = string.Empty;
    }

    public class PropertyEstimateDto
    {
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
    }
}
