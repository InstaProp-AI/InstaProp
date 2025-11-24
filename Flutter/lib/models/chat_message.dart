class ChatMessage {
  final String messageId;
  final String senderId;
  final String? senderName;
  final String content;
  final String? propertyId;
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

  bool get hasProperty => propertyId != null && propertyId!.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ChatMessage(
      messageId: parseId(json['messageId']),
      senderId: parseId(json['senderId']),
      senderName: json['senderName'],
      content: json['content'] ?? '',
      propertyId: parseOptionalId(json['propertyId']),
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) {
        if (id == 0) return null; // Legacy: 0 means null
        return id.toString();
      }
      return id.toString();
    }

    return ChatMessage(
      messageId: parseId(json['messageId']),
      senderId: parseId(json['senderId']),
      senderName: null,
      content: json['content'] ?? '',
      propertyId: parseOptionalId(json['propertyId']),
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
