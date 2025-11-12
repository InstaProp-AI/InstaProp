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
  final bool isSupportChat;

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
      isSupportChat: json['isSupportChat'] ?? false,
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
      isSupportChat: json['isSupportChat'] ?? false,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}
