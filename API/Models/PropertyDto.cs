using System;
using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    public class PropertyDto
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string? Location { get; set; }

        public int Bedrooms { get; set; }

        public int Bathrooms { get; set; }

        public int SquareFeet { get; set; }

        public int YearBuilt { get; set; }

        [Required]
        public string Type { get; set; } = PropertyTypeHelper.ToDisplayName(PropertyType.Apartment);

        public string? ImageUrl { get; set; } = string.Empty;

        public long? ProjectId { get; set; }
        public string? ProjectName { get; set; }

        public int? ParentPropertyId { get; set; }

        [MaxLength(50)]
        public string? UnitNumber { get; set; }

        public DateTime? DeliveryDate { get; set; }

        public bool? HasGarden { get; set; }
        public bool? HasClubhouse { get; set; }
        public bool? HasInfrastructure { get; set; }
        public bool? HasUndergroundParking { get; set; }
        public bool? HasMedicalCenter { get; set; }
        public bool? HasCommercialStrip { get; set; }
        public bool? HasBusinessHub { get; set; }
        public bool? HasOutdoorPools { get; set; }
        public bool? HasBicycleLanes { get; set; }
        public bool? HasJoggingTrail { get; set; }

        public InstallmentSummaryInputDto? InstallmentSummary { get; set; }
    }

    public class PropertyUpdateDto
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Description { get; set; } = string.Empty;

        [Required]
        public string Location { get; set; } = string.Empty;

        public InstallmentSummaryInputDto? InstallmentSummary { get; set; }
    }

    public class InstallmentSummaryInputDto
    {
        [Range(0, double.MaxValue)]
        public decimal? ContractedPrice { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? TotalPaid { get; set; }

        [Range(0, 100)]
        public decimal? DownPaymentPercent { get; set; }

        [Range(0, 100)]
        public int? TermYears { get; set; }

        public DateTime? InstallmentEndDate { get; set; }

        public bool? IsFullyPaid { get; set; }
    }
}