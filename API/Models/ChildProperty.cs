using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    /// <summary>
    /// Child Property - Individual property unit that inherits from Parent Property
    /// Contains unique attributes specific to this unit (floor, view, phase, delivery date, etc.)
    /// </summary>
    public class ChildProperty
    {
        [Key]
        public int PropertyId { get; set; } // Keep same name for compatibility

        [ForeignKey("ParentProperty")]
        public int? ParentPropertyId { get; set; }

        [ForeignKey("Owner")]
        public long? OwnerId { get; set; }

        // Phase information (moved from parent to child)
        [MaxLength(50)]
        public string? Phase { get; set; } // "Phase 1", "Phase 2", "Phase 3", "Phase 4"

        // Unit-specific details
        public int? FloorNumber { get; set; }

        [MaxLength(50)]
        public string? UnitNumber { get; set; }

        [MaxLength(100)]
        public string? ViewType { get; set; } // Sea, Nile, Pyramid, Garden, Street

        [MaxLength(100)]
        public string? Orientation { get; set; } // North, South, East, West, etc.

        public DateTime? DeliveryDate { get; set; }

        public int? ParkingSlots { get; set; }
        public bool? HasStorageRoom { get; set; }

        // Purchase information (for owner)
        [Column(TypeName = "decimal(18,2)")]
        public decimal? BuyingPrice { get; set; } // Price owner paid when purchasing

        public DateTime? BuyingDate { get; set; } // When owner purchased this property

        // For developers adding multiple units
        public int Quantity { get; set; } = 1; // Default 1 for regular users

        // Unit-specific Amenities
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

        // View-specific flags
        public bool? SeaView { get; set; }
        public bool? NileView { get; set; }
        public bool? PyramidView { get; set; }
        public bool? GardenView { get; set; }
        public bool? StreetView { get; set; }

        // Legacy fields for compatibility (will be populated from parent)
        [MaxLength(500)]
        public string Name { get; set; } = string.Empty; // Auto-generated from parent + unit

        [MaxLength(2000)]
        public string Description { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Location { get; set; } = string.Empty; // From parent's project

        public string ImageUrl { get; set; } = string.Empty;
        public int SquareFeet { get; set; } // Calculated from parent's AreaSqm

        public int YearBuilt { get; set; } // Project's year

        public bool IsApproved { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Properties inherited from ParentProperty for compatibility
        public int Bedrooms { get; set; } // From parent
        public int Bathrooms { get; set; } // From parent
        public PropertyType Type { get; set; } = PropertyType.Apartment;
        public PropertyStatus Status { get; set; } = PropertyStatus.NotApproved; // Individual property status
        public long? ProjectId { get; set; } // Optional direct link to project

        // Navigation properties
        public virtual ParentProperty? ParentProperty { get; set; }
        public virtual Account? Owner { get; set; }
        public virtual ICollection<PropertyImage> PropertyImages { get; set; } = new List<PropertyImage>();
        public virtual ICollection<PropertyDoc> PropertyDocs { get; set; } = new List<PropertyDoc>();
        public virtual ICollection<Auction> Auctions { get; set; } = new List<Auction>();
        public virtual Project? Project { get; set; } // Optional link to Project table
        public virtual InstallmentSummary? InstallmentSummary { get; set; }
    }
}

