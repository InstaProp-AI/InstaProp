using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    public class CreateCommunityDto
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public CommunityScopeType ScopeType { get; set; }

        [Required]
        public CommunityAccessType AccessType { get; set; }

        public List<long>? ProjectIds { get; set; } // For ProjectBased scope
        public List<long>? DeveloperIds { get; set; } // For DeveloperBased scope
    }

    public class UpdateCommunityDto
    {
        [MaxLength(200)]
        public string? Name { get; set; }

        public string? Description { get; set; }

        public CommunityAccessType? AccessType { get; set; }
    }

    public class CommunityResponseDto
    {
        public long CommunityId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public CommunityScopeType ScopeType { get; set; }
        public CommunityAccessType AccessType { get; set; }
        public List<long> ProjectIds { get; set; } = new();
        public List<long> DeveloperIds { get; set; } = new();
        public string? CoverPhotoUrl { get; set; }
        public int MemberCount { get; set; }
        public int PostCount { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsJoined { get; set; }
        public bool CanJoin { get; set; }
        public bool IsLocked { get; set; }
        public CommunityMemberRole? UserRole { get; set; }
    }

    public class CreatePostDto
    {
        [Required]
        public string Content { get; set; } = string.Empty;

        public string? ImageUrl { get; set; }

        public PostType PostType { get; set; } = PostType.Regular;

        public List<string>? Categories { get; set; }

        // For polls
        public CreatePollDto? Poll { get; set; }
    }

    public class CreatePollDto
    {
        [Required]
        public string Question { get; set; } = string.Empty;

        [Required]
        [MinLength(2)]
        public List<string> Options { get; set; } = new();

        public DateTime? EndsAt { get; set; }
    }

    public class PostResponseDto
    {
        public long PostId { get; set; }
        public long CommunityId { get; set; }
        public string CommunityName { get; set; } = string.Empty;
        public string? CommunityCoverPhotoUrl { get; set; }
        public CommunityAccessType CommunityAccessType { get; set; }
        public bool IsUserJoinedCommunity { get; set; }
        public long AuthorId { get; set; }
        public string AuthorName { get; set; } = string.Empty;
        public string AuthorType { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public PostType PostType { get; set; }
        public bool IsPinned { get; set; }
        public int LikeCount { get; set; }
        public int CommentCount { get; set; }
        public bool IsLiked { get; set; }
        public List<string> Categories { get; set; } = new();
        public PollResponseDto? Poll { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class PollResponseDto
    {
        public long PollId { get; set; }
        public string Question { get; set; } = string.Empty;
        public List<PollOptionDto> Options { get; set; } = new();
        public int TotalVotes { get; set; }
        public DateTime? EndsAt { get; set; }
        public bool HasVoted { get; set; }
        public int? UserVoteOptionIndex { get; set; }
    }

    public class PollOptionDto
    {
        public string Text { get; set; } = string.Empty;
        public int VoteCount { get; set; }
        public double Percentage { get; set; }
    }

    public class CreateCommentDto
    {
        [Required]
        public string Content { get; set; } = string.Empty;

        public long? ParentCommentId { get; set; }
    }

    public class CommentResponseDto
    {
        public long CommentId { get; set; }
        public long PostId { get; set; }
        public long AuthorId { get; set; }
        public string AuthorName { get; set; } = string.Empty;
        public string AuthorType { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public long? ParentCommentId { get; set; }
        public int LikeCount { get; set; }
        public bool IsLiked { get; set; }
        public List<CommentResponseDto> Replies { get; set; } = new();
        public DateTime CreatedAt { get; set; }
    }
}

