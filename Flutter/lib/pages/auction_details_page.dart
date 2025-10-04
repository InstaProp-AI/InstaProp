import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../services/bid_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

class AuctionDetailsPage extends StatefulWidget {
  final Auction auction;

  const AuctionDetailsPage({super.key, required this.auction});

  @override
  State<AuctionDetailsPage> createState() => _AuctionDetailsPageState();
}

class _AuctionDetailsPageState extends State<AuctionDetailsPage>
    with TickerProviderStateMixin {
  final _bidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<Bid> _bids = [];
  bool _isLoadingBids = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadBids();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoadingBids = true;
    });

    try {
      print('Loading bids for auction ID: ${widget.auction.auctionId}');
      final response = await BidService.getBids(widget.auction.auctionId);
      print(
        'Bid response: ${response.success}, data: ${response.data?.length}',
      );
      if (response.success && response.data != null) {
        setState(() {
          _bids = response.data!;
        });
        print('Loaded ${_bids.length} bids');
      } else {
        print('Error loading bids: ${response.error}');
        setState(() {
          _bids = [];
        });
      }
    } catch (e) {
      print('Error loading bids: $e');
      setState(() {
        _bids = [];
      });
    } finally {
      setState(() {
        _isLoadingBids = false;
      });
    }
  }

  Future<void> _placeBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final bidAmount = double.parse(_bidController.text);
      print('Placing bid: $bidAmount for auction: ${widget.auction.auctionId}');

      final response = await BidService.placeBid(
        auctionId: widget.auction.auctionId,
        bidAmount: bidAmount,
      );

      print('Bid response: ${response.success}, error: ${response.error}');

      if (response.success) {
        setState(() {
          _successMessage = 'Bid placed successfully!';
          _bidController.clear();
        });
        _loadBids(); // Refresh bids
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to place bid';
        });
      }
    } catch (e) {
      print('Error placing bid: $e');
      setState(() {
        _errorMessage = 'Error placing bid: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildModernAppBar(),
              _buildPropertyDetails(),
              _buildBiddingSection(),
              _buildBidHistory(),
              _buildChartsSection(),
              _buildLeaderboard(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Property Image
            if (widget.auction.property?.imageUrl.isNotEmpty == true)
              Image.network(
                widget.auction.property!.imageUrl,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.home, size: 100, color: Colors.grey),
              ),

            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),

            // Property Info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.auction.property?.name ?? 'Property',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.auction.property?.location ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.auction.isActive
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.auction.isActive ? 'LIVE AUCTION' : 'ENDED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPropertyDetails() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (widget.auction.property != null) ...[
                  _buildDetailRow(
                    'Description',
                    widget.auction.property!.description,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Bedrooms',
                          '${widget.auction.property!.bedrooms}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Bathrooms',
                          '${widget.auction.property!.bathrooms}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Square Feet',
                          '${widget.auction.property!.squareFeet}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Year Built',
                          '${widget.auction.property!.yearBuilt}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Category',
                    widget.auction.property!.category,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBiddingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Bid',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.auction.bidCount} bids',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    '\$${widget.auction.currentPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Starting Price: \$${widget.auction.startAt.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ),

                if (widget.auction.buyNowPrice != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Buy Now: \$${widget.auction.buyNowPrice!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Time remaining
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.auction.isActive
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.auction.isActive
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: widget.auction.isActive
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.auction.isActive
                            ? 'Ends in ${widget.auction.timeRemaining}'
                            : 'Auction Ended',
                        style: TextStyle(
                          color: widget.auction.isActive
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bidding form
                if (widget.auction.isActive) ...[
                  Text(
                    'Place a Bid',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),

                  // Check if user is logged in
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      if (!appState.isLoggedIn) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.orange[700],
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Login to place a bid',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need to be logged in to participate in this auction',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/auth'),
                                icon: const Icon(Icons.login),
                                label: const Text('Login to Bid'),
                              ),
                            ],
                          ),
                        );
                      }

                      // Logged in user can bid
                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _bidController,
                              labelText: 'Bid Amount',
                              hintText: 'Enter your bid amount',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty == true)
                                  return 'Bid amount is required';
                                final bidAmount = double.tryParse(value!);
                                if (bidAmount == null)
                                  return 'Please enter a valid number';
                                if (bidAmount <= widget.auction.currentPrice) {
                                  return 'Bid must be higher than current price';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            LoadingButton(
                              onPressed: _isLoading ? null : _placeBid,
                              isLoading: _isLoading,
                              child: const Text('Place Bid'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidHistory() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bid History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_isLoadingBids)
                  const Center(child: CircularProgressIndicator())
                else if (_bids.isEmpty)
                  _buildEmptyState(
                    'No Bids Yet',
                    'Be the first to place a bid on this property',
                    Icons.gavel_outlined,
                  )
                else
                  ..._bids.take(10).map((bid) => _buildBidItem(bid)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidItem(Bid bid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: Text(
              _getBidderInitial(bid),
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBidderName(bid),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatDateTime(bid.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${bid.bidAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bidding Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                SizedBox(height: 200, child: _buildBidChart()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidChart() {
    if (_bids.isEmpty) {
      return _buildEmptyState(
        'No Bidding Data',
        'Bid activity will appear here once bids are placed',
        Icons.show_chart,
      );
    }

    // Sort bids by creation time
    final sortedBids = List<Bid>.from(_bids)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedBids.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.bidAmount);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF2E7D32),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2E7D32).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Bidders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_bids.isEmpty)
                  _buildEmptyState(
                    'No Bidders Yet',
                    'Top bidders will appear here once bidding starts',
                    Icons.leaderboard,
                  )
                else
                  ..._getTopBidders().asMap().entries.map((entry) {
                    final index = entry.key;
                    final bid = entry.value;
                    return _buildLeaderboardItem(index + 1, bid);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Bid> _getTopBidders() {
    // Get unique bidders with their highest bids
    final Map<int, Bid> topBids = {};
    for (final bid in _bids) {
      if (!topBids.containsKey(bid.bidderId) ||
          bid.bidAmount > topBids[bid.bidderId]!.bidAmount) {
        topBids[bid.bidderId] = bid;
      }
    }

    // Sort by bid amount and take top 5
    final sortedBids = topBids.values.toList()
      ..sort((a, b) => b.bidAmount.compareTo(a.bidAmount));

    return sortedBids.take(5).toList();
  }

  Widget _buildLeaderboardItem(int position, Bid bid) {
    Color getPositionColor(int pos) {
      switch (pos) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey[400]!;
        case 3:
          return Colors.orange[600]!;
        default:
          return Colors.grey[300]!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: position <= 3
            ? getPositionColor(position).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: position <= 3 ? getPositionColor(position) : Colors.grey[200]!,
          width: position <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: getPositionColor(position),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBidderName(bid),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDateTime(bid.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${bid.bidAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getBidderInitial(Bid bid) {
    final firstName = bid.bidder?.firstName;
    if (firstName != null && firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    return 'B';
  }

  String _getBidderName(Bid bid) {
    final firstName = bid.bidder?.firstName;
    final lastName = bid.bidder?.lastName;
    if (firstName != null && firstName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return 'Bidder #${bid.bidderId}';
  }
}
