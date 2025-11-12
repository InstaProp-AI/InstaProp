import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faq.dart';
import '../models/help_chat.dart';

class HelpService {
  final String baseUrl;
  final String? token;

  HelpService(this.baseUrl, {this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<List<Faq>> getFaqPreview({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/api/help/faq?limit=$limit');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Faq.fromJson(json)).toList();
    }

    throw Exception('Failed to load FAQs: ${response.statusCode}');
  }

  Future<List<Faq>> getAllFaq() async {
    final uri = Uri.parse('$baseUrl/api/help/faq/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Faq.fromJson(json)).toList();
    }

    throw Exception('Failed to load FAQs: ${response.statusCode}');
  }

  Future<HelpChatDetails?> getSupportChat() async {
    if (token == null) {
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/helpchat');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return HelpChatDetails.fromJson(json.decode(response.body));
    }

    if (response.statusCode == 401) {
      return null;
    }

    throw Exception('Failed to load support chat: ${response.statusCode}');
  }

  Future<HelpChatSendResponse> sendSupportMessage(String content) async {
    if (token == null) {
      throw Exception('Authentication required');
    }

    final uri = Uri.parse('$baseUrl/api/helpchat/messages');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 200) {
      return HelpChatSendResponse.fromJson(json.decode(response.body));
    }

    throw Exception('Failed to send message: ${response.statusCode}');
  }
}
