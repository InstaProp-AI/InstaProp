import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/chat_message.dart';

class ChatService {
  final String baseUrl;
  final String? token;

  ChatService(this.baseUrl, {this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Get all chats for current user
  Future<List<Chat>> getChats() async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chats: $e');
      throw Exception('Failed to load chats');
    }
  }

  // Get specific chat with messages
  Future<ChatDetails> getChatDetails(int chatId) async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/$chatId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ChatDetails.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat details: $e');
      throw Exception('Failed to load chat');
    }
  }

  // Create new chat with developer
  Future<Chat> createChat({required int developerId, int? projectId}) async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: headers,
        body: json.encode({'developerId': developerId, 'projectId': projectId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Chat.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating chat: $e');
      throw Exception('Failed to create chat');
    }
  }

  // Send message in chat
  Future<ChatMessage> sendMessage({
    required int chatId,
    required String content,
    int? propertyId,
  }) async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/$chatId/message'),
        headers: headers,
        body: json.encode({'content': content, 'propertyId': propertyId}),
      );

      if (response.statusCode == 200) {
        return ChatMessage.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Mark chat messages as read
  Future<void> markAsRead(int chatId) async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/chat/$chatId/read'),
        headers: headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      // Don't throw, this is a non-critical operation
    }
  }

  // Get total unread count across all chats
  Future<int> getUnreadCount() async {
    try {
      final chats = await getChats();
      int total = 0;
      for (var chat in chats) {
        total += chat.unreadCount;
      }
      return total;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
