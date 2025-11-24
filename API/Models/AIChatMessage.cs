using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class AIChatMessage
    {
        [Key]
        public Guid MessageId { get; set; }

        [Required]
        public Guid AIChatId { get; set; }

        [ForeignKey(nameof(AIChatId))]
        public AIChat AIChat { get; set; } = null!;

        [Required]
        [MaxLength(20)]
        public string Role { get; set; } = string.Empty; // User, Assistant

        [Required]
        public string Content { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string MessageType { get; set; } = "Text"; // Text, PropertyCard, DeveloperCard, ProjectCard, OptionsPrompt

        // Optional linked entities for card messages
        public Guid? PropertyId { get; set; }
        public Guid? ProjectId { get; set; }
        public Guid? DeveloperId { get; set; }

        // Store options for OptionsPrompt messages (JSON array)
        public string? Options { get; set; }
        public string? QuestionType { get; set; } // budget, location, bedrooms, bathrooms, propertyType

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}


