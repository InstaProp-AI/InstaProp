using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Property - Individual ownable property unit with all attributes on one record.
    /// </summary>
    public class Property
    {
        [Key]
        public Guid PropertyId { get; set; }

        [ForeignKey("Owner")]
        public Guid? OwnerId { get; set; }

        [MaxLength(200)]
        public string? ProjectName { get; set; }

        public Guid? ProjectId { get; set; }

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

        [Column(TypeName = "decimal(18,2)")]
        public decimal? BuyingPrice { get; set; }

        public DateTime? BuyingDate { get; set; }

        public int Quantity { get; set; } = 1;

        [MaxLength(100)]
        public string FinishingType { get; set; } = "Finished";

        // Compound / project amenities
        public bool HasPool { get; set; }
        public bool HasGym { get; set; }
        public bool HasSecurity { get; set; }
        public bool HasParking { get; set; }
        public bool HasPlayground { get; set; }

        // Unit amenities
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

        [MaxLength(500)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string Description { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Location { get; set; } = string.Empty;

        public string ImageUrl { get; set; } = string.Empty;
        public int SquareFeet { get; set; }

        public int YearBuilt { get; set; }

        public bool IsApproved { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public PropertyType Type { get; set; } = PropertyType.Apartment;
        public PropertyStatus Status { get; set; } = PropertyStatus.NotApproved;

        public virtual AccountBase? Owner { get; set; }
        public virtual Project? Project { get; set; }
        public virtual ICollection<PropertyImage> PropertyImages { get; set; } = new List<PropertyImage>();
        public virtual ICollection<PropertyDoc> PropertyDocs { get; set; } = new List<PropertyDoc>();
        public virtual ICollection<Auction> Auctions { get; set; } = new List<Auction>();
        public virtual InstallmentSummary? InstallmentSummary { get; set; }
    }
}
