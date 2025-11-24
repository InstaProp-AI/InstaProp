class StreamChatMessage {
  final String messageId;
  final String streamId;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String message;
  final DateTime createdAt;

  StreamChatMessage({
    required this.messageId,
    required this.streamId,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.message,
    required this.createdAt,
  });

  factory StreamChatMessage.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return StreamChatMessage(
      messageId: parseId(json['messageId']),
      streamId: parseId(json['streamId']),
      userId: parseId(json['userId']),
      userName: json['userName'] ?? 'Unknown User',
      userProfileImageUrl: json['userProfileImageUrl'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

