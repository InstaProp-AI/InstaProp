import 'chat_message.dart';

class Chat {
  final String chatId;
  final String userId;
  final String? userName;
  final String developerId;
  final String? developerName;
  final String? projectId;
  final String? projectName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final String? lastMessage;
  final int unreadCount;
  final bool isSupportChat;
  final String? salesMemberId;
  final String? salesMemberName;
  final bool isAvailable; // For sales: indicates if chat is available to take

  Chat({
    required this.chatId,
    required this.userId,
    this.userName,
    required this.developerId,
    this.developerName,
    this.projectId,
    this.projectName,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isActive,
    this.lastMessage,
    required this.unreadCount,
    this.isSupportChat = false,
    this.salesMemberId,
    this.salesMemberName,
    this.isAvailable = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
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

    return Chat(
      chatId: parseId(json['chatId']),
      userId: parseId(json['userId']),
      userName: json['userName'],
      developerId: parseId(json['developerId']),
      developerName: json['developerName'],
      projectId: parseOptionalId(json['projectId']),
      projectName: json['projectName'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessageAt: DateTime.parse(
        json['lastMessageAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
      isSupportChat: json['isSupportChat'] ?? false,
      salesMemberId: parseOptionalId(json['salesMemberId']),
      salesMemberName: json['salesMemberName'],
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'developerId': developerId,
      'developerName': developerName,
      'projectId': projectId,
      'projectName': projectName,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'isActive': isActive,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'isSupportChat': isSupportChat,
      'salesMemberId': salesMemberId,
      'salesMemberName': salesMemberName,
      'isAvailable': isAvailable,
    };
  }
}

class ChatDetails {
  final String chatId;
  final String userId;
  final String? userName;
  final String developerId;
  final String? developerName;
  final String? projectId;
  final String? projectName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final bool isSupportChat;
  final List<ChatMessage> messages;

  ChatDetails({
    required this.chatId,
    required this.userId,
    this.userName,
    required this.developerId,
    this.developerName,
    this.projectId,
    this.projectName,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isActive,
    this.isSupportChat = false,
    required this.messages,
  });

  factory ChatDetails.fromJson(Map<String, dynamic> json) {
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

    return ChatDetails(
      chatId: parseId(json['chatId']),
      userId: parseId(json['userId']),
      userName: json['userName'],
      developerId: parseId(json['developerId']),
      developerName: json['developerName'],
      projectId: parseOptionalId(json['projectId']),
      projectName: json['projectName'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessageAt: DateTime.parse(
        json['lastMessageAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      isSupportChat: json['isSupportChat'] ?? false,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}
