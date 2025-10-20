import '../../theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/bid.dart';
import '../models/auction.dart';
import '../services/bid_service.dart';
import '../services/property_financials_service.dart';
import 'add_property_page.dart';
import 'valuate_page.dart';
import 'my_properties_page.dart';
import 'auction_details_page.dart';
import 'auctions_page.dart';
import 'create_auction_request_dialog.dart';
import 'portfolio_analytics_page.dart';
import '../widgets/loading_button.dart';
import 'calendar_page.dart';
import '../services/api_client.dart';

class PropertiesManagementPage extends StatefulWidget {
  const PropertiesManagementPage({super.key});

  @override
  State<PropertiesManagementPage> createState() =>
      _PropertiesManagementPageState();
}

class _PropertiesManagementPageState extends State<PropertiesManagementPage> {
  List<Bid> _myBids = [];
  bool _loadingBids = true;
  bool _loadingFinancials = true;
  PortfolioSummary? _portfolioSummary;
  List<PropertyFinancials> _propertiesFinancials = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppState>().isLoggedIn) {
        context.read<AppState>().loadProperties();
        _loadMyBids();
        _loadPortfolioFinancials();
      }
    });
  }

  Future<void> _loadPortfolioFinancials() async {
    setState(() {
      _loadingFinancials = true;
    });

    try {
      final appState = context.read<AppState>();
      final propertyIds = appState.userProperties
          .map((p) => p.propertyId)
          .toList();

      if (propertyIds.isEmpty) {
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

      final financials =
          await PropertyFinancialsService.getAllPropertiesFinancials(
            propertyIds,
          );
      final summary = PropertyFinancialsService.calculatePortfolioSummary(
        financials,
      );

      setState(() {
        _propertiesFinancials = financials;
        _portfolioSummary = summary;
        _loadingFinancials = false;
      });
    } catch (e) {
      print('Error loading portfolio financials: $e');
      setState(() {
        _loadingFinancials = false;
      });
    }
  }

  Future<void> _loadMyBids() async {
    print('🔄 Loading my bids...');
    setState(() {
      _loadingBids = true;
    });

    try {
      final response = await BidService.getUserBids();
      print(
        '📊 My Bids Response - Success: ${response.success}, Data: ${response.data?.length}, Error: ${response.error}',
      );

      if (response.success && response.data != null) {
        print('✅ Loaded ${response.data!.length} bids');
        for (var bid in response.data!) {
          print(
            '  Bid #${bid.bidId}: \$${bid.bidAmount} on Auction #${bid.auctionId}',
          );
          print('    Has auction data: ${bid.auction != null}');
          if (bid.auction != null) {
            print(
              '    Auction property: ${bid.auction!.property?.name ?? "No property"}',
            );
          }
        }
        setState(() {
          _myBids = response.data!;
          _loadingBids = false;
        });
      } else {
        print('❌ Failed to load bids: ${response.error}');
        setState(() {
          _myBids = [];
          _loadingBids = false;
        });
      }
    } catch (e) {
      print('❌ Error loading my bids: $e');
      setState(() {
        _myBids = [];
        _loadingBids = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoggedIn) {
            return _buildLoggedInContent(context, appState);
          } else {
            return _buildNotLoggedInContent(context, appState);
          }
        },
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimal Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Hello, ${appState.user?.firstName}',
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

          // Financial Dashboard
          if (!_loadingFinancials && _portfolioSummary != null)
            _buildFinancialDashboard(),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Access: Calendar
                _buildCalendarSection(context),

                const SizedBox(height: 24),

                // My Bids Section
                _buildMyBidsSection(appState),

                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.add_home_work,
                        title: 'Add Property',
                        subtitle: 'List your property',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPropertyPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.assessment,
                        title: 'Get Valuation',
                        subtitle: 'Detailed analysis',
                        color: Colors.blue,
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

                const SizedBox(height: 32),

                // My Properties Section
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
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyPropertiesPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_list),
                      label: const Text('View All'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Properties List
                if (appState.loadingProperties)
                  const Center(child: CircularProgressIndicator())
                else if (appState.userProperties.isEmpty)
                  _buildEmptyPropertiesState(context)
                else
                  _buildPropertiesList(context, appState),

                const SizedBox(height: 32),

                // My Auctions Section
                _buildMyAuctionsSection(context, appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDashboard() {
    final summary = _portfolioSummary!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Net Value',
                '\$${_formatNumber(summary.totalNetValue)}',
                Colors.green,
              ),
              _buildMetricCard(
                'Total Assets',
                '\$${_formatNumber(summary.totalAssets)}',
                Colors.blue,
              ),
              _buildMetricCard(
                'Total Owed',
                '\$${_formatNumber(summary.totalOwed)}',
                Colors.orange,
              ),
              _buildMetricCard(
                'Avg ROI',
                '${summary.averageROI.toStringAsFixed(1)}%',
                summary.averageROI >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pie Chart
          if (summary.totalAssets > 0) _buildOwnVsOwePieChart(summary),

          const SizedBox(height: 24),

          // Analytics Button
          SizedBox(
            width: double.infinity,
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
                backgroundColor: Colors.grey[100],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Detailed Analytics',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: Colors.grey[800]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
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
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnVsOwePieChart(PortfolioSummary summary) {
    final owned = summary.totalEquity;
    final owed = summary.totalOwed;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: owned,
                    title: '${summary.ownedPercent.toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: owed,
                    title: '${summary.owedPercent.toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Owned', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('Owed', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  Widget _buildCalendarSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Events & schedules',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // removed saved searches section

  Widget _buildMyBidsSection(AppState appState) {
    // Get only the latest bid per auction
    final Map<int, Bid> latestBidsMap = {};
    for (var bid in _myBids) {
      final existingBid = latestBidsMap[bid.auctionId];
      if (existingBid == null || bid.createdAt.isAfter(existingBid.createdAt)) {
        latestBidsMap[bid.auctionId] = bid;
      }
    }
    final latestBids = latestBidsMap.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Positions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.7,
              ),
            ),
            if (_loadingBids)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${latestBids.length}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (!_loadingBids && latestBids.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.gavel_rounded, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No Positions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start bidding on properties!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuctionsPage(),
                        ),
                      );
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 18),
                        SizedBox(width: 8),
                        Text('Browse Auctions'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!_loadingBids)
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: latestBids.length,
              itemBuilder: (context, index) {
                final bid = latestBids[index];
                final auction =
                    bid.auction ??
                    appState.auctions.firstWhere(
                      (a) => a.auctionId == bid.auctionId,
                      orElse: () => Auction(
                        auctionId: bid.auctionId,
                        propertyId: 0,
                        startPrice: 0,
                        currentPrice: bid.bidAmount,
                        startAt: DateTime.now(),
                        duration: 0,
                        bidCount: 0,
                        status: 'Unknown',
                        createdAt: DateTime.now(),
                      ),
                    );
                return _buildEnhancedBidCard(bid, auction);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedBidCard(Bid bid, Auction auction) {
    final isWinning = auction.currentPrice == bid.bidAmount;
    final isActive = auction.isActive;
    final isEnded = auction.isEnded;
    final property = auction.property;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child:
                        property?.imageUrl != null &&
                            (property?.imageUrl.isNotEmpty ?? false)
                        ? Image.network(
                            property!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.home,
                                size: 40,
                                color: Colors.grey[400],
                              );
                            },
                          )
                        : Icon(Icons.home, size: 40, color: Colors.grey[400]),
                  ),
                  // Status Badge
                  if (isWinning && isActive)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Winning',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bid Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property?.name ?? 'Property #${auction.propertyId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBidStat(
                        'Your Bid',
                        '\$${bid.bidAmount.toStringAsFixed(0)}',
                        Colors.blue,
                      ),
                      _buildBidStat(
                        'Current',
                        '\$${auction.currentPrice.toStringAsFixed(0)}',
                        isWinning ? Colors.green : Colors.red,
                      ),
                      _buildBidStat(
                        'Bids',
                        '${auction.bidCount}',
                        Colors.grey[700]!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isEnded
                          ? Colors.grey[200]
                          : (isWinning
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEnded
                          ? (isWinning ? 'Won' : 'Lost')
                          : (isActive
                                ? (isWinning ? 'Leading' : 'Outbid')
                                : auction.status),
                      style: TextStyle(
                        color: isEnded
                            ? Colors.grey[700]
                            : (isWinning ? Colors.green : Colors.orange),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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

  Widget _buildBidStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedInContent(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimal Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Property Management',
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Access Row: Calendar & Valuation
                Row(
                  children: [
                    Expanded(child: _buildCalendarSection(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.assessment,
                        title: 'Quick Estimate',
                        subtitle: 'Property valuation',
                        color: Colors.blue,
                        onTap: () {
                          _showQuickValuationDialog(context);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Prompt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Want More Features?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign up to add your own properties, get detailed valuations, and manage your listings.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/auth');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Sign Up Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPropertiesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Properties Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first property to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPropertyPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Property'),
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    property.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.home,
                          color: Colors.grey[400],
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: property.isApproved
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: property.isApproved ? Colors.green : Colors.orange,
                      fontSize: 11,
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

  Widget _buildMyAuctionsSection(BuildContext context, AppState appState) {
    final userAuctions = appState.userAuctions;
    final liveAuctions = userAuctions.where((a) => a.isActive).toList();
    final endedAuctions = userAuctions.where((a) => a.isEnded).toList();
    final requestedAuctions = userAuctions
        .where((a) => a.status == 'Requested')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Auctions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.7,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreateAuctionRequestDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text('Create'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Auctions
        if (liveAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Live Auctions',
            liveAuctions,
            Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Requested Auctions
        if (requestedAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Requested Auctions',
            requestedAuctions,
            Colors.orange,
          ),
          const SizedBox(height: 16),
        ],

        // Ended Auctions
        if (endedAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Ended Auctions',
            endedAuctions,
            Colors.grey,
          ),
          const SizedBox(height: 16),
        ],

        // Empty State
        if (userAuctions.isEmpty) _buildEmptyAuctionsState(context),
      ],
    );
  }

  Widget _buildAuctionSubsection(
    BuildContext context,
    String title,
    List auctions,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${auctions.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...auctions
            .take(3)
            .map((auction) => _buildAuctionCard(context, auction, color)),
        if (auctions.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                // Navigate to full auctions page with filter
                // This could be implemented later
              },
              child: Text('View all ${auctions.length} ${title.toLowerCase()}'),
            ),
          ),
      ],
    );
  }

  Widget _buildAuctionCard(BuildContext context, auction, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: auction.property?.imageUrl.isNotEmpty == true
                    ? Image.network(
                        auction.property!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.home, color: Colors.grey[400], size: 24),
                      )
                    : Icon(Icons.home, color: Colors.grey[400], size: 24),
              ),
            ),
            const SizedBox(width: 12),

            // Auction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.name ?? 'Unknown Property',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auction.property?.location ?? 'Unknown Location',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                auction.status,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAuctionsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.gavel_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Auctions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first auction request to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateAuctionRequestDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Create Auction'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickValuationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuickValuationDialog();
      },
    );
  }
}

class QuickValuationDialog extends StatefulWidget {
  @override
  State<QuickValuationDialog> createState() => _QuickValuationDialogState();
}

class _QuickValuationDialogState extends State<QuickValuationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _estimateResult;

  @override
  void initState() {
    super.initState();
    _yearBuiltController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFeetController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  Future<void> _getEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _estimateResult = null;
    });

    try {
      // Call the public estimation API
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/Property/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': _locationController.text,
          'bedrooms': int.parse(_bedroomsController.text),
          'bathrooms': int.parse(_bathroomsController.text),
          'squareFeet': int.parse(_squareFeetController.text),
          'yearBuilt': int.parse(_yearBuiltController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _estimateResult = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get estimate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Property Estimate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.surface),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_estimateResult == null) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return 'Location is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bedrooms',
                              prefixIcon: Icon(Icons.bed),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bathrooms',
                              prefixIcon: Icon(Icons.bathtub),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _squareFeetController,
                            decoration: const InputDecoration(
                              labelText: 'Square Feet',
                              prefixIcon: Icon(Icons.square_foot),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _yearBuiltController,
                            decoration: const InputDecoration(
                              labelText: 'Year Built',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        onPressed: _isLoading ? null : _getEstimate,
                        isLoading: _isLoading,
                        child: const Text('Get Estimate'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show estimate result
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assessment, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Estimated Value',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_estimateResult!['estimatedValue'].toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _estimateResult!['confidence'],
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _estimateResult!['message'],
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _estimateResult = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  child: const Text('Get Another Estimate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
