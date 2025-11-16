using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public enum CommunityScopeType
    {
        ProjectBased = 0,
        DeveloperBased = 1
    }

    public enum CommunityAccessType
    {
        Private = 0,        // Only members of chosen projects/developers
        PublicOwners = 1,   // Any property owner
        PublicAll = 2       // Anyone, even not logged in
    }

    public class Community
    {
        [Key]
        public long CommunityId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public long CreatedById { get; set; }

        [ForeignKey(nameof(CreatedById))]
        public Account CreatedBy { get; set; } = null!;

        [Required]
        public CommunityScopeType ScopeType { get; set; } = CommunityScopeType.ProjectBased;

        [Required]
        public CommunityAccessType AccessType { get; set; } = CommunityAccessType.Private;

        // JSON arrays for multi-select projects/developers
        [Column(TypeName = "TEXT")]
        public string? ProjectIds { get; set; } // JSON array of project IDs

        [Column(TypeName = "TEXT")]
        public string? DeveloperIds { get; set; } // JSON array of developer IDs

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public bool IsActive { get; set; } = true;

        // Cover photo
        [MaxLength(500)]
        public string? CoverPhotoUrl { get; set; }

        // Computed counts
        public int MemberCount { get; set; } = 0;
        public int PostCount { get; set; } = 0;

        // Relations
        public ICollection<CommunityMember> Members { get; set; } = new List<CommunityMember>();
        public ICollection<CommunityPost> Posts { get; set; } = new List<CommunityPost>();
    }
}

