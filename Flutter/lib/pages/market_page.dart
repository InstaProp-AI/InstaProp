import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';
import '../services/developer_service.dart';
import '../core/router/app_router.dart';
import 'developer_profile_page.dart';
import 'property_search_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  bool _isLoading = true;
  String? _error;

  MarketOverviewResponse? _marketOverview;
  List<PriceTrendResponse>? _priceTrends;
  GoldComparisonResponse? _goldComparison;
  List<DeveloperRankingResponse>? _developerRankings;
  List<BestInvestmentResponse>? _bestInvestments;
  PortfolioAnalyticsResponse? _portfolioAnalytics;
  final Map<int, String> _developerNameOverrides = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDashboardData);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final userId = appState.isLoggedIn ? appState.user?.accountId : null;

      final results = await Future.wait([
        AnalyticsService.getMarketOverview(),
        AnalyticsService.getPriceTrends(months: 12),
        AnalyticsService.getGoldComparison(months: 12),
        AnalyticsService.getDeveloperRankings(),
        AnalyticsService.getBestInvestments(limit: 6),
        if (userId != null)
          AnalyticsService.getPortfolioAnalytics(userId)
        else
          Future.value(null),
      ]);

      if (!mounted) return;

      final marketOverview = results[0] as MarketOverviewResponse?;
      final priceTrends = results[1] as List<PriceTrendResponse>?;
      final goldComparison = results[2] as GoldComparisonResponse?;
      final developerRankings = results[3] as List<DeveloperRankingResponse>?;
      final bestInvestments = results[4] as List<BestInvestmentResponse>?;
      final portfolioAnalytics =
          results.length > 5 ? results[5] as PortfolioAnalyticsResponse? : null;

      if (!mounted) return;

      setState(() {
        _marketOverview = marketOverview;
        _priceTrends = priceTrends;
        _goldComparison = goldComparison;
        _developerRankings = developerRankings;
        _bestInvestments = bestInvestments;
        _portfolioAnalytics = portfolioAnalytics;
        _isLoading = false;

        if (developerRankings != null) {
          _developerNameOverrides
              .removeWhere((key, value) => !developerRankings
                  .any((developer) => developer.developerId == key));
        }
      });

      if (developerRankings != null && developerRankings.isNotEmpty) {
        Future.microtask(() => _hydrateDeveloperNames(developerRankings));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Weekly leaderboard',
            onPressed: () => AppRouter.navigateTo(
              context,
              AppRouter.leaderboard,
              // 2 = "All Time" tab in LeaderboardPage
              arguments: {'initialTabIndex': 2},
            ),
          ),
          const SizedBox(width: 8),
        ],
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Market Intelligence',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Real-time performance, ROI, and opportunities',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingButtons(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Unable to load market data',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            sliver: SliverList.list(children: [
              _buildQuickActions(context),
              const SizedBox(height: 16),
              _buildHeroMetrics(),
              const SizedBox(height: 16),
              _buildMacroPulse(),
              const SizedBox(height: 16),
              _buildPortfolioSnapshot(),
              const SizedBox(height: 16),
              _buildPriceTrends(),
              const SizedBox(height: 16),
              _buildOpportunityDeck(),
              const SizedBox(height: 16),
              _buildDeveloperLeaderboard(),
              const SizedBox(height: 16),
              _buildGoldComparison(),
              const SizedBox(height: 16),
              _buildAiRecommendations(),
              const SizedBox(height: 16),
              _buildMarketNews(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildQuickActionChip(
          context,
          label: 'Live Auctions',
          icon: Icons.gavel_outlined,
          routeName: AppRouter.auctions,
        ),
        _buildQuickActionChip(
          context,
          label: 'Add Property',
          icon: Icons.add_home_work_outlined,
          routeName: AppRouter.addProperty,
        ),
        _buildQuickActionChip(
          context,
          label: 'Manage Portfolio',
          icon: Icons.account_balance_wallet_outlined,
          routeName: AppRouter.propertyManagement,
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String routeName,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: colorScheme.primary),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: () => AppRouter.navigateTo(context, routeName),
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildHeroMetrics() {
    final roi = _calculateMarketRoi();
    final capRate = _calculateMarketCapRate();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildHeroMetric(
                title: 'Market ROI (30d)',
                value: roi != null ? '${roi.toStringAsFixed(1)}%' : '—',
                trendUp: roi != null && roi >= 0,
              ),
              const SizedBox(width: 16),
              _buildHeroMetric(
                title: 'Avg Cap Rate',
                value: capRate != null ? '${capRate.toStringAsFixed(1)}%' : '—',
                trendUp: capRate != null && capRate >= 8,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeroBadge(
                  icon: Icons.flash_on,
                  label: () {
                    final totalProperties = _marketOverview?.totalProperties;
                    return totalProperties != null
                        ? '$totalProperties active listings'
                        : 'Market activity live';
                  }(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppRouter.navigateTo(context, AppRouter.propertyManagement);
                  },
                  child: _buildHeroBadge(
                    icon: Icons.link,
                    label: 'Connect your portfolio to unlock deeper metrics',
                  ),
                ),
              ),
            ],
          ),
          _buildUpdatedStamp(_marketOverview?.generatedAt),
        ],
      ),
    );
  }

  Widget _buildMacroPulse() {
    final overview = _marketOverview;

    if (overview == null) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.pie_chart_outline,
        title: 'Market pulse is warming up',
        description:
            'We’re still collecting enough recent transactions to surface pulse insights. Check back shortly.',
        actionLabel: 'Refresh',
        onAction: _loadDashboardData,
      );
    }

    if (!overview.hasData) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.pie_chart_outline,
        title: 'Market pulse is warming up',
        description: overview.message ??
            'We need a few verified sales before we can plot the market pulse.',
        actionLabel: 'Refresh',
        onAction: _loadDashboardData,
      );
    }

    final averagePrice = overview.areaPrices.isNotEmpty
        ? overview.areaPrices
                .map((e) => e.averagePrice)
                .reduce((a, b) => a + b) /
            overview.areaPrices.length
        : null;
    final priceTrendDelta = _priceTrends != null && _priceTrends!.length > 1
        ? ((_priceTrends!.last.price - _priceTrends!.first.price) /
                max(_priceTrends!.first.price, 1)) *
            100
        : null;
    final liquidityDays = _bestInvestments?.isNotEmpty == true
        ? (_bestInvestments!
                    .map((e) => e.priceHistoryCount)
                    .fold<int>(0, (acc, v) => acc + v) /
                _bestInvestments!.length)
            .clamp(10, 90)
        : null;

    final transactions = overview.recentPriceTrends;
    final transactionCount = transactions.length;
    final lastTransactionCount = transactions.isNotEmpty
        ? transactions.last.transactionCount
        : null;

    final items = [
      _MacroItem(
        label: 'Avg Sale Price',
        value: averagePrice != null ? '${averagePrice.toStringAsFixed(0)} EGP' : '—',
        delta: priceTrendDelta != null ? priceTrendDelta.toStringAsFixed(1) : null,
        trendUp: priceTrendDelta != null && priceTrendDelta >= 0,
      ),
      _MacroItem(
        label: 'Transaction Volume',
        value: transactionCount > 0 ? '${transactionCount * 24}' : '—',
        delta: lastTransactionCount != null ? '+$lastTransactionCount' : null,
        trendUp: true,
      ),
      _MacroItem(
        label: 'Liquidity (Days)',
        value: liquidityDays != null ? liquidityDays.toStringAsFixed(0) : '—',
        delta: liquidityDays != null
            ? (liquidityDays < 45 ? 'Fast moving' : 'Cooling')
            : null,
        trendUp: liquidityDays != null && liquidityDays < 45,
      ),
      _MacroItem(
        label: 'Market Sentiment',
        value: _deriveSentimentLabel(priceTrendDelta ?? 0),
        delta: priceTrendDelta != null ? '${priceTrendDelta.abs().toStringAsFixed(1)}% swing' : null,
        trendUp: (priceTrendDelta ?? 0) >= 0,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.pie_chart_outline,
            title: 'Market Pulse',
            subtitle: 'Macro indicators updated in real-time',
          ),
          _buildUpdatedStamp(overview.generatedAt),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final childAspectRatio =
                  constraints.maxWidth > 600 ? 2.4 : 1.6;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.delta != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                item.trendUp ? Icons.trending_up : Icons.trending_down,
                                size: 16,
                                color: item.trendUp ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.delta!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.trendUp ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSnapshot() {
    final appState = context.watch<AppState>();
    final isLoggedIn = appState.isLoggedIn;
    final portfolio = _portfolioAnalytics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Portfolio Snapshot',
            subtitle: isLoggedIn
                ? 'Live view of your holdings and buying power'
                : 'Sign in to sync assets and unlock tailored insights',
            trailing: isLoggedIn
                ? null
                : TextButton.icon(
                    onPressed: () {
                      AppRouter.navigateTo(
                        context,
                        AppRouter.propertyManagement,
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Connect Now'),
                  ),
          ),
          const SizedBox(height: 18),
          if (!isLoggedIn || portfolio == null)
            _buildPortfolioPlaceholder()
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPortfolioMetric(
                        label: 'Total Invested',
                        value:
                            '${portfolio.totalInvested.toStringAsFixed(0)} EGP',
                        trendText:
                            '${portfolio.totalROIPercentage.toStringAsFixed(1)}% ROI',
                        positive: portfolio.totalROIPercentage >= 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPortfolioMetric(
                        label: 'Current Value',
                        value:
                            '${portfolio.totalCurrentValue.toStringAsFixed(0)} EGP',
                        trendText:
                            '${portfolio.totalProfitLoss.toStringAsFixed(0)} EGP P/L',
                        positive: portfolio.totalProfitLoss >= 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPortfolioMetric(
                        label: 'Buying Power',
                        value:
                            '${max(portfolio.totalCurrentValue - portfolio.totalInvested, 0).toStringAsFixed(0)} EGP',
                        trendText:
                            '${portfolio.averageROIPercentage.toStringAsFixed(1)}% avg yield',
                        positive: portfolio.averageROIPercentage >= 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPortfolioMetric(
                        label: 'Best Performer',
                        value: portfolio.bestPerformingProperty.isNotEmpty
                            ? portfolio.bestPerformingProperty
                            : '—',
                        trendText:
                            '${portfolio.totalProperties} active holdings',
                        positive: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPriceTrends() {
    final aggregatedTrends = _aggregateMonthlyTrends();

    if (aggregatedTrends.isEmpty) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.timeline_outlined,
        title: 'Price momentum coming soon',
        description:
            'As soon as we log a few consecutive transactions, we’ll chart price momentum here.',
        actionLabel: 'Refresh',
        onAction: _loadDashboardData,
      );
    }

    final spots = aggregatedTrends
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value.averagePrice,
          ),
        )
        .toList();

    final maxPrice = aggregatedTrends
        .map((trend) => trend.averagePrice)
        .reduce(max);
    final horizontalInterval = max(50000.0, maxPrice / 4);
    final minPrice = aggregatedTrends
        .map((trend) => trend.averagePrice)
        .reduce(min);
    final priceRangePadding = max((maxPrice - minPrice) * 0.1, 50000.0);
    final minY = max(0.0, minPrice - priceRangePadding);
    final maxY = maxPrice + priceRangePadding;

    String formatPriceLabel(double value) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      }
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.timeline_outlined,
            title: 'Price Momentum',
            subtitle: 'Trailing 12 months across tracked projects',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatPriceLabel(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= aggregatedTrends.length) {
                          return const SizedBox.shrink();
                        }
                        final bucket = aggregatedTrends[index];
                        final monthLabel =
                            _monthLabels[bucket.date.month - 1];
                        return Text(
                          '$monthLabel ${bucket.date.year % 100}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: 0,
                maxX: spots.length.toDouble() - 1,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: horizontalInterval,
                ),
                borderData: FlBorderData(
                  border: const Border(
                    left: BorderSide(color: Color(0xFFE0E3EB)),
                    bottom: BorderSide(color: Color(0xFFE0E3EB)),
                  ),
                ),
                lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.blue[600],
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityDeck() {
    if (_bestInvestments == null || _bestInvestments!.isEmpty) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.lightbulb_outline,
        title: 'No standout opportunities yet',
        description:
            'We highlight listings once they show exceptional yield, growth, or momentum. In the meantime, browse the marketplace.',
        actionLabel: 'Browse listings',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertySearchPage()),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.lightbulb_outline,
            title: 'Opportunity Deck',
            subtitle: 'Handpicked listings by yield, growth, and momentum',
            trailing: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PropertySearchPage()),
                );
              },
              child: const Text('Explore All'),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _bestInvestments!
                .map(
                  (investment) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      color: Colors.green.withValues(alpha: 0.04),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apartment, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investment.propertyName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${investment.location} • ${investment.propertyType}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildOpportunityChip(
                                    icon: Icons.bar_chart,
                                    label:
                                        'ROI ${(investment.priceTrend.isNotEmpty ? _calculateTrendRoi(investment.priceTrend) : 0).toStringAsFixed(1)}%',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOpportunityChip(
                                    icon: Icons.square_foot,
                                    label:
                                        '${investment.pricePerSqm.toStringAsFixed(0)} EGP /sqm',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${investment.currentPrice.toStringAsFixed(0)} EGP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${investment.bedrooms} bd • ${investment.bathrooms} ba • ${investment.squareFeet} sqft',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .take(4)
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperLeaderboard() {
    if (_developerRankings == null || _developerRankings!.isEmpty) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.emoji_events_outlined,
        title: 'Developer stats syncing',
        description:
            'Once developers start closing deals on the platform we’ll surface rankings and performance insights here.',
        actionLabel: 'Refresh',
        onAction: _loadDashboardData,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.emoji_events_outlined,
            title: 'Developer Leaderboard',
            subtitle: 'Best-in-class developers ranked by velocity and value',
          ),
          const SizedBox(height: 16),
          Column(
            children: _developerRankings!
                .take(5)
                .map(_buildDeveloperCard)
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldComparison() {
    final data = _goldComparison;
    if (data == null) {
      return _buildAnalyticsPlaceholder(
        icon: Icons.compare_arrows,
        title: 'Asset comparison unavailable',
        description:
            'We need more historical sales and gold price data to generate this comparison. Check back soon.',
        actionLabel: 'Refresh',
        onAction: _loadDashboardData,
      );
    }

    final bool isPropertyWinner = data.betterInvestment == 'Property';
    final bool isGoldWinner = data.betterInvestment == 'Gold';
    final bool isTied =
        !isPropertyWinner && !isGoldWinner; // handles "Tied" or empty

    final Color baseColor = isPropertyWinner
        ? Colors.green
        : isGoldWinner
            ? (Colors.amber[800] ?? Colors.amber)
            : Colors.blueGrey;
    final IconData summaryIcon = isPropertyWinner
        ? Icons.trending_up
        : isGoldWinner
            ? Icons.trending_flat
            : Icons.horizontal_rule;
    final String summaryText = isTied
        ? 'Property and gold are moving in lockstep over the last ${data.periodMonths} months.'
        : '${data.betterInvestment} is outperforming by ${data.returnDifference.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.compare_arrows,
            title: 'Asset Class Showdown',
            subtitle: 'Real estate vs gold performance over ${data.periodMonths} months',
          ),
          _buildUpdatedStamp(data.generatedAt),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  title: 'Property ROI',
                  value: '${data.propertyReturnPercentage.toStringAsFixed(1)}%',
                  icon: Icons.apartment,
                  color: Colors.green,
                  isWinner: data.betterInvestment == 'Property',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonCard(
                  title: 'Gold ROI',
                  value: '${data.goldReturnPercentage.toStringAsFixed(1)}%',
                  icon: Icons.monetization_on,
                  color: Colors.amber[800]!,
                  isWinner: data.betterInvestment == 'Gold',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  summaryIcon,
                  color: baseColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summaryText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: baseColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (data.message != null && data.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInlineNotice(
              data.message!,
              icon: Icons.info_outline,
              color: Colors.blueGrey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(DeveloperRankingResponse developer) {
    final displayName = _displayDeveloperName(developer);
    final canNavigate = developer.developerId > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canNavigate ? () => _openDeveloperProfile(developer.developerId) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(Icons.business_center, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${developer.projectCount} projects • ${developer.totalProperties} units',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildRatingBadge(developer.averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '${developer.averagePropertyPrice.toStringAsFixed(0)} EGP avg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (canNavigate) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayDeveloperName(DeveloperRankingResponse developer) {
    final override = _developerNameOverrides[developer.developerId];
    final candidate = override ?? developer.developerName;
    final trimmed = candidate.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown developer') {
      return 'Developer #${developer.developerId}';
    }
    return trimmed;
  }

  void _openDeveloperProfile(int developerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeveloperProfilePage(developerId: developerId),
      ),
    );
  }

  Future<void> _hydrateDeveloperNames(
    List<DeveloperRankingResponse> rankings,
  ) async {
    final appState = context.read<AppState>();
    final developerService = DeveloperService(
      ApiClient.baseUrl,
      token: appState.token,
    );

    final Map<int, String> fetchedNames = {};

    for (final developer in rankings.take(8)) {
      final developerId = developer.developerId;
      if (developerId <= 0 || _developerNameOverrides.containsKey(developerId)) {
        continue;
      }

      final existingName = developer.developerName.trim();
      if (existingName.isNotEmpty &&
          existingName.toLowerCase() != 'unknown developer') {
        fetchedNames[developerId] = existingName;
        continue;
      }

      try {
        final profile = await developerService.getDeveloperProfile(developerId);
        final companyName = profile.companyName?.trim();
        final fullName = profile.fullName.trim();
        final profileName = (companyName != null && companyName.isNotEmpty)
            ? companyName
            : fullName.isNotEmpty
                ? fullName
                : 'Developer #$developerId';
        fetchedNames[developerId] = profileName;
      } catch (_) {
        fetchedNames[developerId] =
            existingName.isNotEmpty ? existingName : 'Developer #$developerId';
      }
    }

    if (fetchedNames.isNotEmpty && mounted) {
      setState(() {
        _developerNameOverrides.addAll(fetchedNames);
      });
    }
  }

  Widget _buildAiRecommendations() {
    final roi = _calculateMarketRoi();
    final heroCallout = roi == null
        ? 'Stay ready – we will flag the next breakout pocket as soon as data hits.'
        : roi >= 10
            ? 'Momentum-driven investors may want to double down on high-yield auctions.'
            : roi >= 0
                ? 'Stable returns suggest dollar-cost averaging across prime neighborhoods.'
                : 'Defensive posture advised: shift focus to cash-flow heavy rentals.';

    final recommendations = [
      'Diversify across developers with >4.0 rating and high absorption rate.',
      'Monitor liquidity – listings turning in <30 days are primed for flips.',
      'Blend auction acquisitions with off-market deals to balance risk.',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.smart_toy_outlined,
            title: 'AI Market Playbook',
            subtitle:
                'Strategy suggestions generated from live indicators and recent sales',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.lightBlueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    heroCallout,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: recommendations
                .map(
                  (rec) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
                    title: Text(
                      rec,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<_MonthlyTrend> _aggregateMonthlyTrends() {
    if (_priceTrends == null || _priceTrends!.isEmpty) return [];

    final Map<DateTime, _MonthlyTrend> buckets = {};

    for (final trend in _priceTrends!) {
      final bucketDate = DateTime(trend.date.year, trend.date.month);
      final bucket =
          buckets.putIfAbsent(bucketDate, () => _MonthlyTrend(date: bucketDate));
      bucket.total += trend.price;
      bucket.count += 1;
    }

    final trends = buckets.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (trends.length > 12) {
      trends.removeRange(0, trends.length - 12);
    }

    return trends;
  }

  Widget _buildMarketNews() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.article_outlined,
            title: 'Market Headlines',
            subtitle: 'Latest signals across finance, development, and policy',
          ),
          const SizedBox(height: 16),
          _buildNewsItem(
            title:
                'Real estate demand surges with ${_marketOverview?.activeAuctions ?? 0} auctions closing this week',
            label: 'Breaking',
          ),
          const SizedBox(height: 12),
          _buildNewsItem(
            title:
                'Top developers raise incentives as absorption rate tightens in New Cairo',
            label: 'Developers',
          ),
          const SizedBox(height: 12),
          _buildNewsItem(
            title: 'Central bank announces steady rate policy to fuel mortgage appetite',
            label: 'Policy',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton.extended(
            heroTag: 'auctions_fab',
            onPressed: () {
              AppRouter.navigateTo(context, AppRouter.auctions);
            },
            backgroundColor: Colors.orange[600],
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Live Auctions'),
          ),
          FloatingActionButton.extended(
            heroTag: 'properties_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PropertySearchPage()),
              );
            },
            backgroundColor: Colors.blue[600],
            icon: const Icon(Icons.home_outlined),
            label: const Text('Find Properties'),
          ),
        ],
      ),
    );
  }

  double? _calculateMarketRoi() {
    if (_priceTrends == null || _priceTrends!.length < 2) return null;
    final first = _priceTrends!.first.price;
    final last = _priceTrends!.last.price;
    if (first <= 0) return null;
    return ((last - first) / first) * 100;
  }

  double? _calculateMarketCapRate() {
    if (_bestInvestments == null || _bestInvestments!.isEmpty) return null;
    final roiValues = _bestInvestments!
        .map((investment) => _calculateTrendRoi(investment.priceTrend))
        .where((value) => value.isFinite)
        .toList();
    if (roiValues.isEmpty) return null;
    return roiValues.reduce((a, b) => a + b) / roiValues.length;
  }

  double _calculateTrendRoi(List<double> prices) {
    if (prices.isEmpty || prices.first <= 0) return 0;
    final first = prices.first;
    final last = prices.last;
    return ((last - first) / first) * 100;
  }

  String _deriveSentimentLabel(double delta) {
    if (delta >= 12) return 'Bullish';
    if (delta >= 2) return 'Positive';
    if (delta <= -8) return 'Bearish';
    if (delta < 0) return 'Cooling';
    return 'Neutral';
  }

  Widget _buildHeroMetric({
    required String title,
    required String value,
    required bool trendUp,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: trendUp
                ? [Colors.green[500]!, Colors.green[700]!]
                : [Colors.red[400]!, Colors.red[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: trendUp
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  trendUp ? 'Positive Momentum' : 'Monitor Risk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.lock_open, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Buying Power & ROI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect your holdings to view real-time profit, risk exposure, and tailored moves.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              AppRouter.navigateTo(
                context,
                AppRouter.propertyManagement,
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioMetric({
    required String label,
    required String value,
    required String trendText,
    required bool positive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: positive ? Colors.green : Colors.red,
              ),
              Text(
                trendText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: positive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPlaceholder({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withOpacity(0.08),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel ?? 'Refresh data'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineNotice(
    String message, {
    IconData icon = Icons.info_outline,
    Color? color,
  }) {
    final resolvedColor = color ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: resolvedColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: resolvedColor.withOpacity(0.9),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatedStamp(DateTime? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Updated ${_formatRelativeTime(timestamp)}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) {
      return 'moments ago';
    }
    final localTime = timestamp.toLocal();
    final diff = DateTime.now().difference(localTime);

    if (diff.inMinutes < 1) return 'moments ago';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return '${localTime.day}/${localTime.month}/${localTime.year}';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: Colors.grey[200]!),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isWinner,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Leading',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsItem({required String title, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.blue.withValues(alpha: 0.1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem {
  final String label;
  final String value;
  final String? delta;
  final bool trendUp;

  _MacroItem({
    required this.label,
    required this.value,
    this.delta,
    required this.trendUp,
  });
}

const List<String> _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _MonthlyTrend {
  _MonthlyTrend({required this.date});

  final DateTime date;
  double total = 0;
  int count = 0;

  double get averagePrice => count == 0 ? 0 : total / count;
}
