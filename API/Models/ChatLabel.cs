using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Chat Label - Developer conversation outcome tracking
    /// Allows developers to label conversations for sales tracking
    /// </summary>
    public class ChatLabel
    {
        [Key]
        public int ChatLabelId { get; set; }

        [Required]
        [ForeignKey("Chat")]
        public long ChatId { get; set; }

        [Required]
        [ForeignKey("Developer")]
        public long DeveloperId { get; set; }

        [Required]
        [ForeignKey("User")]
        public long UserId { get; set; }

        [Required]
        [MaxLength(50)]
        public string Label { get; set; } = string.Empty; // "Bought", "HotBuyer", "NormalBuyer", "JustAsker"

        [MaxLength(500)]
        public string? Notes { get; set; }

        public DateTime LabeledAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual Chat? Chat { get; set; }
        public virtual Account? Developer { get; set; }
        public virtual Account? User { get; set; }
    }

    /// <summary>
    /// Chat label types for developer conversation tracking
    /// </summary>
    public static class ChatLabelType
    {
        public const string Bought = "Bought";
        public const string HotBuyer = "HotBuyer";
        public const string NormalBuyer = "NormalBuyer";
        public const string JustAsker = "JustAsker";
    }
}

