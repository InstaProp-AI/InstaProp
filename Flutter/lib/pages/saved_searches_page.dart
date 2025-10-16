import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import 'dart:convert';

class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({super.key});

  @override
  State<SavedSearchesPage> createState() => _SavedSearchesPageState();
}

class _SavedSearchesPageState extends State<SavedSearchesPage> {
  List<dynamic> savedSearches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // For now, use empty data as saved searches endpoints might not be implemented
      setState(() {
        savedSearches = [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading saved searches: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSavedSearch(int searchId) async {
    final appState = Provider.of<AppState>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: const Text(
          'Are you sure you want to delete this saved search?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // TODO: Implement delete endpoint when backend is ready
      _loadSavedSearches();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved search deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting saved search')),
        );
      }
    }
  }

  Future<void> _toggleNotifications(int searchId, bool currentValue) async {
    try {
      // TODO: Implement toggle endpoint when backend is ready
      _loadSavedSearches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating notification settings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.token == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Searches'),
          backgroundColor: const Color(0xFF667eea),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'Login to view saved searches',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Searches'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedSearches.isEmpty
          ? _buildEmptyState()
          : _buildSearchesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSearchDialog(),
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Saved Searches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Save your favorite search filters to get notified when matching properties are listed',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showCreateSearchDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Saved Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedSearches.length,
      itemBuilder: (context, index) {
        final search = savedSearches[index];
        final filters = _parseFilters(search['filters']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
              child: const Icon(Icons.search, color: Color(0xFF667eea)),
            ),
            title: Text(
              search['searchName'] ?? 'Unnamed Search',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _getFiltersSummary(filters),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: search['notifyOnMatch'] ?? false,
                  onChanged: (value) => _toggleNotifications(
                    search['searchId'],
                    search['notifyOnMatch'] ?? false,
                  ),
                  activeColor: const Color(0xFF667eea),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSavedSearch(search['searchId']),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Filters:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...filters.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(entry.value.toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          search['notifyOnMatch'] ?? false
                              ? 'Notifications enabled'
                              : 'Notifications disabled',
                          style: TextStyle(
                            color: (search['notifyOnMatch'] ?? false)
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _parseFilters(String? filtersJson) {
    if (filtersJson == null || filtersJson.isEmpty) return {};
    try {
      return jsonDecode(filtersJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  String _getFiltersSummary(Map<String, dynamic> filters) {
    if (filters.isEmpty) return 'No filters';

    final parts = <String>[];
    if (filters.containsKey('minPrice') || filters.containsKey('maxPrice')) {
      parts.add(
        'Price: \$${filters['minPrice'] ?? '0'} - \$${filters['maxPrice'] ?? '∞'}',
      );
    }
    if (filters.containsKey('bedrooms')) {
      parts.add('${filters['bedrooms']} beds');
    }
    if (filters.containsKey('type')) {
      parts.add(filters['type']);
    }

    return parts.join(' • ');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Saved Searches'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💾 Save your favorite search filters'),
            SizedBox(height: 8),
            Text('🔔 Get notified when matching properties are listed'),
            SizedBox(height: 8),
            Text('⚡ Quickly access your common searches'),
            SizedBox(height: 8),
            Text('🎯 Never miss your dream property'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCreateSearchDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Saved Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Search Name',
                hintText: 'e.g., My Dream Home',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Search filters can be set when you search for properties. This saved search will use your current filters.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a search name')),
                );
                return;
              }

              Navigator.pop(context);
              await _createSavedSearch(nameController.text.trim());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSavedSearch(String name) async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // TODO: Implement create endpoint when backend is ready
      _loadSavedSearches();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved search created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating saved search')),
        );
      }
    }
  }
}
