import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  final String baseUrl;
  final String? token;

  NewsService(this.baseUrl, {this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Get latest news articles
  Future<List<NewsArticle>> getLatestNews({int count = 3}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/latest?count=$count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load latest news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest news: $e');
      throw Exception('Failed to load latest news');
    }
  }

  // Get all news with pagination
  Future<PaginatedNewsResponse> getAllNews({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news?page=$page&pageSize=$pageSize'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return PaginatedNewsResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news');
    }
  }

  // Get single news article by ID
  Future<NewsArticle> getNewsById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return NewsArticle.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('News article not found');
      } else {
        throw Exception('Failed to load news article: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news article: $e');
      throw Exception('Failed to load news article');
    }
  }

  // Search news with filters and pagination
  Future<PaginatedNewsResponse> searchNews({
    String? query,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/news/search').replace(
        queryParameters: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null && category.isNotEmpty) 'category': category,
          if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
          if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return PaginatedNewsResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching news: $e');
      throw Exception('Failed to search news');
    }
  }

  // Get available categories (this would need to be implemented in the backend)
  Future<List<String>> getCategories() async {
    try {
      // For now, return a static list of common categories
      // In a real implementation, this would be a separate API endpoint
      return [
        'General',
        'Real Estate',
        'Market Updates',
        'Technology',
        'Finance',
        'Investment',
        'Development',
        // Community category removed
      ];
    } catch (e) {
      print('Error fetching categories: $e');
      return ['General'];
    }
  }
}
