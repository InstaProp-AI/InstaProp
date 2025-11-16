using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Poll
    {
        [Key]
        public long PollId { get; set; }

        [Required]
        public long PostId { get; set; }

        [ForeignKey(nameof(PostId))]
        public CommunityPost Post { get; set; } = null!;

        [Required]
        public string Question { get; set; } = string.Empty;

        // JSON array of {optionText, voteCount}
        [Column(TypeName = "TEXT")]
        [Required]
        public string Options { get; set; } = string.Empty;

        public DateTime? EndsAt { get; set; }

        public int TotalVotes { get; set; } = 0;

        // Flags
        public bool IsMultipleChoice { get; set; } = false;
        public bool AllowChangeVote { get; set; } = true;
        public bool ShowResultsBeforeVote { get; set; } = true;

        // Optional image for the poll question
        [MaxLength(500)]
        public string? ImageUrl { get; set; }

        // Relations
        public ICollection<PollVote> Votes { get; set; } = new List<PollVote>();
    }

    public class PollVote
    {
        [Key]
        public long VoteId { get; set; }

        [Required]
        public long PollId { get; set; }

        [ForeignKey(nameof(PollId))]
        public Poll Poll { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public int OptionIndex { get; set; } // Which option was selected

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

