class HelpChatDetails {
  final int? chatId;
  final String supportTitle;
  final List<HelpChatMessage> messages;

  HelpChatDetails({
    required this.chatId,
    required this.supportTitle,
    required this.messages,
  });

  bool get hasChat => chatId != null;

  factory HelpChatDetails.fromJson(Map<String, dynamic> json) {
    return HelpChatDetails(
      chatId: json['chatId'],
      supportTitle: json['supportTitle'] ?? 'Customer Support',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => HelpChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class HelpChatMessage {
  final int messageId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  HelpChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory HelpChatMessage.fromJson(Map<String, dynamic> json) {
    return HelpChatMessage(
      messageId: json['messageId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isMine: json['isMine'] ?? false,
    );
  }
}

class HelpChatSendResponse {
  final int chatId;
  final bool createdNewChat;
  final String supportTitle;
  final HelpChatMessage message;

  HelpChatSendResponse({
    required this.chatId,
    required this.createdNewChat,
    required this.supportTitle,
    required this.message,
  });

  factory HelpChatSendResponse.fromJson(Map<String, dynamic> json) {
    return HelpChatSendResponse(
      chatId: json['chatId'] ?? 0,
      createdNewChat: json['createdNewChat'] ?? false,
      supportTitle: json['supportTitle'] ?? 'Customer Support',
      message: HelpChatMessage.fromJson(json['message'] ?? {}),
    );
  }
}
