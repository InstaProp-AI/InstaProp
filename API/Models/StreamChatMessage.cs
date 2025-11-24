using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class StreamChatMessage
    {
        [Key]
        public Guid MessageId { get; set; }

        [Required]
        public Guid StreamId { get; set; }

        [ForeignKey(nameof(StreamId))]
        public LiveStream Stream { get; set; } = null!;

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public AccountBase User { get; set; } = null!;

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

