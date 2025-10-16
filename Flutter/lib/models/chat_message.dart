class ChatMessage {
  final int messageId;
  final int senderId;
  final String? senderName;
  final String content;
  final int? propertyId;
  final String? propertyName;
  final String? propertyLocation;
  final String? propertyImageUrl;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.propertyId,
    this.propertyName,
    this.propertyLocation,
    this.propertyImageUrl,
    required this.createdAt,
    required this.isRead,
  });

  bool get hasProperty => propertyId != null && propertyId! > 0;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'],
      content: json['content'] ?? '',
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      propertyLocation: json['propertyLocation'],
      propertyImageUrl: json['propertyImageUrl'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
    );
  }

  // For Firestore real-time messages
  factory ChatMessage.fromFirestore(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: null,
      content: json['content'] ?? '',
      propertyId: json['propertyId'] == 0 ? null : json['propertyId'],
      propertyName: null,
      propertyLocation: null,
      propertyImageUrl: null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyLocation': propertyLocation,
      'propertyImageUrl': propertyImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
