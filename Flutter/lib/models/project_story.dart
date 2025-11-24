class ProjectStory {
  final String projectId;
  final String name;
  final String? location;
  final DateTime createdAt;
  final int propertyCount;
  final int activeAuctionCount;
  final int completedMilestones;
  final int upcomingMilestones;
  final double averageRoi;
  final ProjectStoryMilestone? latestMilestone;

  ProjectStory({
    required this.projectId,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.propertyCount,
    required this.activeAuctionCount,
    required this.completedMilestones,
    required this.upcomingMilestones,
    required this.averageRoi,
    required this.latestMilestone,
  });

  factory ProjectStory.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ProjectStory(
      projectId: parseId(json['projectId']),
      name: (json['name'] ?? '') as String,
      location: json['location'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      propertyCount: (json['propertyCount'] ?? 0) as int,
      activeAuctionCount: (json['activeAuctionCount'] ?? 0) as int,
      completedMilestones: (json['completedMilestones'] ?? 0) as int,
      upcomingMilestones: (json['upcomingMilestones'] ?? 0) as int,
      averageRoi: (json['averageRoi'] ?? 0).toDouble(),
      latestMilestone: json['latestMilestone'] != null
          ? ProjectStoryMilestone.fromJson(
              json['latestMilestone'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ProjectStoryMilestone {
  final String title;
  final DateTime targetDate;
  final DateTime? completedDate;

  ProjectStoryMilestone({
    required this.title,
    required this.targetDate,
    required this.completedDate,
  });

  factory ProjectStoryMilestone.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completedDate'];
    DateTime? completedDate;
    if (completedRaw is String && completedRaw.isNotEmpty) {
      completedDate = DateTime.parse(completedRaw);
    }

    return ProjectStoryMilestone(
      title: (json['title'] ?? '') as String,
      targetDate: DateTime.parse(
        json['targetDate'] ?? DateTime.now().toIso8601String(),
      ),
      completedDate: completedDate,
    );
  }
}

