import '../../theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../widgets/auction_timer.dart';
import '../widgets/property_image_carousel.dart';
import 'auction_details_page.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  List<Auction> _filteredAuctions = [];
  Map<String, dynamic> _activeFilters = {};

  // Filter options
  final Map<String, String> _categoryOptions = {
    'all': 'All Categories',
    'Single Family': 'Single Family',
    'Condo': 'Condo',
    'Townhouse': 'Townhouse',
    'Commercial': 'Commercial',
  };

  final Map<String, String> _priceRangeOptions = {
    'all': 'All Prices',
    'under_300k': 'Under \$300K',
    '300k_500k': '\$300K - \$500K',
    '500k_750k': '\$500K - \$750K',
    'over_750k': 'Over \$750K',
  };

  final Map<String, String> _bidCountOptions = {
    'all': 'All Bid Counts',
    'no_bids': 'No Bids',
    'low_bids': '1-5 Bids',
    'medium_bids': '6-15 Bids',
    'high_bids': '16+ Bids',
  };

  final Map<String, String> _projectOptions = {
    'all': 'All Projects',
    'Luxury': 'Luxury',
    'Affordable': 'Affordable',
    'Commercial': 'Commercial',
    'Residential': 'Residential',
  };

  final Map<String, String> _locationOptions = {
    'all': 'All Locations',
    'Downtown': 'Downtown',
    'Suburbs': 'Suburbs',
    'Waterfront': 'Waterfront',
    'Historic': 'Historic District',
  };

  // Sort options
  final Map<String, String> _sortOptions = {
    'none': 'No Sorting',
    'bidders_asc': 'Bidders (Low to High)',
    'bidders_desc': 'Bidders (High to Low)',
    'price_asc': 'Price (Low to High)',
    'price_desc': 'Price (High to Low)',
    'end_time_asc': 'End Time (Soonest First)',
    'end_time_desc': 'End Time (Latest First)',
  };

  String _currentSort = 'none';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure auctions are loaded before applying filters
      final appState = context.read<AppState>();
      if (appState.auctions.isEmpty) {
        appState.loadAuctions().then((_) {
          _applyFilters();
        });
      } else {
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _applyFilters() {
    try {
      final appState = context.read<AppState>();
      print('Applying filters - auctions count: ${appState.auctions.length}');
      List<Auction> auctions = List.from(appState.auctions);

      // Apply category filter
      if (_activeFilters.containsKey('category') &&
          _activeFilters['category'] != 'all') {
        auctions = auctions.where((auction) {
          return auction.property?.category == _activeFilters['category'];
        }).toList();
      }

      // Apply price range filter
      if (_activeFilters.containsKey('priceRange') &&
          _activeFilters['priceRange'] != 'all') {
        auctions = auctions.where((auction) {
          final currentPrice = auction.currentPrice;
          switch (_activeFilters['priceRange']) {
            case 'under_300k':
              return currentPrice < 300000;
            case '300k_500k':
              return currentPrice >= 300000 && currentPrice < 500000;
            case '500k_750k':
              return currentPrice >= 500000 && currentPrice < 750000;
            case 'over_750k':
              return currentPrice >= 750000;
            default:
              return true;
          }
        }).toList();
      }

      // Apply bid count filter
      if (_activeFilters.containsKey('bidCount') &&
          _activeFilters['bidCount'] != 'all') {
        auctions = auctions.where((auction) {
          final bidCount = auction.bidCount;
          switch (_activeFilters['bidCount']) {
            case 'no_bids':
              return bidCount == 0;
            case 'low_bids':
              return bidCount >= 1 && bidCount <= 5;
            case 'medium_bids':
              return bidCount >= 6 && bidCount <= 15;
            case 'high_bids':
              return bidCount >= 16;
            default:
              return true;
          }
        }).toList();
      }

      // Apply project filter
      if (_activeFilters.containsKey('project') &&
          _activeFilters['project'] != 'all') {
        auctions = auctions.where((auction) {
          return auction.property?.project == _activeFilters['project'];
        }).toList();
      }

      // Apply location filter
      if (_activeFilters.containsKey('location') &&
          _activeFilters['location'] != 'all') {
        auctions = auctions.where((auction) {
          return auction.property?.location.contains(
                _activeFilters['location'],
              ) ??
              false;
        }).toList();
      }

      // Apply sorting
      _applySorting(auctions);

      print('Filtered auctions count: ${auctions.length}');
      setState(() {
        _filteredAuctions = auctions;
      });
    } catch (e) {
      print('Error applying filters: $e');
      setState(() {
        _filteredAuctions = [];
      });
    }
  }

  void _setFilter(String key, String value) {
    print('Setting filter: $key = $value');
    setState(() {
      _activeFilters[key] = value;
    });
    _applyFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
    });
    _applyFilters();
  }

  void _refreshAuctionData() {
    final appState = context.read<AppState>();
    appState.loadAuctions();
    _applyFilters();
  }

  void _applySorting(List<Auction> auctions) {
    if (_currentSort == 'none') return;

    switch (_currentSort) {
      case 'bidders_asc':
        auctions.sort((a, b) => a.bidCount.compareTo(b.bidCount));
        break;
      case 'bidders_desc':
        auctions.sort((a, b) => b.bidCount.compareTo(a.bidCount));
        break;
      case 'price_asc':
        auctions.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'price_desc':
        auctions.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'end_time_asc':
        auctions.sort((a, b) => a.endAt.compareTo(b.endAt));
        break;
      case 'end_time_desc':
        auctions.sort((a, b) => b.endAt.compareTo(a.endAt));
        break;
    }
  }

  void _setSort(String sortKey) {
    setState(() {
      _currentSort = sortKey;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Auctions'),
            const SizedBox(width: 8),
            // Small refresh indicator
            Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.loadingAuctions) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        actions: [
          PopupMenuButton<String>(
            onSelected: _setSort,
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) {
              return _sortOptions.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      if (_currentSort == entry.key)
                        Icon(Icons.check, color: AppColors.primary, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          print(
            'AuctionsPage builder - loadingAuctions: ${appState.loadingAuctions}, auctions length: ${appState.auctions.length}',
          );

          if (appState.loadingAuctions) {
            return const Center(child: CircularProgressIndicator());
          }

          // Add null safety check
          if (appState.auctions.isEmpty) {
            return _buildEmptyState(
              context,
              'No Auctions',
              'No auctions available at the moment',
              Icons.gavel_outlined,
            );
          }

          return Column(
            children: [
              // Scrollable filter bar
              _buildScrollableFilterBar(),

              // Auctions Tables with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await appState.loadAuctions();
                    _applyFilters();
                  },
                  child: _buildAuctionsTables(appState),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScrollableFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.background!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Clear All
            _buildFilterButton('Clear All', 'clear', {}),
            const SizedBox(width: 8),

            // Category Filter
            _buildFilterButton('Category', 'category', _categoryOptions),
            const SizedBox(width: 8),

            // Price Filter
            _buildFilterButton('Price', 'priceRange', _priceRangeOptions),
            const SizedBox(width: 8),

            // Bids Filter
            _buildFilterButton('Bids', 'bidCount', _bidCountOptions),
            const SizedBox(width: 8),

            // Project Filter
            _buildFilterButton('Project', 'project', _projectOptions),
            const SizedBox(width: 8),

            // Location Filter
            _buildFilterButton('Location', 'location', _locationOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsTables(AppState appState) {
    print(
      '_buildAuctionsTables - appState.auctions: ${appState.auctions.length}, _filteredAuctions: ${_filteredAuctions.length}',
    );

    final auctionsToShow = _filteredAuctions.isEmpty
        ? appState.auctions
        : _filteredAuctions;

    // Separate upcoming, live and ended auctions
    final now = DateTime.now();

    final upcomingAuctions = auctionsToShow
        .where(
          (auction) =>
              auction.status == 'Active' && now.isBefore(auction.startAt),
        )
        .toList();

    final liveAuctions = auctionsToShow
        .where(
          (auction) =>
              auction.isActive &&
              auction.status != 'Ended' &&
              now.isAfter(auction.startAt) &&
              !now.isAfter(auction.endAt),
        )
        .toList();

    final endedAuctions = auctionsToShow
        .where(
          (auction) =>
              auction.isEnded ||
              auction.status == 'Ended' ||
              now.isAfter(auction.endAt),
        )
        .toList();

    print(
      'Auctions separation - Total: ${auctionsToShow.length}, Upcoming: ${upcomingAuctions.length}, Live: ${liveAuctions.length}, Ended: ${endedAuctions.length}',
    );

    // Debug each auction
    for (var auction in auctionsToShow) {
      print(
        'Auction ${auction.auctionId}: status=${auction.status}, endAt=${auction.endAt}, isActive=${auction.isActive}, isEnded=${auction.isEnded}',
      );
      print('  - Current time: ${DateTime.now()}');
      print('  - End time: ${auction.endAt}');
      print(
        '  - Time difference: ${auction.endAt.difference(DateTime.now()).inMinutes} minutes',
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Upcoming Auctions Section
          if (upcomingAuctions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary!, AppColors.primary!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Upcoming Auctions (${upcomingAuctions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildAuctionsTable(
              context,
              upcomingAuctions,
              isLive: false,
              isUpcoming: true,
            ),
            const SizedBox(height: 24), // Spacing between sections
          ],

          // Live Auctions Section
          if (liveAuctions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top: upcomingAuctions.isEmpty ? 16 : 0,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.background!, AppColors.background!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Live Auctions (${liveAuctions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildAuctionsTable(
              context,
              liveAuctions,
              isLive: true,
              isUpcoming: false,
            ),
          ],

          // Ended Auctions Section
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background!, Colors.orange[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Ended Auctions (${endedAuctions.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (endedAuctions.isNotEmpty)
            _buildAuctionsTable(context, endedAuctions, isLive: false)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.background!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Ended Auctions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for completed auctions',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Empty state if no auctions
          if (auctionsToShow.isEmpty) ...[
            const SizedBox(height: 32),
            _buildEmptyState(
              context,
              'No Auctions Found',
              'No auctions match your current filters',
              Icons.filter_list_off,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuctionsTable(
    BuildContext context,
    List<Auction> auctions, {
    required bool isLive,
    bool isUpcoming = false,
  }) {
    Color borderColor;
    Color headerColor;

    if (isUpcoming) {
      borderColor = AppColors.primary!;
      headerColor = AppColors.primary!;
    } else if (isLive) {
      borderColor = Colors.green[200]!;
      headerColor = AppColors.background!;
    } else {
      borderColor = AppColors.secondary!;
      headerColor = AppColors.background!;
    }

    // Calculate dynamic height based on actual auction count (max 5)
    final displayCount = auctions.length > 5 ? 5 : auctions.length;
    final dynamicHeight =
        displayCount * 60.0 + 48.0; // rows × 60px + header height

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        height: dynamicHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Column(
              children: [
                // Sticky Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80, // Fixed width for property image
                        child: Text(
                          'Image',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200, // Fixed width for property name
                        child: Text(
                          'Property Name',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120, // Fixed width for start price
                        child: Text(
                          'Start Price',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120, // Fixed width for current price
                        child: Text(
                          'Current Price',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80, // Fixed width for bids
                        child: Text(
                          'Bids',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100, // Fixed width for time left
                        child: Text(
                          isUpcoming
                              ? 'Starts In'
                              : (isLive ? 'Time Left' : 'Ended'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120, // Fixed width for project
                        child: Text(
                          'Project',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120, // Fixed width for category
                        child: Text(
                          'Category',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Data rows
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: auctions
                          .map(
                            (auction) => _buildAuctionMatrixRow(
                              context,
                              auction,
                              isLive: isLive,
                              isUpcoming: isUpcoming,
                              onAuctionEnded: _refreshAuctionData,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionMatrixRow(
    BuildContext context,
    Auction auction, {
    required bool isLive,
    bool isUpcoming = false,
    VoidCallback? onAuctionEnded,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.background!)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        ),
        child: Row(
          children: [
            // Property Image/Carousel
            SizedBox(
              width: 80, // Fixed width for property image
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary!),
                ),
                child: PropertyImageCarousel(
                  images: auction.property?.propertyImages ?? [],
                  fallbackImageUrl: auction.property?.imageUrl,
                  height: 50,
                  showIndicators: false,
                  showNavigationButtons: false,
                  showImageCounter: false,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200, // Fixed width for property name
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.name ?? 'Property',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auction.property?.location ?? '',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Fixed width for start price
              child: Text(
                '\$${auction.startPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Fixed width for current price
              child: Text(
                '\$${auction.currentPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80, // Fixed width for bids
              child: Text(
                '${auction.bidCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100, // Fixed width for time left/ended
              child: isUpcoming
                  ? _buildStartsInWidget(auction)
                  : (isLive
                        ? AuctionTimer(
                            auction: auction,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                            onAuctionEnded: onAuctionEnded,
                          )
                        : Text(
                            'Ended',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          )),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Fixed width for project
              child: Text(
                auction.property?.project ?? 'N/A',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Fixed width for category
              child: Text(
                auction.property?.category ?? 'N/A',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartsInWidget(Auction auction) {
    final now = DateTime.now();
    final difference = auction.startAt.difference(now);

    String timeText;
    if (difference.inDays > 0) {
      timeText = '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}m';
    } else {
      timeText = 'Starting soon';
    }

    return Text(
      timeText,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String title,
    String filterKey,
    Map<String, String> options,
  ) {
    if (filterKey == 'clear') {
      return InkWell(
        onTap: _clearAllFilters,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final currentValue = _activeFilters[filterKey] ?? 'all';
    final currentLabel = options[currentValue] ?? 'All';
    final hasFilter = currentValue != 'all';

    return InkWell(
      onTap: () => _showFilterMenu(filterKey, options),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFilter ? AppColors.primary! : AppColors.secondary!,
          ),
        ),
        child: Text(
          currentLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: hasFilter ? FontWeight.w600 : FontWeight.normal,
            color: hasFilter ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(String filterKey, Map<String, String> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${filterKey.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            final isSelected =
                entry.key == (_activeFilters[filterKey] ?? 'all');
            return ListTile(
              title: Text(entry.value),
              leading: isSelected
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _setFilter(filterKey, entry.key);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
