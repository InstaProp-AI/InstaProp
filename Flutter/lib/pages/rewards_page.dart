import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int totalPoints = 0;
  List<dynamic> recentRewards = [];
  List<dynamic> badges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRewardsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRewardsData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // For now, use mock data as rewards endpoints might not be implemented
      setState(() {
        totalPoints = 0;
        recentRewards = [];
        badges = [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading rewards: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.token == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'Login to view rewards',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Points
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, size: 60, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        '$totalPoints',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Activity'),
                Tab(text: 'Badges'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityTab(),
                _buildBadgesTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (recentRewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No activity yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Start exploring properties to earn points!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentRewards.length,
      itemBuilder: (context, index) {
        final reward = recentRewards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
              child: Text(
                '+${reward['points']}',
                style: const TextStyle(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(reward['rewardType'] ?? 'Unknown'),
            subtitle: Text(reward['description'] ?? ''),
            trailing: Text(
              _formatDate(reward['earnedAt']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab() {
    final allBadges = [
      {
        'name': 'Getting Started',
        'icon': '🌟',
        'description': 'Earned 100 points',
        'unlocked': _hasBadge('Getting Started'),
      },
      {
        'name': 'Active User',
        'icon': '🔥',
        'description': 'Earned 500 points',
        'unlocked': _hasBadge('Active User'),
      },
      {
        'name': 'Power User',
        'icon': '⚡',
        'description': 'Earned 1000 points',
        'unlocked': _hasBadge('Power User'),
      },
      {
        'name': 'VIP Member',
        'icon': '👑',
        'description': 'Earned 5000 points',
        'unlocked': _hasBadge('VIP Member'),
      },
      {
        'name': 'First Bidder',
        'icon': '🎯',
        'description': 'Placed your first bid',
        'unlocked': _hasBadge('First Bidder'),
      },
      {
        'name': 'Property Explorer',
        'icon': '🔍',
        'description': 'Viewed 10+ properties',
        'unlocked': _hasBadge('Property Explorer'),
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final unlocked = badge['unlocked'] as bool;

        return Card(
          elevation: unlocked ? 4 : 1,
          child: Container(
            decoration: unlocked
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge['icon'] as String,
                  style: TextStyle(
                    fontSize: 48,
                    color: unlocked ? Colors.white : Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.white : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    badge['description'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: unlocked ? Colors.white70 : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 20),
          const Text(
            'Leaderboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Coming Soon!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Text(
            'Compete with other users\nfor the top spot',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  bool _hasBadge(String badgeName) {
    return badges.any((badge) => badge['badgeName'] == badgeName);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays > 7) {
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }
}
