import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auction_request.dart';
import 'api_client.dart';

class AuctionRequestService {
  static const String _baseUrl = 'http://localhost:5284/api';

  Future<AuctionRequestResponse> createAuctionRequest(
    AuctionRequest request,
  ) async {
    final token = await ApiClient.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    print('🚀 Creating auction request for property ${request.propertyId}');
    print('📤 Request data: ${jsonEncode(request.toJson())}');

    final response = await http.post(
      Uri.parse('$_baseUrl/Auction/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AuctionRequestResponse.fromJson(data);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to create auction request',
      );
    }
  }

  Future<List<AuctionRequest>> getAuctionRequests() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/Auction/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AuctionRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch auction requests');
    }
  }
}
