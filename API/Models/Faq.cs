using System;
using System.ComponentModel.DataAnnotations;

namespace PropertyFlipperAPI.Models
{
    public class Faq
    {
        public int FaqId { get; set; }

        [Required]
        [MaxLength(250)]
        public string Question { get; set; } = string.Empty;

        [Required]
        public string Answer { get; set; } = string.Empty;

        public int DisplayOrder { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
