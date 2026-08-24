import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/property_financials_service.dart';
import '../services/analytics_service.dart';
import '../models/user.dart';
import 'valuate_page.dart';
import 'my_properties_page.dart';
import 'portfolio_analytics_page.dart';
import 'auction_activity_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart' show SettingsPage;
import 'help_page.dart';
import 'rewards_page.dart';
import '../core/router/app_router.dart';

class PropertiesManagementPage extends StatefulWidget {
  const PropertiesManagementPage({super.key});

  @override
  State<PropertiesManagementPage> createState() =>
      _PropertiesManagementPageState();
}

class _PropertiesManagementPageState extends State<PropertiesManagementPage> {
  bool _loadingFinancials = true;
  PortfolioSummary? _portfolioSummary;
  List<PropertyFinancials> _propertiesFinancials = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppState>().isLoggedIn) {
        context.read<AppState>().loadProperties();
        _loadPortfolioFinancials();
      }
    });
  }

  Future<void> _loadPortfolioFinancials() async {
    // Add safety check to prevent assertion errors
    if (!mounted) return;

    setState(() {
      _loadingFinancials = true;
    });

    try {
      final appState = context.read<AppState>();
      final userId = appState.user?.accountId;

      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _portfolioSummary = PortfolioSummary(
            totalNetValue: 0,
            totalAssets: 0,
            totalOwed: 0,
            totalEquity: 0,
            averageROI: 0,
            propertiesCount: 0,
          );
          _propertiesFinancials = [];
          _loadingFinancials = false;
        });
        return;
      }

      // Use the analytics API instead of local calculations
      final portfolioData = await AnalyticsService.getPortfolioAnalytics(
        userId,
      );

      if (portfolioData == null) {
        if (!mounted) return;
        setState(() {
          _portfolioSummary = PortfolioSummary(
            totalNetValue: 0,
            totalAssets: 0,
            totalOwed: 0,
            totalEquity: 0,
            averageROI: 0,
            propertiesCount: 0,
          );
          _propertiesFinancials = [];
          _loadingFinancials = false;
        });
        return;
      }

      // Convert API response to local format
      final summary = PortfolioSummary(
        totalNetValue: portfolioData.totalCurrentValue,
        totalAssets: portfolioData.totalCurrentValue,
        totalOwed: 0, // API doesn't provide debt info
        totalEquity: portfolioData.totalCurrentValue,
        averageROI: portfolioData.averageROIPercentage,
        propertiesCount: portfolioData.totalProperties.toDouble(),
      );

      // Convert property breakdown to PropertyFinancials format
      final financials = portfolioData.propertyBreakdown.map((property) {
        return PropertyFinancials(
          propertyId: property.propertyId,
          sumInstallments: 0, // API doesn't provide installment info
          paidSoFar: 0, // API doesn't provide payment info
          remainingInstallments: 0, // API doesn't provide installment info
          remainingToPay: 0, // API doesn't provide debt info
          buyingPrice: property.investedAmount,
          marketValue: property.currentValue,
          roiPercent: property.roi,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _propertiesFinancials = financials;
        _portfolioSummary = summary;
        _loadingFinancials = false;
      });
    } catch (e) {
      print('Error loading portfolio financials: $e');
      if (!mounted) return;
      setState(() {
        _loadingFinancials = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return _buildLoggedInContent(context, appState);
        },
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppState appState) {
    return CustomScrollView(
      slivers: [
        // Minimal Clean Header
        SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: _buildHeaderActions(context, appState),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Portfolio',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your property investments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: const Text(
              'Portfolio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              if (appState.isLoggedIn && appState.user != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProfileOverview(appState),
                ),
                const SizedBox(height: 24),
              ],

              // Financial Dashboard
              if (appState.isFeatureEnabled('PortfolioAnalytics') &&
                  appState.isLoggedIn &&
                  !_loadingFinancials &&
                  _portfolioSummary != null)
                _buildFinancialDashboard()
              else if (!appState.isLoggedIn)
                _buildNotLoggedInFinancialDashboard(),

              const SizedBox(height: 32),

              // Quick Actions - Compact Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Row 1: Auction Activity + Add Property
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactActionButton(
                            context,
                            icon: Icons.gavel_rounded,
                            title: 'My Auctions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AuctionActivityPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactActionButton(
                            context,
                            icon: Icons.add_home_work,
                            title: 'Add Property',
                            onTap: () {
                          AppRouter.navigateTo(
                            context,
                            AppRouter.addProperty,
                          );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Calendar + Valuate Property (feature-flagged)
                    if (appState.isFeatureEnabled('CalendarEvents') ||
                        appState.isFeatureEnabled('Valuation'))
                      Row(
                        children: [
                          if (appState.isFeatureEnabled('CalendarEvents'))
                            Expanded(
                              child: _buildCompactActionButton(
                                context,
                                icon: Icons.calendar_today_rounded,
                                title: 'My Calendar',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CalendarPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (appState.isFeatureEnabled('CalendarEvents') &&
                              appState.isFeatureEnabled('Valuation'))
                            const SizedBox(width: 12),
                          if (appState.isFeatureEnabled('Valuation'))
                            Expanded(
                              child: _buildCompactActionButton(
                                context,
                                icon: Icons.assessment,
                                title: 'Valuate Property',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ValuatePage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Friendly message for non-logged-in users
              if (!appState.isLoggedIn) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These features are available without signing up!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // My Properties Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Properties',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.7,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyPropertiesPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Properties List
                    if (!appState.isLoggedIn)
                      _buildNotLoggedInPropertiesState(context)
                    else if (appState.loadingProperties)
                      const Center(child: CircularProgressIndicator())
                    else if (appState.userProperties.isEmpty)
                      _buildEmptyPropertiesState(context)
                    else
                      _buildPropertiesList(context, appState),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeaderActions(BuildContext context, AppState appState) {
    return [
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        color: const Color(0xFF1A1A1A),
        tooltip: 'Settings',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.help_outline),
        color: const Color(0xFF1A1A1A),
        tooltip: 'Help',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpPage()),
          );
        },
      ),
      if (appState.isFeatureEnabled('Redemptions'))
        IconButton(
          icon: const Icon(Icons.card_giftcard_outlined),
          color: const Color(0xFF1A1A1A),
          tooltip: 'Rewards',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardsPage()),
            );
          },
        ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildProfileOverview(AppState appState) {
    final user = appState.user!;
    final rawName = user.fullName.trim();
    final displayName = rawName.isNotEmpty ? rawName : 'Guest User';
    final email = user.email.trim().isNotEmpty ? user.email : 'No email on file';
    final initialSource = user.firstName.trim().isNotEmpty
        ? user.firstName
        : (email.isNotEmpty ? email : 'U');
    final initials = initialSource.trim().isNotEmpty
        ? initialSource.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[200],
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip(
                icon: _statusIcon(user.status),
                label: _statusText(user.status),
                background: _statusBackground(user.status),
                foreground: _statusForeground(user.status),
              ),
              _buildInfoChip(
                icon: Icons.stars,
                label: '${user.currentPoints ?? 0} pts',
                background: Colors.amber.withOpacity(0.15),
                foreground: Colors.amber.shade800,
              ),
              if (user.totalEarnedPoints != null)
                _buildInfoChip(
                  icon: Icons.emoji_events_outlined,
                  label: 'Lifetime ${user.totalEarnedPoints}',
                  background: Colors.indigo.withOpacity(0.12),
                  foreground: Colors.indigo.shade600,
                ),
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: 'Member since ${_formatMemberSince(user.createdAt)}',
                background: Colors.grey[100]!,
                foreground: const Color(0xFF1A1A1A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusBackground(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green.withOpacity(0.12);
      case VerificationStatus.pending:
        return Colors.blue.withOpacity(0.12);
      case VerificationStatus.notVerified:
        return Colors.orange.withOpacity(0.12);
    }
  }

  Color _statusForeground(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.blue;
      case VerificationStatus.notVerified:
        return Colors.orange;
    }
  }

  IconData _statusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.notVerified:
        return Icons.warning_amber_rounded;
    }
  }

  String _statusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.notVerified:
        return 'Not Verified';
    }
  }

  String _formatMemberSince(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFinancialDashboard() {
    final summary = _portfolioSummary!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          const Text(
            'Portfolio Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 20),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildMinimalMetricCard(
                'Net Value',
                '\$${_formatNumber(summary.totalNetValue)}',
                AppColors.primary,
              ),
              _buildMinimalMetricCard(
                'Total Assets',
                '\$${_formatNumber(summary.totalAssets)}',
                AppColors.secondary,
              ),
              _buildMinimalMetricCard(
                'Total Owed',
                '\$${_formatNumber(summary.totalOwed)}',
                Colors.orange,
              ),
              _buildMinimalMetricCard(
                'Avg ROI',
                '${summary.averageROI.toStringAsFixed(1)}%',
                summary.averageROI >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Analytics Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PortfolioAnalyticsPage(
                      summary: summary,
                      propertiesFinancials: _propertiesFinancials,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Detailed Analytics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  // removed saved searches section

  Widget _buildEmptyPropertiesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No Properties Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first property to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                AppRouter.navigateTo(
                  context,
                  AppRouter.addProperty,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text('Add Property'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(BuildContext context, AppState appState) {
    return Column(
      children: appState.userProperties.take(3).map((property) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyPropertiesPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    property.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.home,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        property.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: property.isApproved
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.isApproved ? 'Verified' : 'Pending',
                    style: TextStyle(
                      color: property.isApproved
                          ? AppColors.success
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotLoggedInFinancialDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          const Text(
            'Portfolio Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 20),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildMinimalMetricCard('Net Value', '\$0', Colors.grey),
              _buildMinimalMetricCard('Total Assets', '\$0', Colors.grey),
              _buildMinimalMetricCard('Total Owed', '\$0', Colors.grey),
              _buildMinimalMetricCard('Avg ROI', '0%', Colors.grey),
            ],
          ),

          const SizedBox(height: 24),

          // Login Prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.login, size: 32, color: Colors.blue[600]),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to view your portfolio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your investments, view analytics, and manage your properties',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.auth);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInPropertiesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.home_work, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Your Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to view and manage your properties',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.auth);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
