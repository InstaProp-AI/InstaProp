import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import 'auction_details_page.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  List<Auction> _filteredAuctions = [];
  Map<String, dynamic> _activeFilters = {};
  bool _showFilters = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final appState = context.read<AppState>();
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

    setState(() {
      _filteredAuctions = auctions;
    });
  }

  void _setFilter(String key, String value) {
    setState(() {
      _activeFilters[key] = value;
    });
    _applyFilters();
  }

  void _removeFilter(String key) {
    setState(() {
      _activeFilters.remove(key);
    });
    _applyFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auctions'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              final appState = context.read<AppState>();
              appState.loadAuctions();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.loadingAuctions) {
            return const Center(child: CircularProgressIndicator());
          }

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
              // Filter Bar
              if (_activeFilters.isNotEmpty) _buildFilterBar(),

              // Filter Options
              if (_showFilters) _buildFilterOptions(),

              // Auctions Tables
              Expanded(child: _buildAuctionsTables(appState)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Active Filters:',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeFilters.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getFilterDisplayText(entry.key, entry.value),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeFilter(entry.key),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_activeFilters.isNotEmpty)
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Auctions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Category Filter
          _buildFilterSection(
            'Property Category',
            'category',
            _categoryOptions,
          ),

          const SizedBox(height: 16),

          // Price Range Filter
          _buildFilterSection('Price Range', 'priceRange', _priceRangeOptions),

          const SizedBox(height: 16),

          // Bid Count Filter
          _buildFilterSection('Bid Count', 'bidCount', _bidCountOptions),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    String filterKey,
    Map<String, String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.entries.map((entry) {
            final isSelected = _activeFilters[filterKey] == entry.key;
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                _setFilter(filterKey, entry.key);
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAuctionsTables(AppState appState) {
    final auctionsToShow = _filteredAuctions.isEmpty
        ? appState.auctions
        : _filteredAuctions;

    // Separate live and ended auctions
    final liveAuctions = auctionsToShow
        .where((auction) => auction.isActive)
        .toList();
    final endedAuctions = auctionsToShow
        .where((auction) => auction.isEnded)
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Live Auctions Section
          if (liveAuctions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
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
                    color: Colors.green[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Live Auctions (${liveAuctions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            _buildAuctionsTable(context, liveAuctions, isLive: true),
          ],

          // Ended Auctions Section
          if (endedAuctions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Ended Auctions (${endedAuctions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            _buildAuctionsTable(context, endedAuctions, isLive: false),
          ],

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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? Colors.green[200]! : Colors.orange[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (isLive ? Colors.green : Colors.orange)[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200, // Fixed width for property name
                      child: Text(
                        'Property Name',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120, // Fixed width for start price
                      child: Text(
                        'Start Price',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120, // Fixed width for current price
                      child: Text(
                        'Current Price',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80, // Fixed width for bids
                      child: Text(
                        'Bids',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100, // Fixed width for time left
                      child: Text(
                        isLive ? 'Time Left' : 'Ended',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120, // Fixed width for category
                      child: Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Data rows
              ...auctions
                  .map(
                    (auction) => _buildAuctionMatrixRow(
                      context,
                      auction,
                      isLive: isLive,
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionMatrixRow(
    BuildContext context,
    Auction auction, {
    required bool isLive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        ),
        child: Row(
          children: [
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                '\$${auction.startAt.toStringAsFixed(0)}',
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
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80, // Fixed width for bids
              child: Text(
                '${auction.bidCount}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100, // Fixed width for time left/ended
              child: isLive
                  ? Text(
                      auction.timeRemaining,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.red[600],
                        fontSize: 12,
                      ),
                    )
                  : Text(
                      'Ended',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120, // Fixed width for category
              child: Text(
                auction.property?.category ?? 'N/A',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
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
            Icon(icon, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
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

  String _getFilterDisplayText(String key, String value) {
    switch (key) {
      case 'category':
        return _categoryOptions[value] ?? value;
      case 'priceRange':
        return _priceRangeOptions[value] ?? value;
      case 'bidCount':
        return _bidCountOptions[value] ?? value;
      default:
        return value;
    }
  }
}
