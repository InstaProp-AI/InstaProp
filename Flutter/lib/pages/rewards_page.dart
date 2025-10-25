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
        totalPoints = appState.user?.totalEarnedPoints ?? 0;
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
                // Current Points (Spendable)
                Text(
                  '${appState.user?.currentPoints ?? 0}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Current Points (Spendable)',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                // Total Earned Points (Lifetime)
                Text(
                  '${appState.user?.totalEarnedPoints ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const Text(
                  'Total Earned (Lifetime)',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
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
                          value: _getProgressToNextBadge(
                            appState.user?.totalEarnedPoints ?? 0,
                          ),
                          minHeight: 12,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Next milestone: ${_getNextMilestone(appState.user?.totalEarnedPoints ?? 0)} pts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress: ${(_getProgressToNextBadge(appState.user?.totalEarnedPoints ?? 0) * 100).toStringAsFixed(1)}% to next milestone',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
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
                Tab(text: 'My Codes'),
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
                _buildRedemptionHistoryTab(),
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

  Widget _buildRedemptionHistoryTab() {
    return FutureBuilder(
      future: RewardService.getRedemptionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.redeem, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 20),
                Text(
                  'No redemptions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Redeem your first reward to see it here!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final redemptions = snapshot.data!.data!;
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final redemption = redemptions[index];
            return Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                  child: const Icon(Icons.redeem, color: Color(0xFF667eea)),
                ),
                title: Text(redemption['rewardType'] ?? 'Unknown'),
                subtitle: Text('Code: ${redemption['promoCode'] ?? ''}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${redemption['pointsSpent'] ?? 0} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    Text(
                      _formatDate(redemption['redeemedAt']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    final appState = Provider.of<AppState>(context, listen: false);
    final canRedeem = (appState.user?.currentPoints ?? 0) >= points;

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

  void _showRedeemDialog(String item, int points) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text(
          'Are you sure you want to redeem $points points for $item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await RewardService.redeemReward(
          rewardType: item,
          points: points,
        );

        if (response.success && response.data != null) {
          _showPromoCodeDialog(response.data!['promoCode']);
          _loadRewardsData(); // Refresh points
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Redemption failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPromoCodeDialog(String promoCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Promo Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Save this code:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Text(
                promoCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('This code has been saved to your history'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
    // Show progress as percentage of total earned points relative to next milestone
    final nextTarget = _getNextMilestone(points);
    return (points / nextTarget).clamp(0.0, 1.0);
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
