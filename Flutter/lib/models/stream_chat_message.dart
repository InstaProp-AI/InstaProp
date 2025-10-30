class StreamChatMessage {
  final int messageId;
  final int streamId;
  final int userId;
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
    return StreamChatMessage(
      messageId: json['messageId'] ?? 0,
      streamId: json['streamId'] ?? 0,
      userId: json['userId'] ?? 0,
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

