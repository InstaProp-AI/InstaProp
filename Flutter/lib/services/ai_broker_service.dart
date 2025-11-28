import 'api_client.dart';

class AIBrokerService {
  // Start a new AI broker conversation
  static Future<ApiResponse<AIBrokerConversation>> startConversation() async {
    return await ApiClient.post(
      '/api/aibroker/start-conversation',
      {},
      AIBrokerConversation.fromJson,
    );
  }

  // Send a message to AI broker
  static Future<ApiResponse<AIBrokerResponse>> sendMessage({
    required String aichatId,
    required String message,
    String? questionType,
  }) async {
    return await ApiClient.post('/api/aibroker/send-message', {
      'aichatId': aichatId,
      'message': message,
      'questionType': questionType,
    }, AIBrokerResponse.fromJson);
  }

  // Get conversation history
  static Future<ApiResponse<AIBrokerConversation>> getConversation(
    String aichatId,
  ) async {
    return await ApiClient.get(
      '/api/aibroker/conversation/$aichatId',
      AIBrokerConversation.fromJson,
    );
  }

  // Get all user's AI broker chats
  static Future<ApiResponse<List<AIBrokerChatSummary>>> getMyAIChats() async {
    return await ApiClient.getList(
      '/api/aibroker/my-chats',
      AIBrokerChatSummary.fromJson,
    );
  }

  // Get active AI chat (returns null if none exists)
  static Future<ApiResponse<AIBrokerChatSummary>> getActiveChat() async {
    return await ApiClient.get(
      '/api/aibroker/active-chat',
      AIBrokerChatSummary.fromJson,
    );
  }
}

// AI Chat Summary for list view
class AIBrokerChatSummary {
  final String aichatId;
  final String status;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int messageCount;

  AIBrokerChatSummary({
    required this.aichatId,
    required this.status,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory AIBrokerChatSummary.fromJson(Map<String, dynamic> json) {
    // Parse chat ID - now handles GUID strings
    String chatId = '';
    final possibleKeys = ['aiChatId', 'AIChatId', 'aichatId'];
    for (var key in possibleKeys) {
      if (json.containsKey(key) && json[key] != null) {
        chatId = json[key].toString();
        break;
      }
    }

    return AIBrokerChatSummary(
      aichatId: chatId,
      status: json['status'] ?? json['Status'] ?? '',
      lastMessage: json['lastMessage'] ?? json['LastMessage'] ?? '',
      lastMessageAt: DateTime.parse(
        json['lastMessageAt'] ??
            json['LastMessageAt'] ??
            DateTime.now().toIso8601String(),
      ),
      messageCount: json['messageCount'] ?? json['MessageCount'] ?? 0,
    );
  }
}

// Models
class AIBrokerConversation {
  final String aichatId;
  final List<AIBrokerMessage> messages;

  AIBrokerConversation({required this.aichatId, required this.messages});

  factory AIBrokerConversation.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing AIBrokerConversation from JSON: $json');

    List<AIBrokerMessage> messagesList = [];

    final messagesData = json['messages'] ?? json['Messages'];
    if (messagesData != null && messagesData is List) {
      try {
        messagesList = messagesData
            .map((messageData) {
              try {
                return AIBrokerMessage.fromJson(messageData as Map<String, dynamic>);
              } catch (e, stackTrace) {
                print('❌ Error parsing message: $e');
                print('   Stack trace: $stackTrace');
                print('   Message data: $messageData');
                rethrow;
              }
            })
            .toList();
      } catch (e, stackTrace) {
        print('❌ Error parsing messages list: $e');
        print('   Stack trace: $stackTrace');
        rethrow;
      }
    }

    // Parse chat ID - now handles GUID strings
    String chatId = '';

    // Try all possible key variations
    final possibleKeys = ['aiChatId', 'AIChatId', 'aichatId', 'Aichatid'];
    for (var key in possibleKeys) {
      if (json.containsKey(key) && json[key] != null) {
        chatId = json[key].toString();
        print('🔍 Found chatId with key "$key": $chatId');
        break;
      }
    }

    print('🔍 Final chatId: $chatId');

    return AIBrokerConversation(aichatId: chatId, messages: messagesList);
  }
}

class AIBrokerResponse {
  final List<AIBrokerMessage> messages;

  AIBrokerResponse({required this.messages});

  factory AIBrokerResponse.fromJson(Map<String, dynamic> json) {
    List<AIBrokerMessage> messagesList = [];

    final messagesData = json['messages'] ?? json['Messages'];
    if (messagesData != null && messagesData is List) {
      messagesList = messagesData
          .map((e) => AIBrokerMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AIBrokerResponse(messages: messagesList);
  }
}

class AIBrokerMessage {
  final int messageId;
  final String role;
  final String content;
  final String messageType;
  final List<String>? options;
  final String? questionType;
  final int? propertyId;
  final int? projectId;
  final int? developerId;
  final List<PropertySuggestion>? properties;
  final List<DeveloperSuggestion>? developers;
  final DateTime createdAt;

  AIBrokerMessage({
    required this.messageId,
    required this.role,
    required this.content,
    required this.messageType,
    this.options,
    this.questionType,
    this.propertyId,
    this.projectId,
    this.developerId,
    this.properties,
    this.developers,
    required this.createdAt,
  });

  factory AIBrokerMessage.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from int or string
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('⚠️ Failed to parse int from string: $value');
          return null;
        }
      }
      return null;
    }

    List<String>? optionsList;
    if (json['options'] != null || json['Options'] != null) {
      final opts = json['options'] ?? json['Options'];
      if (opts is List) {
        optionsList = opts.map((e) => e.toString()).toList();
      }
    }

    List<PropertySuggestion>? propertiesList;
    if (json['properties'] != null || json['Properties'] != null) {
      final props = json['properties'] ?? json['Properties'];
      if (props is List) {
        propertiesList = props
            .map((e) => PropertySuggestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    List<DeveloperSuggestion>? developersList;
    if (json['developers'] != null || json['Developers'] != null) {
      final devs = json['developers'] ?? json['Developers'];
      if (devs is List) {
        developersList = devs
            .map((e) => DeveloperSuggestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return AIBrokerMessage(
      messageId: parseInt(json['messageId'] ?? json['MessageId']) ?? 0,
      role: json['role'] ?? json['Role'] ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      messageType: json['messageType'] ?? json['MessageType'] ?? 'Text',
      options: optionsList,
      questionType: json['questionType'] ?? json['QuestionType'],
      propertyId: parseInt(json['propertyId'] ?? json['PropertyId']),
      projectId: parseInt(json['projectId'] ?? json['ProjectId']),
      developerId: parseInt(json['developerId'] ?? json['DeveloperId']),
      properties: propertiesList,
      developers: developersList,
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PropertySuggestion {
  final int propertyId;
  final String name;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final String imageUrl;
  final String type;
  final String status;
  final int? auctionId;
  final double currentPrice;
  final DateTime? auctionStartTime;
  final String? auctionStatus;

  PropertySuggestion({
    required this.propertyId,
    required this.name,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.imageUrl,
    required this.type,
    required this.status,
    this.auctionId,
    required this.currentPrice,
    this.auctionStartTime,
    this.auctionStatus,
  });

  factory PropertySuggestion.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from int or string
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('⚠️ Failed to parse int from string: $value');
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper to safely parse nullable int
    int? parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('⚠️ Failed to parse int from string: $value');
          return null;
        }
      }
      return null;
    }

    DateTime? startTime;
    final startTimeStr = json['auctionStartTime'] ?? json['AuctionStartTime'];
    if (startTimeStr != null && startTimeStr.toString().isNotEmpty) {
      try {
        startTime = DateTime.parse(startTimeStr.toString());
      } catch (e) {
        print('Error parsing auction start time: $e');
      }
    }

    return PropertySuggestion(
      propertyId: parseInt(json['propertyId'] ?? json['PropertyId']),
      name: json['name'] ?? json['Name'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      bedrooms: parseInt(json['bedrooms'] ?? json['Bedrooms']),
      bathrooms: parseInt(json['bathrooms'] ?? json['Bathrooms']),
      squareFeet: parseInt(json['squareFeet'] ?? json['SquareFeet']),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
      type: json['type'] ?? json['Type'] ?? '',
      status: json['status'] ?? json['Status'] ?? '',
      auctionId: parseIntNullable(json['auctionId'] ?? json['AuctionId']),
      currentPrice: (json['currentPrice'] ?? json['CurrentPrice'] ?? 0)
          .toDouble(),
      auctionStartTime: startTime,
      auctionStatus: json['auctionStatus'] ?? json['AuctionStatus'],
    );
  }
}

class DeveloperSuggestion {
  final int developerId;
  final String name;
  final String companyName;
  final double averageRating;
  final int totalProjects;
  final int totalRatings;
  final String specialization;

  DeveloperSuggestion({
    required this.developerId,
    required this.name,
    required this.companyName,
    required this.averageRating,
    required this.totalProjects,
    required this.totalRatings,
    required this.specialization,
  });

  factory DeveloperSuggestion.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from int or string
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('⚠️ Failed to parse int from string: $value');
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return DeveloperSuggestion(
      developerId: parseInt(json['developerId'] ?? json['DeveloperId']),
      name: json['name'] ?? json['Name'] ?? '',
      companyName: json['companyName'] ?? json['CompanyName'] ?? '',
      averageRating: (json['averageRating'] ?? json['AverageRating'] ?? 0)
          .toDouble(),
      totalProjects: parseInt(json['totalProjects'] ?? json['TotalProjects']),
      totalRatings: parseInt(json['totalRatings'] ?? json['TotalRatings']),
      specialization: json['specialization'] ?? json['Specialization'] ?? '',
    );
  }
}
