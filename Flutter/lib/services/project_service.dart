import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

class ProjectService {
  final String baseUrl;

  ProjectService(this.baseUrl);

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
      print('Error fetching projects: $e');
      throw Exception('Failed to load projects');
    }
  }

  // Get project details by ID
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

  // Search projects by name or location
  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      final projects = await getPublicProjects();

      if (query.isEmpty) return projects;

      return projects.where((project) {
        final nameLower = project.name.toLowerCase();
        final locationLower = project.location?.toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        return nameLower.contains(queryLower) ||
            locationLower.contains(queryLower);
      }).toList();
    } catch (e) {
      print('Error searching projects: $e');
      throw Exception('Failed to search projects');
    }
  }

  // Filter projects by location
  Future<List<ProjectModel>> filterByLocation(String location) async {
    try {
      final projects = await getPublicProjects();

      if (location.isEmpty || location == 'All') return projects;

      return projects.where((project) {
        final projectLocation = project.location?.toLowerCase() ?? '';
        return projectLocation.contains(location.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error filtering projects: $e');
      throw Exception('Failed to filter projects');
    }
  }

  // Get trending projects (most properties or highest rated developers)
  Future<List<ProjectModel>> getTrendingProjects() async {
    try {
      final projects = await getPublicProjects();

      // Sort by properties count and developer rating
      projects.sort((a, b) {
        final scoreA = a.propertiesCount * 10 + (a.developerRating * 5).toInt();
        final scoreB = b.propertiesCount * 10 + (b.developerRating * 5).toInt();
        return scoreB.compareTo(scoreA);
      });

      return projects.take(5).toList();
    } catch (e) {
      print('Error fetching trending projects: $e');
      throw Exception('Failed to fetch trending projects');
    }
  }
}
