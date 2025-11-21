using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ParentPropertyController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ParentPropertyController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetParentProperties([FromQuery] ParentPropertyFilters filters)
        {
            var query = _context.ParentProperties
                .Include(p => p.Project)
                .Include(p => p.ChildProperties)
                .AsQueryable();

            // Apply filters
            if (filters.Type.HasValue)
            {
                var typeName = PropertyTypeHelper.ToDisplayName(filters.Type.Value);
                query = query.Where(p => p.Type == typeName);
            }

            if (filters.Bedrooms.HasValue)
            {
                query = query.Where(p => p.Bedrooms >= filters.Bedrooms);
            }

            if (filters.Bathrooms.HasValue)
            {
                query = query.Where(p => p.Bathrooms >= filters.Bathrooms);
            }

            if (filters.MinArea.HasValue)
            {
                query = query.Where(p => p.AreaSqm >= filters.MinArea);
            }

            if (filters.MaxArea.HasValue)
            {
                query = query.Where(p => p.AreaSqm <= filters.MaxArea);
            }

            if (!string.IsNullOrEmpty(filters.Governorate))
            {
                query = query.Where(p => p.Project != null && p.Project.Location.Contains(filters.Governorate));
            }

            if (!string.IsNullOrEmpty(filters.City))
            {
                query = query.Where(p => p.Project != null && p.Project.Location.Contains(filters.City));
            }

            if (filters.HasPool.HasValue)
            {
                query = query.Where(p => p.HasPool == filters.HasPool);
            }

            if (filters.HasGym.HasValue)
            {
                query = query.Where(p => p.HasGym == filters.HasGym);
            }

            if (filters.HasSecurity.HasValue)
            {
                query = query.Where(p => p.HasSecurity == filters.HasSecurity);
            }

            if (filters.HasParking.HasValue)
            {
                query = query.Where(p => p.HasParking == filters.HasParking);
            }

            if (filters.FinishingType.HasValue)
            {
                query = query.Where(p => p.FinishingType == filters.FinishingType.ToString());
            }

            // Apply sorting
            query = filters.SortBy?.ToLower() switch
            {
                "area_asc" => query.OrderBy(p => p.AreaSqm),
                "area_desc" => query.OrderByDescending(p => p.AreaSqm),
                "bedrooms_asc" => query.OrderBy(p => p.Bedrooms),
                "bedrooms_desc" => query.OrderByDescending(p => p.Bedrooms),
                "date_asc" => query.OrderBy(p => p.CreatedAt),
                "date_desc" => query.OrderByDescending(p => p.CreatedAt),
                _ => query.OrderByDescending(p => p.CreatedAt)
            };

            var totalCount = await query.CountAsync();
            var parentProperties = await query
                .Skip((filters.Page - 1) * filters.PageSize)
                .Take(filters.PageSize)
                .Select(p => new
                {
                    p.ParentPropertyId,
                    Type = p.Type,
                    ProjectName = p.Project != null
                        ? p.Project.Name
                        : (string.IsNullOrWhiteSpace(p.ProjectName) ? "N/A" : p.ProjectName),
                    p.Bedrooms,
                    p.Bathrooms,
                    p.AreaSqm,
                    p.FinishingType,
                    p.HasPool,
                    p.HasGym,
                    p.HasSecurity,
                    p.HasParking,
                    p.HasGarden,
                    p.HasPlayground,
                    p.HasClubhouse,
                    p.CreatedAt,
                    Project = p.Project != null ? new
                    {
                        p.Project.ProjectId,
                        p.Project.Name,
                        p.Project.Location,
                        p.Project.DeveloperId
                    } : null,
                    ChildPropertiesCount = p.ChildProperties.Count,
                    AvailableUnits = p.ChildProperties.Count(c => c.OwnerId == null)
                })
                .ToListAsync();

            return Ok(new
            {
                ParentProperties = parentProperties,
                TotalCount = totalCount,
                Page = filters.Page,
                PageSize = filters.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / filters.PageSize)
            });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetParentProperty(int id)
        {
            var parentProperty = await _context.ParentProperties
                .Include(p => p.Project)
                .Include(p => p.ChildProperties)
                    .ThenInclude(c => c.PropertyImages)
                .FirstOrDefaultAsync(p => p.ParentPropertyId == id);

            if (parentProperty == null) return NotFound();

            return Ok(new
            {
                parentProperty.ParentPropertyId,
                ProjectName = string.IsNullOrWhiteSpace(parentProperty.ProjectName) ? "N/A" : parentProperty.ProjectName,
                Type = parentProperty.Type,
                parentProperty.Bedrooms,
                parentProperty.Bathrooms,
                parentProperty.AreaSqm,
                parentProperty.FinishingType,
                parentProperty.HasPool,
                parentProperty.HasGym,
                parentProperty.HasSecurity,
                parentProperty.HasParking,
                parentProperty.HasGarden,
                parentProperty.HasPlayground,
                parentProperty.HasClubhouse,
                parentProperty.CreatedAt,
                Project = parentProperty.Project != null ? new
                {
                    parentProperty.Project.ProjectId,
                    parentProperty.Project.Name,
                    parentProperty.Project.Description,
                    parentProperty.Project.Location,
                    parentProperty.Project.DeveloperId
                } : null,
                ChildProperties = parentProperty.ChildProperties.Select(c => new
                {
                    c.PropertyId,
                    c.Name,
                    c.Description,
                    c.Location,
                    c.ImageUrl,
                    c.SquareFeet,
                    c.YearBuilt,
                    c.IsApproved,
                    c.CreatedAt,
                    c.BuyingPrice,
                    c.BuyingDate,
                    c.FloorNumber,
                    c.UnitNumber,
                    c.ViewType,
                    c.Orientation,
                    c.DeliveryDate,
                    c.ParkingSlots,
                    c.HasStorageRoom,
                    c.HasNannyRoom,
                    c.HasDriverRoom,
                    c.HasMaidRoom,
                    c.HasPrivatePool,
                    c.HasRoofAccess,
                    c.HasBalcony,
                    c.HasGarden,
                    c.HasClubhouse,
                    c.HasInfrastructure,
                    c.HasUndergroundParking,
                    c.HasMedicalCenter,
                    c.HasCommercialStrip,
                    c.HasBusinessHub,
                    c.HasOutdoorPools,
                    c.HasBicycleLanes,
                    c.HasJoggingTrail,
                    c.SmartHome,
                    c.CentralAC,
                    c.NaturalGas,
                    c.HasGenerator,
                    c.SeaView,
                    c.NileView,
                    c.PyramidView,
                    c.GardenView,
                    c.StreetView,
                    ImageCount = c.PropertyImages.Count
                })
            });
        }

        [HttpGet("{id}/children")]
        public async Task<IActionResult> GetParentChildren(int id)
        {
            var children = await _context.ChildProperties
                .Where(c => c.ParentPropertyId == id)
                .Include(c => c.PropertyImages)
                .OrderBy(c => c.CreatedAt)
                .ToListAsync();

            if (!children.Any())
            {
                return Ok(Array.Empty<object>());
            }

            var result = children.Select(c => new
            {
                c.PropertyId,
                c.ParentPropertyId,
                c.OwnerId,
                c.Phase,
                c.FloorNumber,
                c.UnitNumber,
                c.ViewType,
                c.Orientation,
                DeliveryDate = c.DeliveryDate?.ToString("o"),
                c.ParkingSlots,
                c.HasStorageRoom,
                c.BuyingPrice,
                BuyingDate = c.BuyingDate?.ToString("o"),
                c.Quantity,
                c.HasNannyRoom,
                c.HasDriverRoom,
                c.HasMaidRoom,
                c.HasPrivatePool,
                c.HasRoofAccess,
                c.HasBalcony,
                c.HasGarden,
                c.HasClubhouse,
                c.HasInfrastructure,
                c.HasUndergroundParking,
                c.HasMedicalCenter,
                c.HasCommercialStrip,
                c.HasBusinessHub,
                c.HasOutdoorPools,
                c.HasBicycleLanes,
                c.HasJoggingTrail,
                c.SmartHome,
                c.CentralAC,
                c.NaturalGas,
                c.HasGenerator,
                c.SeaView,
                c.NileView,
                c.PyramidView,
                c.GardenView,
                c.StreetView,
                c.Name,
                c.Description,
                c.Location,
                c.ImageUrl,
                c.SquareFeet,
                c.YearBuilt,
                c.IsApproved,
                CreatedAt = c.CreatedAt.ToString("o"),
                UpdatedAt = c.UpdatedAt.ToString("o"),
                c.Bedrooms,
                c.Bathrooms,
                Type = PropertyTypeHelper.ToDisplayName(c.Type),
                Status = (int)c.Status,
                c.ProjectId,
                PropertyImages = c.PropertyImages.Select(img => new
                {
                    img.PropertyImageId,
                    img.PropertyId,
                    img.ImageUrl,
                    img.ImageType,
                    img.IsMainImage,
                    img.DisplayOrder,
                    img.DeleteUrl,
                    CreatedAt = img.CreatedAt.ToString("o")
                })
            });

            return Ok(result);
        }

        [HttpPost("find-or-create")]
        public async Task<IActionResult> FindOrCreateParentProperty([FromBody] FindOrCreateParentPropertyRequest request)
        {
            var typeDisplayName = PropertyTypeHelper.ToDisplayName(request.Type);
            var trimmedProjectName = string.IsNullOrWhiteSpace(request.ProjectName)
                ? null
                : request.ProjectName!.Trim();

            var project = trimmedProjectName != null
                ? await _context.Projects.FirstOrDefaultAsync(p => p.Name == trimmedProjectName)
                : null;

            var existingParent = await _context.ParentProperties
                .Include(p => p.Project)
                .FirstOrDefaultAsync(p =>
                    p.Type == typeDisplayName &&
                    p.Bedrooms == request.Bedrooms &&
                    p.Bathrooms == request.Bathrooms &&
                    // Match properties within 5 sqm range
                    p.AreaSqm >= request.AreaSqm - 5 &&
                    p.AreaSqm <= request.AreaSqm + 5 &&
                    p.FinishingType == request.FinishingType.ToString() &&
                    p.HasPool == request.HasPool &&
                    p.HasGym == request.HasGym &&
                    p.HasSecurity == request.HasSecurity &&
                    p.HasParking == request.HasParking &&
                    p.HasGarden == request.HasGarden &&
                    p.HasPlayground == request.HasPlayground &&
                    p.HasClubhouse == request.HasClubhouse &&
                    (project != null ? p.ProjectId == project.ProjectId : p.ProjectId == null) &&
                    (trimmedProjectName != null ? p.ProjectName == trimmedProjectName : p.ProjectName == null));

            if (existingParent != null)
            {
                return Ok(new
                {
                    ParentPropertyId = existingParent.ParentPropertyId,
                    IsNew = false,
                    Message = "Found existing parent property"
                });
            }

            var newParentProperty = new ParentProperty
            {
                ProjectId = project?.ProjectId,
                ProjectName = project?.Name ?? trimmedProjectName,
                Type = typeDisplayName,
                Bedrooms = request.Bedrooms,
                Bathrooms = request.Bathrooms,
                AreaSqm = (int)request.AreaSqm,
                FinishingType = request.FinishingType.ToString(),
                HasPool = request.HasPool,
                HasGym = request.HasGym,
                HasSecurity = request.HasSecurity,
                HasParking = request.HasParking,
                HasGarden = request.HasGarden,
                HasPlayground = request.HasPlayground,
                HasClubhouse = request.HasClubhouse,
                CreatedAt = DateTime.UtcNow
            };

            _context.ParentProperties.Add(newParentProperty);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                ParentPropertyId = newParentProperty.ParentPropertyId,
                IsNew = true,
                Message = "Created new parent property"
            });
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetParentPropertyStats()
        {
            var totalCount = await _context.ParentProperties.CountAsync();
            var byType = await _context.ParentProperties
                .GroupBy(p => p.Type)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToListAsync();
            var byBedrooms = await _context.ParentProperties
                .GroupBy(p => p.Bedrooms)
                .Select(g => new { Bedrooms = g.Key, Count = g.Count() })
                .OrderBy(x => x.Bedrooms)
                .ToListAsync();
            var byFinishing = await _context.ParentProperties
                .GroupBy(p => p.FinishingType)
                .Select(g => new { FinishingType = g.Key, Count = g.Count() })
                .ToListAsync();

            var averageArea = await _context.ParentProperties
                .AverageAsync(p => p.AreaSqm);

            var amenities = new
            {
                HasPool = await _context.ParentProperties.CountAsync(p => p.HasPool),
                HasGym = await _context.ParentProperties.CountAsync(p => p.HasGym),
                HasSecurity = await _context.ParentProperties.CountAsync(p => p.HasSecurity),
                HasParking = await _context.ParentProperties.CountAsync(p => p.HasParking),
                HasGarden = await _context.ParentProperties.CountAsync(p => p.HasGarden),
                HasPlayground = await _context.ParentProperties.CountAsync(p => p.HasPlayground),
                HasClubhouse = await _context.ParentProperties.CountAsync(p => p.HasClubhouse)
            };

            return Ok(new
            {
                TotalCount = totalCount,
                ByType = byType,
                ByBedrooms = byBedrooms,
                ByFinishing = byFinishing,
                AverageArea = Math.Round(averageArea, 2),
                Amenities = amenities
            });
        }
    }

    public class ParentPropertyFilters
    {
        public PropertyType? Type { get; set; }
        public int? Bedrooms { get; set; }
        public int? Bathrooms { get; set; }
        public decimal? MinArea { get; set; }
        public decimal? MaxArea { get; set; }
        public string? Governorate { get; set; }
        public string? City { get; set; }
        public bool? HasPool { get; set; }
        public bool? HasGym { get; set; }
        public bool? HasSecurity { get; set; }
        public bool? HasParking { get; set; }
        public FinishingType? FinishingType { get; set; }
        public string? SortBy { get; set; } = "date_desc";
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    public class FindOrCreateParentPropertyRequest
    {
        public string? ProjectName { get; set; }
        public PropertyType Type { get; set; }
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public decimal AreaSqm { get; set; }
        public FinishingType FinishingType { get; set; }
        public bool HasPool { get; set; }
        public bool HasGym { get; set; }
        public bool HasSecurity { get; set; }
        public bool HasParking { get; set; }
        public bool HasGarden { get; set; }
        public bool HasPlayground { get; set; }
        public bool HasClubhouse { get; set; }
    }
}
