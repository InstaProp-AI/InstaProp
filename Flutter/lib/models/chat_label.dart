class ChatLabel {
  final String chatLabelId;
  final String chatId;
  final String developerId;
  final String userId;
  final String label; // "Bought", "HotBuyer", "NormalBuyer", "JustAsker"
  final String? notes;
  final DateTime labeledAt;
  final DateTime updatedAt;

  ChatLabel({
    required this.chatLabelId,
    required this.chatId,
    required this.developerId,
    required this.userId,
    required this.label,
    this.notes,
    required this.labeledAt,
    required this.updatedAt,
  });

  factory ChatLabel.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ChatLabel(
      chatLabelId: parseId(json['chatLabelId']),
      chatId: parseId(json['chatId']),
      developerId: parseId(json['developerId']),
      userId: parseId(json['userId']),
      label: json['label'] ?? '',
      notes: json['notes'],
      labeledAt: DateTime.parse(
        json['labeledAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatLabelId': chatLabelId,
      'chatId': chatId,
      'developerId': developerId,
      'userId': userId,
      'label': label,
      'notes': notes,
      'labeledAt': labeledAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatLabel copyWith({
    String? chatLabelId,
    String? chatId,
    String? developerId,
    String? userId,
    String? label,
    String? notes,
    DateTime? labeledAt,
    DateTime? updatedAt,
  }) {
    return ChatLabel(
      chatLabelId: chatLabelId ?? this.chatLabelId,
      chatId: chatId ?? this.chatId,
      developerId: developerId ?? this.developerId,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      labeledAt: labeledAt ?? this.labeledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatLabel(chatLabelId: $chatLabelId, chatId: $chatId, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatLabel && other.chatLabelId == chatLabelId;
  }

  @override
  int get hashCode => chatLabelId.hashCode;
}

// Chat label constants
class ChatLabelType {
  static const String bought = 'Bought';
  static const String hotBuyer = 'HotBuyer';
  static const String normalBuyer = 'NormalBuyer';
  static const String justAsker = 'JustAsker';

  static const List<String> allLabels = [
    bought,
    hotBuyer,
    normalBuyer,
    justAsker,
  ];

  static String getDisplayName(String label) {
    switch (label) {
      case bought:
        return 'Bought';
      case hotBuyer:
        return 'Hot Buyer';
      case normalBuyer:
        return 'Normal Buyer';
      case justAsker:
        return 'Just Asker';
      default:
        return label;
    }
  }
}
