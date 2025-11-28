import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/bid.dart';
import '../models/auction.dart';
import '../services/bid_service.dart';
import 'auction_details_page.dart';
import 'auctions_page.dart';
import 'create_auction_request_dialog.dart';

class AuctionActivityPage extends StatefulWidget {
  const AuctionActivityPage({super.key});

  @override
  State<AuctionActivityPage> createState() => _AuctionActivityPageState();
}

class _AuctionActivityPageState extends State<AuctionActivityPage> {
  List<Bid> _myBids = [];
  bool _loadingBids = true;
  bool _showAllPositions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppState>().isLoggedIn) {
        _loadMyBids();
      }
    });
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
      backgroundColor: AppColors.background,
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

  Widget _buildNotLoggedInContent(BuildContext context, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'Auction Activity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please log in to view your auction activity',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to login or handle authentication
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppState appState) {
    return CustomScrollView(
      slivers: [
        // Minimal Clean Header
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: Colors.white),
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: const Text(
              'Auction Activity',
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

              // Your Positions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMyBidsSection(appState),
              ),

              const SizedBox(height: 32),

              // My Auctions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMyAuctionsSection(context, appState),
              ),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyBidsSection(AppState appState) {
    // Group bids by auction and get the latest bid for each auction
    final Map<String, Bid> latestBidsMap = {};
    for (var bid in _myBids) {
      if (bid.auction != null) {
        final auctionId = bid.auction!.auctionId;
        if (!latestBidsMap.containsKey(auctionId) ||
            bid.bidAmount > latestBidsMap[auctionId]!.bidAmount) {
          latestBidsMap[auctionId] = bid;
        }
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
        else
          // Vertical list with inline expansion
          Column(
            children: [
              ...(_showAllPositions ? latestBids : latestBids.take(3)).map(
                (bid) => _buildBidCard(context, bid),
              ),
              if (latestBids.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllPositions = !_showAllPositions;
                      });
                    },
                    child: Text(
                      _showAllPositions
                          ? 'Show Less'
                          : 'View all ${latestBids.length} positions',
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildBidCard(BuildContext context, Bid bid) {
    final auction = bid.auction;
    if (auction == null) return const SizedBox.shrink();

    final property = auction.property;
    if (property == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                  color: auction.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auction.isActive ? 'Live' : 'Ended',
                  style: TextStyle(
                    color: auction.isActive ? Colors.green : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Bid',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${bid.bidAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Current Price',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: bid.bidAmount >= auction.currentPrice
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show bid button if user is outbid and auction is active
          if (bid.bidAmount < auction.currentPrice && auction.isActive) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _placeQuickBid(
                  context,
                  auction,
                  auction.currentPrice + 1000,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Bid \$1000 More'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailsPage(auction: auction),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Auction'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAuctionsSection(BuildContext context, AppState appState) {
    try {
      print('🔄 Building My Auctions Section...');
      final userAuctions = appState.userAuctions;
      print('   User auctions count: ${userAuctions.length}');
      
      // Safety check: filter out any null or invalid auctions
      final validAuctions = userAuctions.where((a) {
        try {
          // Try to access properties that would throw if auction is invalid
          final _ = a.auctionId;
          final _ = a.propertyId;
          final _ = a.currentPrice;
          final _ = a.bidCount;
          return true;
        } catch (e) {
          print('⚠️ Invalid auction detected: $e');
          return false;
        }
      }).toList();
      
      final liveAuctions = validAuctions.where((a) {
        try {
          return a.isActive;
        } catch (e) {
          print('⚠️ Error checking if auction is active: $e');
          return false;
        }
      }).toList();
      
      final endedAuctions = validAuctions.where((a) {
        try {
          return a.isEnded;
        } catch (e) {
          print('⚠️ Error checking if auction is ended: $e');
          return false;
        }
      }).toList();
      
      final requestedAuctions = validAuctions
          .where((a) {
            try {
              return a.status == 'Requested';
            } catch (e) {
              print('⚠️ Error checking auction status: $e');
              return false;
            }
          })
          .toList();
      
      print('   Live: ${liveAuctions.length}, Ended: ${endedAuctions.length}, Requested: ${requestedAuctions.length}');

      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'My Auctions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.7,
                ),
              ),
            ),
            Flexible(
              child: ElevatedButton(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 4),
                    Text('Create'),
                  ],
                ),
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
        if (validAuctions.isEmpty) _buildEmptyAuctionsState(context),
      ],
    );
    } catch (e, stackTrace) {
      print('❌ Error building My Auctions Section: $e');
      print('   Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Error Loading My Auctions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${e.toString()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Reload auctions
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
      );
    }
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

        // Horizontal scrolling cards - show all items
        SizedBox(
          height: 300, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280, // Fixed width for each card
                margin: EdgeInsets.only(
                  right: index < auctions.length - 1 ? 12 : 0,
                ),
                child: _buildAuctionCard(context, auctions[index], color),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionCard(BuildContext context, Auction auction, Color color) {
    final property = auction.property;
    if (property == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auction.isActive ? 'Live' : 'Ended',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Price',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bids',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${auction.bidCount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailsPage(auction: auction),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Auction'),
            ),
          ),
        ],
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
      child: Center(
        child: Column(
          children: [
            Icon(Icons.gavel_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No Auctions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first auction request!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text('Create Auction'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeQuickBid(
    BuildContext context,
    Auction auction,
    double bidAmount,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await BidService.placeBid(
        auctionId: auction.auctionId,
        bidAmount: bidAmount,
        context: context,
      );

      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bid placed successfully! \$${bidAmount.toStringAsFixed(0)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Refresh the bids data
        _loadMyBids();
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to place bid: ${response.error ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing bid: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
