class LiveStream {
  final String streamId;
  final String developerId;
  final String developerName;
  final String? developerProfileImageUrl;
  final String title;
  final String? description;
  final String streamUrl;
  final String? thumbnailUrl;
  final String status; // "Live", "Ended", "Scheduled"
  final int viewerCount;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  LiveStream({
    required this.streamId,
    required this.developerId,
    required this.developerName,
    this.developerProfileImageUrl,
    required this.title,
    this.description,
    required this.streamUrl,
    this.thumbnailUrl,
    required this.status,
    required this.viewerCount,
    required this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return LiveStream(
      streamId: parseId(json['streamId']),
      developerId: parseId(json['developerId']),
      developerName: json['developerName'] ?? '',
      developerProfileImageUrl: json['developerProfileImageUrl'],
      title: json['title'] ?? '',
      description: json['description'],
      streamUrl: json['streamUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      status: json['status'] ?? 'Scheduled',
      viewerCount: json['viewerCount'] ?? 0,
      startTime: DateTime.parse(
        json['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'developerId': developerId,
      'developerName': developerName,
      'developerProfileImageUrl': developerProfileImageUrl,
      'title': title,
      'description': description,
      'streamUrl': streamUrl,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'viewerCount': viewerCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isLive => status == 'Live';
  bool get isEnded => status == 'Ended';
  bool get isScheduled => status == 'Scheduled';
}

