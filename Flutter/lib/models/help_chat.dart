class HelpChatDetails {
  final String? chatId;
  final String supportTitle;
  final List<HelpChatMessage> messages;

  HelpChatDetails({
    required this.chatId,
    required this.supportTitle,
    required this.messages,
  });

  bool get hasChat => chatId != null;

  factory HelpChatDetails.fromJson(Map<String, dynamic> json) {
    // Helper to parse optional ID fields (handle both string GUID and int legacy formats)
    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return HelpChatDetails(
      chatId: parseOptionalId(json['chatId']),
      supportTitle: json['supportTitle'] ?? 'Customer Support',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => HelpChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class HelpChatMessage {
  final String messageId;
  final String senderId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return HelpChatMessage(
      messageId: parseId(json['messageId']),
      senderId: parseId(json['senderId']),
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
  final String chatId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return HelpChatSendResponse(
      chatId: parseId(json['chatId']),
      createdNewChat: json['createdNewChat'] ?? false,
      supportTitle: json['supportTitle'] ?? 'Customer Support',
      message: HelpChatMessage.fromJson(json['message'] ?? {}),
    );
  }
}
