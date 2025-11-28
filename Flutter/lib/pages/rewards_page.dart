import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/reward_service.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';

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
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: AppColors.textTertiary),
              const SizedBox(height: 20),
              Text(
                'Login to view rewards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Rewards',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Points Display Header
          ModernCard(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              children: [
                const Icon(Icons.stars, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                // Current Points (Spendable)
                Text(
                  '${appState.user?.currentPoints ?? 0}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  'Current Points (Spendable)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 8),
                // Total Earned Points (Lifetime)
                Text(
                  '${appState.user?.totalEarnedPoints ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  'Total Earned (Lifetime)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                    fontFamily: 'SF Pro Text',
                  ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress: ${(_getProgressToNextBadge(appState.user?.totalEarnedPoints ?? 0) * 100).toStringAsFixed(1)}% to next milestone',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          fontFamily: 'SF Pro Text',
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
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
              ),
              unselectedLabelStyle: const TextStyle(fontFamily: 'SF Pro Text'),
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
                Icon(Icons.redeem, size: 80, color: AppColors.textTertiary),
                const SizedBox(height: 20),
                Text(
                  'No redemptions yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Redeem your first reward to see it here!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          );
        }

        final redemptions = snapshot.data!.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final redemption = redemptions[index];
            return ModernCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.redeem, color: AppColors.primary),
                ),
                title: Text(
                  redemption['rewardType'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                subtitle: Text(
                  'Code: ${redemption['promoCode'] ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${redemption['pointsSpent'] ?? 0} pts',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      _formatDate(redemption['redeemedAt']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'SF Pro Text',
                      ),
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
            Icon(Icons.history, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start exploring properties to earn points!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
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
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                '+${reward['points']}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            title: Text(
              reward['rewardType'] ?? 'Unknown',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            subtitle: Text(
              reward['description'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            trailing: Text(
              _formatDate(reward['earnedAt']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
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

        return ModernCard(
          color: unlocked ? AppColors.primary : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge['icon'] as String,
                style: TextStyle(
                  fontSize: 48,
                  color: unlocked ? Colors.white : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge['name'] as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unlocked ? Colors.white : AppColors.textPrimary,
                  fontFamily: 'SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  badge['description'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: unlocked ? Colors.white70 : AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
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
          ModernCard(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            child: Column(
              children: [
                const Icon(Icons.redeem, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Redeem Your Points',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have $totalPoints points',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Vouchers Section
          Text(
            'Gift Vouchers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Display',
            ),
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

    return ModernCard(
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
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'SF Pro Text',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.stars, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$points points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ModernButton(
          text: 'Redeem',
          type: ModernButtonType.primary,
          onPressed: canRedeem
              ? () {
                  _showRedeemDialog(title, points);
                }
              : null,
          width: null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
