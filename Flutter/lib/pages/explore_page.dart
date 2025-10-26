import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';
import '../widgets/community_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Community> _trendingCommunities = [];
  List<Community> _suggestedCommunities = [];
  List<dynamic> _popularMembers = [];
  bool _isLoadingTrending = false;
  bool _isLoadingSuggested = false;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadTrendingCommunities();
    _loadSuggestedCommunities();
    _loadPopularMembers();
  }

  Future<void> _loadTrendingCommunities() async {
    setState(() => _isLoadingTrending = true);
    final response = await CommunityService.getTrendingCommunities();
    if (response.success && response.data != null) {
      setState(() {
        _trendingCommunities = response.data as List<Community>;
        _isLoadingTrending = false;
      });
    } else {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _loadSuggestedCommunities() async {
    setState(() => _isLoadingSuggested = true);
    final response = await CommunityService.getSuggestedCommunities();
    if (response.success && response.data != null) {
      setState(() {
        _suggestedCommunities = response.data as List<Community>;
        _isLoadingSuggested = false;
      });
    } else {
      setState(() => _isLoadingSuggested = false);
    }
  }

  Future<void> _loadPopularMembers() async {
    setState(() => _isLoadingMembers = true);
    final response = await CommunityService.getPopularMembers();
    if (response.success && response.data != null) {
      setState(() {
        _popularMembers = response.data as List<dynamic>;
        _isLoadingMembers = false;
      });
    } else {
      setState(() => _isLoadingMembers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Suggested'),
            Tab(icon: Icon(Icons.people), text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendingCommunities(),
          _buildSuggestedCommunities(),
          _buildPopularMembers(),
        ],
      ),
    );
  }

  Widget _buildTrendingCommunities() {
    if (_isLoadingTrending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trendingCommunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No trending communities yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrendingCommunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trendingCommunities.length,
        itemBuilder: (context, index) {
          final community = _trendingCommunities[index];
          return CommunityCard(community: community);
        },
      ),
    );
  }

  Widget _buildSuggestedCommunities() {
    if (_isLoadingSuggested) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestedCommunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestedCommunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestedCommunities.length,
        itemBuilder: (context, index) {
          final community = _suggestedCommunities[index];
          return CommunityCard(community: community);
        },
      ),
    );
  }

  Widget _buildPopularMembers() {
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_popularMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No popular members found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPopularMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _popularMembers.length,
        itemBuilder: (context, index) {
          final member = _popularMembers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  member['firstName']?[0]?.toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              title: Text(
                '${member['firstName']} ${member['lastName']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${member['postCount'] ?? 0} posts • ${member['reputationPoints'] ?? 0} rep',
              ),
              trailing: Icon(Icons.star, color: Colors.amber),
            ),
          );
        },
      ),
    );
  }
}
