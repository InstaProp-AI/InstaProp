using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public enum CommunityMemberRole
    {
        Member = 0,
        Moderator = 1,
        Creator = 2
    }

    public class CommunityMember
    {
        [Key]
        public long MemberId { get; set; }

        [Required]
        public long CommunityId { get; set; }

        [ForeignKey(nameof(CommunityId))]
        public Community Community { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        public CommunityMemberRole Role { get; set; } = CommunityMemberRole.Member;

        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    }
}

