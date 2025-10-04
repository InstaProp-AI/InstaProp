using System.ComponentModel.DataAnnotations;

namespace PropertyFlipperAPI.Models
{
    public class PropertyDto
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string? Location { get; set; }

        public decimal StartingPrice { get; set; }

        public int Bedrooms { get; set; }

        public int Bathrooms { get; set; }

        public int SquareFeet { get; set; }

        public int YearBuilt { get; set; }

        public string? Category { get; set; } = "Residential";

        public string? ImageUrl { get; set; } = string.Empty;
    }
}