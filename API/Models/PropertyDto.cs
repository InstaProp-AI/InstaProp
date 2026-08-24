using System;
using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    public class PropertyDto
    {
        public string? Description { get; set; }

        public string? Location { get; set; }

        public int Bedrooms { get; set; }

        public int Bathrooms { get; set; }

        public int SquareFeet { get; set; }

        public int YearBuilt { get; set; }

        [Required]
        public string Type { get; set; } = PropertyTypeHelper.ToDisplayName(PropertyType.Apartment);

        public string? ImageUrl { get; set; } = string.Empty;

        public Guid? ProjectId { get; set; }
        public string? ProjectName { get; set; }

        [MaxLength(100)]
        public string? FinishingType { get; set; }

        public bool HasPool { get; set; }
        public bool HasGym { get; set; }
        public bool HasSecurity { get; set; }
        public bool HasParking { get; set; }
        public bool HasPlayground { get; set; }

        [MaxLength(50)]
        public string? Phase { get; set; }

        public int? FloorNumber { get; set; }

        [MaxLength(50)]
        public string? UnitNumber { get; set; }

        [MaxLength(100)]
        public string? ViewType { get; set; }

        [MaxLength(100)]
        public string? Orientation { get; set; }

        public DateTime? DeliveryDate { get; set; }

        public int? ParkingSlots { get; set; }
        public bool? HasStorageRoom { get; set; }

        public decimal? BuyingPrice { get; set; }
        public DateTime? BuyingDate { get; set; }

        public int Quantity { get; set; } = 1;

        public bool? HasNannyRoom { get; set; }
        public bool? HasDriverRoom { get; set; }
        public bool? HasMaidRoom { get; set; }
        public bool? HasPrivatePool { get; set; }
        public bool? HasRoofAccess { get; set; }
        public bool? HasBalcony { get; set; }
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
        public bool? SmartHome { get; set; }
        public bool? CentralAC { get; set; }
        public bool? NaturalGas { get; set; }
        public bool? HasGenerator { get; set; }
        public bool? SeaView { get; set; }
        public bool? NileView { get; set; }
        public bool? PyramidView { get; set; }
        public bool? GardenView { get; set; }
        public bool? StreetView { get; set; }

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
