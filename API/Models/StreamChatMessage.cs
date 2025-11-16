using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class StreamChatMessage
    {
        [Key]
        public long MessageId { get; set; }

        [Required]
        public long StreamId { get; set; }

        [ForeignKey(nameof(StreamId))]
        public LiveStream Stream { get; set; } = null!;

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public Account User { get; set; } = null!;

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

