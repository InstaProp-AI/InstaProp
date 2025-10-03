using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace PropertyFlipperAPI.Models
{
public class Property
{
    [Key]
    public long PropertyId { get; set; }

    [Required]
    public long OwnerId { get; set; }

    [ForeignKey(nameof(OwnerId))]
    public User Owner { get; set; }

    [MaxLength(200)]
    public string Name { get; set; }

    public string Description { get; set; }

    public string Location { get; set; } // could be address or lat-long string

    public decimal StartingPrice { get; set; }

    public bool IsApproved { get; set; } = false; // set by admin

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    // 🔗 Relations
    public ICollection<PropertyDoc> PropertyDocs { get; set; } = new List<PropertyDoc>();
    public ICollection<Auction> Auctions { get; set; } = new List<Auction>();
}
}