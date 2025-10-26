enum CommunityScopeType { projectBased, developerBased }

enum CommunityAccessType { private, publicOwners, publicAll }

enum CommunityMemberRole { member, moderator, creator }

class Community {
  final int communityId;
  final String name;
  final String? description;
  final int createdById;
  final CommunityScopeType scopeType;
  final CommunityAccessType accessType;
  final List<int> projectIds;
  final List<int> developerIds;
  final String? coverPhotoUrl;
  final DateTime createdAt;
  final bool isActive;
  final int memberCount;
  final int postCount;
  final bool isJoined;
  final bool canJoin;
  final bool isLocked;
  final CommunityMemberRole? userRole;

  Community({
    required this.communityId,
    required this.name,
    this.description,
    required this.createdById,
    required this.scopeType,
    required this.accessType,
    this.projectIds = const [],
    this.developerIds = const [],
    this.coverPhotoUrl,
    required this.createdAt,
    this.isActive = true,
    this.memberCount = 0,
    this.postCount = 0,
    this.isJoined = false,
    this.canJoin = false,
    this.isLocked = false,
    this.userRole,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      communityId: json['communityId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      createdById: json['createdById'] ?? 0,
      scopeType: _parseScopeType(json['scopeType']),
      accessType: _parseAccessType(json['accessType']),
      projectIds:
          (json['projectIds'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [],
      developerIds:
          (json['developerIds'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [],
      coverPhotoUrl: json['coverPhotoUrl'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      memberCount: json['memberCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      isJoined: json['isJoined'] ?? false,
      canJoin: json['canJoin'] ?? false,
      isLocked: json['isLocked'] ?? false,
      userRole: json['userRole'] != null
          ? CommunityMemberRole.values.firstWhere(
              (e) =>
                  e.toString().split('.').last ==
                  json['userRole']?.toString().toLowerCase(),
              orElse: () => CommunityMemberRole.member,
            )
          : null,
    );
  }

  static CommunityAccessType _parseAccessType(dynamic value) {
    if (value == null) return CommunityAccessType.private;

    // Handle integer values (0=Private, 1=PublicOwners, 2=PublicAll)
    if (value is int) {
      return CommunityAccessType.values[value.clamp(0, 2)];
    }

    // Handle string values
    final str = value.toString().toLowerCase();
    return CommunityAccessType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => CommunityAccessType.private,
    );
  }

  static CommunityScopeType _parseScopeType(dynamic value) {
    if (value == null) return CommunityScopeType.projectBased;

    // Handle integer values (0=ProjectBased, 1=DeveloperBased)
    if (value is int) {
      return CommunityScopeType.values[value.clamp(0, 1)];
    }

    // Handle string values
    final str = value.toString().toLowerCase();
    return CommunityScopeType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => CommunityScopeType.projectBased,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'name': name,
      'description': description,
      'createdById': createdById,
      'scopeType': scopeType.toString().split('.').last,
      'accessType': accessType.toString().split('.').last,
      'projectIds': projectIds,
      'developerIds': developerIds,
      'coverPhotoUrl': coverPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'memberCount': memberCount,
      'postCount': postCount,
      'isJoined': isJoined,
      'canJoin': canJoin,
      'isLocked': isLocked,
      'userRole': userRole?.toString().split('.').last,
    };
  }
}
