import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

class ProjectService {
  final String baseUrl;
  final String? token;

  ProjectService(this.baseUrl, {this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Get projects by developer ID
  Future<List<ProjectModel>> getProjectsByDeveloper(int developerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/project/by-developer/$developerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching projects by developer: $e');
      throw Exception('Failed to load projects');
    }
  }

  // Get all public projects
  Future<List<ProjectModel>> getPublicProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/project/public'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching public projects: $e');
      throw Exception('Failed to load projects');
    }
  }

  // Get trending projects
  Future<List<ProjectModel>> getTrendingProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/project/public'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Sort by rating and return top projects
        final projects = data
            .map((json) => ProjectModel.fromJson(json))
            .toList();
        projects.sort((a, b) => b.developerRating.compareTo(a.developerRating));
        return projects.take(6).toList();
      } else {
        throw Exception(
          'Failed to load trending projects: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching trending projects: $e');
      throw Exception('Failed to load trending projects');
    }
  }

  // Get project details
  Future<ProjectDetailsModel> getProjectDetails(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/project/public/$projectId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ProjectDetailsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to load project details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching project details: $e');
      throw Exception('Failed to load project details');
    }
  }
}
