import 'chat_message.dart';

class Chat {
  final int chatId;
  final int userId;
  final String? userName;
  final int developerId;
  final String? developerName;
  final int? projectId;
  final String? projectName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final String? lastMessage;
  final int unreadCount;

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
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      chatId: json['chatId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      developerId: json['developerId'] ?? 0,
      developerName: json['developerName'],
      projectId: json['projectId'],
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
    };
  }
}

class ChatDetails {
  final int chatId;
  final int userId;
  final String? userName;
  final int developerId;
  final String? developerName;
  final int? projectId;
  final String? projectName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
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
    required this.messages,
  });

  factory ChatDetails.fromJson(Map<String, dynamic> json) {
    return ChatDetails(
      chatId: json['chatId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      developerId: json['developerId'] ?? 0,
      developerName: json['developerName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessageAt: DateTime.parse(
        json['lastMessageAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}
