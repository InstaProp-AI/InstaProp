import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import 'project_details_page.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  late final ProjectService _projectService;
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _loading = true;
  bool _isGridView = false;
  String _searchQuery = '';
  String _selectedLocation = 'All';

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService(ApiClient.baseUrl);
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectService.getPublicProjects();
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _loading = false;
      });
    } catch (e) {
      print('Error loading projects: $e');
      setState(() => _loading = false);
    }
  }

  void _filterProjects() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (project.location?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);

        final matchesLocation =
            _selectedLocation == 'All' ||
            (project.location?.contains(_selectedLocation) ?? false);

        return matchesSearch && matchesLocation;
      }).toList();
    });
  }

  Set<String> get _locations {
    final locations = <String>{'All'};
    for (var project in _projects) {
      if (project.location != null && project.location!.isNotEmpty) {
        locations.add(project.location!);
      }
    }
    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterProjects();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _locations.map((location) {
                      final isSelected = _selectedLocation == location;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(location),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedLocation = location);
                            _filterProjects();
                          },
                          backgroundColor: AppColors.background,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Projects list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: _isGridView ? _buildGridView() : _buildListView(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        return _buildProjectGridItem(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProjectDetailsPage(projectId: project.projectId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (project.featuredImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  project.featuredImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 180, color: AppColors.background),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (project.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.location!,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: project.developerProfileImage != null
                            ? NetworkImage(project.developerProfileImage!)
                            : null,
                        child: project.developerProfileImage == null
                            ? Text(
                                (project.developerCompany ??
                                    project.developerName)[0],
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.developerCompany ?? project.developerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  project.developerRating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${project.propertiesCount} properties',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGridItem(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProjectDetailsPage(projectId: project.projectId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.featuredImageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    project.featuredImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.propertiesCount} properties',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text(
            'No projects found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
