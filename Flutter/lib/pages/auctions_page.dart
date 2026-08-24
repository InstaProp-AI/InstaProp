import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/property.dart';
import '../models/property_doc.dart';
import '../widgets/auction_timer.dart';
import '../widgets/property_image_carousel.dart';
import 'auction_details_page.dart';
import 'vip_auctions_page.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage>
    with SingleTickerProviderStateMixin {
  List<Auction> _filteredAuctions = [];
  Map<String, dynamic> _activeFilters = {};

  // Track recently updated auctions for highlighting
  final Map<String, DateTime> _recentlyUpdatedAuctions = {};
  final Set<String> _highlightedAuctions = {};
  final Map<String, double> _previousPrices = {}; // Track previous prices
  final Map<String, int> _previousBidCounts = {}; // Track previous bid counts

  // Track when we last applied filters to avoid redundant calls
  int _lastAuctionsHash = 0;

  // Filter options
  final Map<String, String> _typeOptions = {
    'all': 'All Types',
    'Apartment': 'Apartment',
    'Villa': 'Villa',
    'Townhouse': 'Townhouse',
    'Studio': 'Studio',
    'Office': 'Office',
    'Retail': 'Retail',
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
    print('🔄 AuctionsPage initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Ensure auctions are loaded before applying filters
      final appState = context.read<AppState>();
      print(
        '🔄 AuctionsPage post-frame callback - auctions: ${appState.auctions.length}, loading: ${appState.loadingAuctions}',
      );

      // Always try to load auctions if empty, even if not loading
      if (appState.auctions.isEmpty && !appState.loadingAuctions) {
        print('🔄 Loading auctions from initState...');
        appState
            .loadAuctions()
            .then((_) {
              if (mounted) {
                print('✅ Auctions loaded, applying filters');
                _applyFilters();
              }
            })
            .catchError((e) {
              print('❌ Error loading auctions in initState: $e');
            });
      } else if (appState.auctions.isNotEmpty) {
        print('✅ Auctions already loaded, applying filters');
        _applyFilters();
      } else {
        print('⏳ Auctions are loading...');
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
      print(
        '🔄 Applying filters - auctions count: ${appState.auctions.length}',
      );

      // Safety check: ensure auctions list is valid
      if (appState.auctions.isEmpty) {
        print('⚠️ No auctions to filter');
        setState(() {
          _filteredAuctions = [];
        });
        return;
      }

      List<Auction> auctions = List.from(appState.auctions);

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

      // Apply type filter
      if (_activeFilters.containsKey('type') &&
          _activeFilters['type'] != 'all') {
        auctions = auctions.where((auction) {
          return auction.property?.typeLabel == _activeFilters['type'];
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

  /// Track auction updates to highlight changed rows
  void _trackAuctionUpdates(List<Auction> auctions) {
    if (auctions.isEmpty) return;

    // Schedule after frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      for (final auction in auctions) {
        try {
          final auctionId = auction.auctionId;
          final currentPrice = auction.currentPrice;
          final currentBidCount = auction.bidCount;

          final previousPrice = _previousPrices[auctionId];
          final previousBidCount = _previousBidCounts[auctionId];

          // Detect if price or bid count changed
          bool hasChanged = false;

          if (previousPrice != null && currentPrice != previousPrice) {
            print(
              '🔔 Auction $auctionId price changed: \$${previousPrice} → \$${currentPrice}',
            );
            hasChanged = true;
          }

          if (previousBidCount != null && currentBidCount != previousBidCount) {
            print(
              '🔔 Auction $auctionId bid count changed: $previousBidCount → ${currentBidCount}',
            );
            hasChanged = true;
          }

          // Update tracked values (no setState here)
          _previousPrices[auctionId] = currentPrice;
          _previousBidCounts[auctionId] = currentBidCount;

          // If changed, mark for highlighting (this will call setState)
          if (hasChanged) {
            _markAuctionUpdated(auctionId);
          }
        } catch (e) {
          print('⚠️ Error tracking auction update: $e');
          // Continue with other auctions even if one fails
        }
      }
    });
  }

  /// Mark an auction as updated (called when we detect price/bid changes)
  void _markAuctionUpdated(String auctionId) {
    setState(() {
      _recentlyUpdatedAuctions[auctionId] = DateTime.now();
      _highlightedAuctions.add(auctionId);
    });

    // Remove yellow highlight after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedAuctions.remove(auctionId);
        });
      }
    });

    // Remove from priority sorting after 60 seconds (auction will return to normal position)
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedAuctions.remove(auctionId);
          _applyFilters(); // Re-sort to move it back to normal position
        });
      }
    });
  }

  /// Check if auction should be highlighted
  bool _isAuctionHighlighted(String auctionId) {
    return _highlightedAuctions.contains(auctionId);
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
    // First, separate recently updated auctions from the rest
    final recentlyUpdated = <Auction>[];
    final rest = <Auction>[];

    for (final auction in auctions) {
      if (_recentlyUpdatedAuctions.containsKey(auction.auctionId)) {
        recentlyUpdated.add(auction);
      } else {
        rest.add(auction);
      }
    }

    // Sort recently updated by their update time (most recent first)
    recentlyUpdated.sort((a, b) {
      final timeA = _recentlyUpdatedAuctions[a.auctionId]!;
      final timeB = _recentlyUpdatedAuctions[b.auctionId]!;
      return timeB.compareTo(timeA); // Most recent first
    });

    // Apply user's selected sort to the rest
    if (_currentSort != 'none') {
      switch (_currentSort) {
        case 'bidders_asc':
          rest.sort((a, b) => a.bidCount.compareTo(b.bidCount));
          break;
        case 'bidders_desc':
          rest.sort((a, b) => b.bidCount.compareTo(a.bidCount));
          break;
        case 'price_asc':
          rest.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
          break;
        case 'price_desc':
          rest.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
          break;
        case 'end_time_asc':
          rest.sort((a, b) => a.endAt.compareTo(b.endAt));
          break;
        case 'end_time_desc':
          rest.sort((a, b) => b.endAt.compareTo(a.endAt));
          break;
      }
    }

    // Clear and rebuild the list with recently updated first
    auctions.clear();
    auctions.addAll(recentlyUpdated);
    auctions.addAll(rest);
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
      backgroundColor: Colors.white,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          try {
            print(
              'AuctionsPage builder - loadingAuctions: ${appState.loadingAuctions}, auctions length: ${appState.auctions.length}',
            );

            // Safety check: if auctions list is null or has parsing errors, show error
            if (appState.auctions.isEmpty && !appState.loadingAuctions) {
              print(
                '⚠️ AuctionsPage: No auctions available - showing empty state',
              );
            }

            // Force load auctions if they're empty and not loading
            if (appState.auctions.isEmpty && !appState.loadingAuctions) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  print('🔄 Force loading auctions from build method');
                  appState.loadAuctions();
                }
              });
            }

            // Track auction updates for highlighting
            if (appState.auctions.isNotEmpty) {
              _trackAuctionUpdates(appState.auctions);
            }

            // Re-apply filters when AppState auctions actually change
            // Use a hash to detect if auction data changed
            if (appState.auctions.isNotEmpty) {
              try {
                final currentHash = appState.auctions.fold<int>(0, (
                  hash,
                  auction,
                ) {
                  try {
                    return hash ^
                        auction.auctionId.hashCode ^
                        auction.currentPrice.hashCode ^
                        auction.bidCount.hashCode;
                  } catch (e) {
                    print(
                      '⚠️ Error calculating hash for auction ${auction.auctionId}: $e',
                    );
                    return hash; // Return hash unchanged if this auction fails
                  }
                });

                if (currentHash != _lastAuctionsHash) {
                  _lastAuctionsHash = currentHash;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      try {
                        _applyFilters();
                      } catch (e) {
                        print('❌ Error in post-frame filter application: $e');
                      }
                    }
                  });
                }
              } catch (e) {
                print('❌ Error calculating auctions hash: $e');
                // Continue anyway - filters will be applied on next build
              }
            }

            return CustomScrollView(
              slivers: [
                // Minimal Header
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A1A1A),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    children: [
                      const Text(
                        'Auctions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appState.loadingAuctions)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  actions: [
                    if (appState.isFeatureEnabled('VIPAuctions'))
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diamond, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: () => _handleVipButtonPress(context, appState),
                      ),
                    PopupMenuButton<String>(
                      onSelected: _setSort,
                      icon: const Icon(Icons.sort, color: Color(0xFF1A1A1A)),
                      itemBuilder: (BuildContext context) {
                        return _sortOptions.entries.map((entry) {
                          return PopupMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                if (_currentSort == entry.key)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
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
                    const SizedBox(width: 8),
                  ],
                ),

                // Content
                if (appState.loadingAuctions)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading auctions...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (appState.auctions.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(
                      context,
                      'No Auctions',
                      'No auctions available at the moment.\nPull down to refresh.',
                      Icons.gavel_outlined,
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Filter bar
                        _buildScrollableFilterBar(),

                        // Auctions content
                        Builder(
                          builder: (context) {
                            print('🔨 Builder building auctions tables...');
                            try {
                              final result = _buildAuctionsTables(appState);
                              print(
                                '✅ Builder got result from _buildAuctionsTables',
                              );
                              return result;
                            } catch (e, stackTrace) {
                              print('❌ Error building auctions tables: $e');
                              print('Stack trace: $stackTrace');
                              return Container(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Error displaying auctions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        e.toString(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          } catch (e, stackTrace) {
            print('❌ CRITICAL ERROR in AuctionsPage build: $e');
            print('   Error type: ${e.runtimeType}');
            print('   Stack trace: $stackTrace');
            print('   AppState auctions length: ${appState.auctions.length}');
            print('   Loading state: ${appState.loadingAuctions}');
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A1A1A),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Auctions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading auctions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Error: ${e.toString()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            appState.loadAuctions();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry Loading'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final appState = context.read<AppState>();
                            appState.loadAuctions();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildScrollableFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('Clear All', 'clear', {}),
            const SizedBox(width: 8),
            _buildFilterButton('Type', 'type', _typeOptions),
            const SizedBox(width: 8),
            _buildFilterButton('Price', 'priceRange', _priceRangeOptions),
            const SizedBox(width: 8),
            _buildFilterButton('Bids', 'bidCount', _bidCountOptions),
            const SizedBox(width: 8),
            _buildFilterButton('Project', 'project', _projectOptions),
            const SizedBox(width: 8),
            _buildFilterButton('Location', 'location', _locationOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsTables(AppState appState) {
    try {
      print(
        '_buildAuctionsTables - appState.auctions: ${appState.auctions.length}, _filteredAuctions: ${_filteredAuctions.length}',
      );

      // Safety check: filter out any invalid auctions
      final validAuctions = appState.auctions.where((auction) {
        try {
          // Validate auction has required properties
          final _ = auction.auctionId;
          final _ = auction.propertyId;
          final _ = auction.currentPrice;
          final _ = auction.bidCount;
          final _ = auction.startAt;
          return true;
        } catch (e) {
          print('⚠️ Invalid auction detected in _buildAuctionsTables: $e');
          return false;
        }
      }).toList();

      final auctionsToShow = _filteredAuctions.isEmpty
          ? validAuctions
          : _filteredAuctions.where((auction) {
              try {
                final _ = auction.auctionId;
                return true;
              } catch (e) {
                return false;
              }
            }).toList();

      // Separate upcoming, live and ended auctions
      final now = DateTime.now();

      final upcomingAuctions = auctionsToShow.where((auction) {
        try {
          return auction.status == 'Active' && now.isBefore(auction.startAt);
        } catch (e) {
          print('⚠️ Error checking if auction is upcoming: $e');
          return false;
        }
      }).toList();

      final liveAuctions = auctionsToShow.where((auction) {
        try {
          return auction.isActive &&
              auction.status != 'Ended' &&
              now.isAfter(auction.startAt) &&
              !now.isAfter(auction.endAt);
        } catch (e) {
          print('⚠️ Error checking if auction is live: $e');
          return false;
        }
      }).toList();

      final endedAuctions = auctionsToShow.where((auction) {
        try {
          return auction.isEnded ||
              auction.status == 'Ended' ||
              now.isAfter(auction.endAt);
        } catch (e) {
          print('⚠️ Error checking if auction is ended: $e');
          return false;
        }
      }).toList();

      print(
        'Auctions separation - Total: ${auctionsToShow.length}, Upcoming: ${upcomingAuctions.length}, Live: ${liveAuctions.length}, Ended: ${endedAuctions.length}',
      );

      // Debug each auction (with error handling)
      for (var auction in auctionsToShow) {
        try {
          print(
            'Auction ${auction.auctionId}: status=${auction.status}, endAt=${auction.endAt}, isActive=${auction.isActive}, isEnded=${auction.isEnded}',
          );
          print('  - Current time: ${DateTime.now()}');
          print('  - End time: ${auction.endAt}');
          print(
            '  - Time difference: ${auction.endAt.difference(DateTime.now()).inMinutes} minutes',
          );
        } catch (e) {
          print('⚠️ Error debugging auction: $e');
        }
      }

      print('✅ _buildAuctionsTables returning widget tree');
      print(
        '   Upcoming: ${upcomingAuctions.length}, Live: ${liveAuctions.length}, Ended: ${endedAuctions.length}',
      );

      // Debug: Add a visible test container to verify rendering
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debug test widget
            Container(
              height: 50,
              color: Colors.red.withOpacity(0.3),
              child: Center(
                child: Text(
                  'DEBUG: Auctions Table Builder - Live: ${liveAuctions.length}, Ended: ${endedAuctions.length}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Upcoming Auctions Section
            if (upcomingAuctions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${upcomingAuctions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildAuctionsTable(
                context,
                upcomingAuctions,
                isLive: false,
                isUpcoming: true,
              ),
              const SizedBox(height: 32),
            ],

            // Live Auctions Section
            if (liveAuctions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${liveAuctions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildAuctionsTable(
                context,
                liveAuctions,
                isLive: true,
                isUpcoming: false,
              ),
              const SizedBox(height: 32),
            ],

            // Ended Auctions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Ended',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${endedAuctions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
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
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Ended Auctions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for completed auctions',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

            const SizedBox(height: 100),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR in _buildAuctionsTables: $e');
      print('   Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error displaying auctions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${e.toString()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  appState.loadAuctions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAuctionsTable(
    BuildContext context,
    List<Auction> auctions, {
    required bool isLive,
    bool isUpcoming = false,
  }) {
    print(
      '🔨 _buildAuctionsTable called - auctions: ${auctions.length}, isLive: $isLive, isUpcoming: $isUpcoming',
    );

    if (auctions.isEmpty) {
      print(
        '⚠️ _buildAuctionsTable: auctions list is empty, returning SizedBox.shrink()',
      );
      return const SizedBox.shrink();
    }

    Color headerColor = Colors.grey[50]!;

    // Calculate dynamic height based on actual auction count (max 5)
    final displayCount = auctions.length > 5 ? 5 : auctions.length;
    final dynamicHeight =
        displayCount * 60.0 + 48.0; // rows × 60px + header height

    print(
      '✅ _buildAuctionsTable: Building table with height: $dynamicHeight, displayCount: $displayCount',
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Container(
        height: dynamicHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sticky Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60, // Fixed width for property image
                        child: Text(
                          'Image',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140, // Fixed width for property name
                        child: Text(
                          'Property',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90, // Fixed width for start price
                        child: Text(
                          'Start Price',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100, // Fixed width for current price
                        child: Text(
                          'Current Price',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110, // Cash to close column
                        child: Text(
                          'Cash to Close',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50, // Fixed width for bids
                        child: Text(
                          'Bids',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100, // Fixed width for type
                        child: Text(
                          'Type',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70, // Master plan/docs shortcut
                        child: Text(
                          'Docs',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 85, // Fixed width for time left
                            child: Text(
                              isUpcoming
                                  ? 'Starts In'
                                  : (isLive ? 'Time Left' : 'Ended'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
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
    final isHighlighted = _isAuctionHighlighted(auction.auctionId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.yellow.withOpacity(0.15) // Light yellow highlight
            : AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.background),
          left: isHighlighted
              ? BorderSide(
                  color: Colors.amber,
                  width: 4,
                ) // Amber left border when highlighted
              : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              // Property Image/Carousel
              SizedBox(
                width: 60, // Fixed width for property image
                child: Stack(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: PropertyImageCarousel(
                        images: auction.property?.propertyImages ?? [],
                        fallbackImageUrl: auction.property?.imageUrl,
                        height: 40,
                        showIndicators: false,
                        showNavigationButtons: false,
                        showImageCounter: false,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // "Recently Updated" indicator
                    if (_recentlyUpdatedAuctions.containsKey(auction.auctionId))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.fiber_new,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140, // Fixed width for property name
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auction.property?.name ?? 'Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auction.property?.project ?? 'N/A',
                      style: TextStyle(color: AppColors.primary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90, // Fixed width for start price
                child: Text(
                  _formatCurrency(auction.startPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100, // Fixed width for current price
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatCurrency(auction.currentPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? Colors.green[700]
                            : AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'NEW BID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Text(
                  _formatCurrency(_resolveCashToClose(auction)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50, // Fixed width for bids
                child: Text(
                  '${auction.bidCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100, // Fixed width for type
                child: _buildPropertyTypeTag(auction.property?.listingType),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 70, child: _buildDocsCell(auction)),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 85, // Fixed width for time left/ended
                    child: isUpcoming
                        ? _buildStartsInWidget(auction)
                        : (isLive
                              ? AuctionTimer(
                                  auction: auction,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                  onAuctionEnded: onAuctionEnded,
                                )
                              : Text(
                                  'Ended',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                )),
                  ),
                ),
              ),
            ],
          ),
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
        fontSize: 10,
      ),
    );
  }

  Widget _buildDocsCell(Auction auction) {
    final masterPlanUrl = _getMasterPlanUrl(auction);
    if (masterPlanUrl == null) {
      return const Center(
        child: Text('—', style: TextStyle(color: Colors.grey, fontSize: 11)),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _openMasterPlanForAuction(auction),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.map_outlined, size: 14),
        label: const Text(
          'View',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  double? _resolveCashToClose(Auction auction) {
    final explicit = auction.cashToClose;
    if (explicit != null && explicit > 0) {
      return explicit;
    }
    final summary = auction.property?.installmentSummary;
    if (summary == null) return null;
    if (summary.remainingBalance > 0) return summary.remainingBalance;
    if (summary.isFullyPaid) return 0;
    return null;
  }

  String _formatCurrency(double? value) {
    if (value == null) return '--';
    final amount = value.abs();
    String formatted;
    if (amount >= 1000000) {
      formatted = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      formatted = '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      formatted = amount.toStringAsFixed(0);
    }
    final prefix = value < 0 ? '- ' : '';
    return '${prefix}EGP $formatted';
  }

  String? _getMasterPlanUrl(Auction auction) {
    final direct = auction.masterPlanUrl;
    if (direct != null && direct.isNotEmpty) return direct;
    final docs = auction.property?.propertyDocs;
    if (docs == null || docs.isEmpty) return null;

    PropertyDoc? exact;
    try {
      exact = docs.firstWhere(
        (doc) => _isMasterPlanType(doc.docType, strict: true),
      );
    } catch (_) {
      exact = null;
    }
    if (exact != null && exact.imgUrl.isNotEmpty) {
      return exact.imgUrl;
    }

    PropertyDoc? fallback;
    try {
      fallback = docs.firstWhere((doc) => _isMasterPlanType(doc.docType));
    } catch (_) {
      fallback = null;
    }

    return fallback?.imgUrl;
  }

  bool _isMasterPlanType(String? docType, {bool strict = false}) {
    if (docType == null) return false;
    final normalized = docType.toLowerCase();
    if (strict) {
      return normalized == 'master plan' ||
          normalized == 'masterplan' ||
          normalized == 'master-plan';
    }
    return normalized.contains('master') ||
        normalized.contains('plan') ||
        normalized.contains('layout') ||
        normalized.contains('site');
  }

  Future<void> _openMasterPlanForAuction(Auction auction) async {
    final url = _getMasterPlanUrl(auction);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No master plan available for this property yet.'),
        ),
      );
      return;
    }

    final size = MediaQuery.of(context).size;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.6,
                    width: size.width * 0.9,
                    child: InteractiveViewer(
                      minScale: 0.9,
                      maxScale: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Unable to load master plan image.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Master Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
      return GestureDetector(
        onTap: _clearAllFilters,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
        ),
      );
    }

    final currentValue = _activeFilters[filterKey] ?? 'all';
    final currentLabel = options[currentValue] ?? 'All';
    final hasFilter = currentValue != 'all';

    return GestureDetector(
      onTap: () => _showFilterMenu(filterKey, options),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasFilter
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasFilter ? AppColors.primary : Colors.grey[700],
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: AppColors.primary),
            ],
          ],
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

  Widget _buildPropertyTypeTag(ListingType? listingType) {
    if (listingType == null) {
      return const SizedBox.shrink();
    }

    final isPrimary = listingType == ListingType.primary;
    final backgroundColor = isPrimary
        ? AppColors.primary.withOpacity(0.1)
        : Colors.purple.withOpacity(0.1);
    final borderColor = isPrimary
        ? AppColors.primary.withOpacity(0.3)
        : Colors.purple.withOpacity(0.3);
    final textColor = isPrimary ? AppColors.primary : Colors.purple[700]!;
    final text = isPrimary ? 'Primary' : 'Resale';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.new_releases : Icons.recycling,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _handleVipButtonPress(BuildContext context, AppState appState) {
    if (appState.user == null) return;

    final totalEarnedPoints = appState.user!.totalEarnedPoints ?? 0;
    const vipThreshold = 5000;

    if (totalEarnedPoints >= vipThreshold) {
      // User is VIP - navigate to VIP auctions page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VipAuctionsPage()),
      );
    } else {
      // User is not VIP - show VIP requirements dialog
      _showVipRequirementsDialog(context, totalEarnedPoints, vipThreshold);
    }
  }

  void _showVipRequirementsDialog(
    BuildContext context,
    int currentPoints,
    int vipThreshold,
  ) {
    final pointsNeeded = vipThreshold - currentPoints;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.diamond, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('VIP Membership Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock exclusive VIP auctions with premium properties and special features!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.purple[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Points:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '$currentPoints pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VIP Threshold:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '$vipThreshold pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pointsNeeded > 0
                          ? Colors.orange[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pointsNeeded > 0
                              ? Icons.trending_up
                              : Icons.check_circle,
                          color: pointsNeeded > 0
                              ? Colors.orange[700]
                              : Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pointsNeeded > 0
                                ? 'You need $pointsNeeded more points to become VIP'
                                : 'Congratulations! You are VIP!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: pointsNeeded > 0
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Earn points by:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...[
              'Viewing properties',
              'Placing bids',
              'Adding properties',
              'Creating events',
            ].map(
              (activity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 8),
                    Text(
                      activity,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (pointsNeeded > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/rewards');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Earn Points'),
            ),
        ],
      ),
    );
  }
}
