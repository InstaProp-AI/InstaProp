import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/reward_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
      await appState.refreshUserProfile();
      final rewardsResp = await RewardService.getMyRewards();
      final badgesResp = await RewardService.getMyBadges();

      setState(() {
        totalPoints = appState.user?.totalPoints ?? 0;
        recentRewards = rewardsResp.data ?? [];
        badges = badgesResp.data ?? [];
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
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Points Display Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, size: 50, color: Colors.white),
                const SizedBox(height: 8),
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
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // Progress bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _getProgressToNextBadge(totalPoints),
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Next milestone: ${_getNextMilestone(totalPoints)} pts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF667eea),
              labelColor: const Color(0xFF667eea),
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [
                Tab(text: 'How It Works'),
                Tab(text: 'Activity'),
                Tab(text: 'Badges'),
                Tab(text: 'Redeem'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHowItWorksTab(),
                _buildActivityTab(),
                _buildBadgesTab(),
                _buildRedeemTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration Header
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Color(0xFF667eea),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Earn & Redeem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // How to Earn Points Section
          const Text(
            'How to Earn Points',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEarnCard(
            icon: Icons.gavel,
            title: 'Place a Bid',
            points: 100,
            description: 'Participate in auctions by placing bids',
            color: Colors.orange,
          ),
          _buildEarnCard(
            icon: Icons.home_work,
            title: 'Add a Property',
            points: 200,
            description: 'List your properties on the platform',
            color: Colors.blue,
          ),
          _buildEarnCard(
            icon: Icons.assessment,
            title: 'Valuate a Property',
            points: 150,
            description: 'Get instant AI-powered property valuations',
            color: Colors.green,
          ),
          _buildEarnCard(
            icon: Icons.calendar_today,
            title: 'Create an Event',
            points: 20,
            description: 'Manage your calendar with reminders',
            color: Colors.purple,
          ),
          _buildEarnCard(
            icon: Icons.schedule,
            title: 'Import Payment Schedule',
            points: 250,
            description: 'Upload and track payment schedules',
            color: Colors.teal,
          ),

          const SizedBox(height: 24),

          // Badge Progression
          const Text(
            'Badge Progression',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBadgeProgressionCard('🌟', 'Getting Started', 500),
          _buildBadgeProgressionCard('🔥', 'Active User', 1000),
          _buildBadgeProgressionCard('⚡', 'Power User', 2500),
          _buildBadgeProgressionCard('👑', 'VIP Member', 5000),
          _buildBadgeProgressionCard('💎', 'Elite', 10000),
        ],
      ),
    );
  }

  Widget _buildEarnCard({
    required IconData icon,
    required String title,
    required int points,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '+$points pts',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeProgressionCard(String emoji, String name, int points) {
    final unlocked = totalPoints >= points;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: unlocked ? const Color(0xFF667eea).withOpacity(0.1) : null,
      child: ListTile(
        leading: Text(
          emoji,
          style: TextStyle(
            fontSize: 32,
            color: unlocked ? null : Colors.grey[300],
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? const Color(0xFF667eea) : Colors.grey[600],
          ),
        ),
        subtitle: Text('Requires $points points'),
        trailing: unlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.lock_outline, color: Colors.grey[400]),
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
        'description': 'Earned 500 points',
        'unlocked': _hasBadge('Getting Started'),
      },
      {
        'name': 'Active User',
        'icon': '🔥',
        'description': 'Earned 1000 points',
        'unlocked': _hasBadge('Active User'),
      },
      {
        'name': 'Power User',
        'icon': '⚡',
        'description': 'Earned 2500 points',
        'unlocked': _hasBadge('Power User'),
      },
      {
        'name': 'VIP Member',
        'icon': '👑',
        'description': 'Earned 5000 points',
        'unlocked': _hasBadge('VIP Member'),
      },
      {
        'name': 'Elite',
        'icon': '💎',
        'description': 'Earned 10000 points',
        'unlocked': _hasBadge('Elite'),
      },
      {
        'name': 'First Bidder',
        'icon': '🎯',
        'description': 'Placed your first bid',
        'unlocked': _hasBadge('First Bidder'),
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

  Widget _buildRedeemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.redeem, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Redeem Your Points',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have $totalPoints points',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cashback Section
          const Text(
            'Cashback Rewards',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRedeemCard(
            icon: Icons.attach_money,
            title: '\$5 Cashback',
            description: 'Get \$5 credited to your wallet',
            points: 500,
            color: Colors.green,
          ),
          _buildRedeemCard(
            icon: Icons.attach_money,
            title: '\$10 Cashback',
            description: 'Get \$10 credited to your wallet',
            points: 1000,
            color: Colors.green,
          ),
          _buildRedeemCard(
            icon: Icons.attach_money,
            title: '\$25 Cashback',
            description: 'Get \$25 credited to your wallet',
            points: 2500,
            color: Colors.green,
          ),
          _buildRedeemCard(
            icon: Icons.attach_money,
            title: '\$50 Cashback',
            description: 'Get \$50 credited to your wallet',
            points: 5000,
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          // Vouchers Section
          const Text(
            'Gift Vouchers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRedeemCard(
            icon: Icons.shopping_bag,
            title: 'Amazon \$10 Voucher',
            description: 'Shop on Amazon with this voucher',
            points: 1000,
            color: Colors.orange,
          ),
          _buildRedeemCard(
            icon: Icons.card_giftcard,
            title: 'Starbucks \$10 Voucher',
            description: 'Enjoy your favorite coffee',
            points: 1000,
            color: Colors.brown,
          ),
          _buildRedeemCard(
            icon: Icons.local_gas_station,
            title: 'Gas Station \$15 Voucher',
            description: 'Save on fuel costs',
            points: 1500,
            color: Colors.blue,
          ),
          _buildRedeemCard(
            icon: Icons.restaurant,
            title: 'Restaurant \$15 Voucher',
            description: 'Dine at partner restaurants',
            points: 1500,
            color: Colors.red,
          ),

          const SizedBox(height: 24),

          // Premium Features Section
          const Text(
            'Premium Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRedeemCard(
            icon: Icons.trending_up,
            title: 'Advanced Analytics (1 month)',
            description: 'Get detailed property insights',
            points: 800,
            color: Colors.purple,
          ),
          _buildRedeemCard(
            icon: Icons.priority_high,
            title: 'Priority Support (1 month)',
            description: '24/7 dedicated customer support',
            points: 600,
            color: Colors.indigo,
          ),
          _buildRedeemCard(
            icon: Icons.verified,
            title: 'Verified Seller Badge',
            description: 'Stand out with a verified badge',
            points: 1000,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCard({
    required IconData icon,
    required String title,
    required String description,
    required int points,
    required Color color,
  }) {
    final canRedeem = totalPoints >= points;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.stars, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$points points',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: canRedeem
              ? () {
                  _showRedeemDialog(title, points);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canRedeem ? color : Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Redeem'),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showRedeemDialog(String item, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text(
          'Are you sure you want to redeem $points points for $item?\n\nThis feature is coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redemption feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  bool _hasBadge(String badgeName) {
    return badges.any((badge) => badge['badgeName'] == badgeName);
  }

  int _getNextMilestone(int points) {
    if (points < 500) return 500;
    if (points < 1000) return 1000;
    if (points < 2500) return 2500;
    if (points < 5000) return 5000;
    if (points < 10000) return 10000;
    return 20000;
  }

  double _getProgressToNextBadge(int points) {
    final nextTarget = _getNextMilestone(points);
    final start = points < 500
        ? 0
        : points < 1000
        ? 500
        : points < 2500
        ? 1000
        : points < 5000
        ? 2500
        : points < 10000
        ? 5000
        : 10000;
    return ((points - start) / (nextTarget - start)).clamp(0.0, 1.0);
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
