import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../services/bid_service.dart';
import '../services/auction_service.dart';
import '../services/websocket_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/auction_timer.dart';

class AuctionDetailsPage extends StatefulWidget {
  final Auction auction;

  const AuctionDetailsPage({super.key, required this.auction});

  @override
  State<AuctionDetailsPage> createState() => _AuctionDetailsPageState();
}

class _AuctionDetailsPageState extends State<AuctionDetailsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _bidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<Bid> _bids = [];

  // Real-time updates
  StreamSubscription<AuctionUpdate>? _auctionUpdateSubscription;
  StreamSubscription<BidUpdate>? _bidUpdateSubscription;
  Auction? _currentAuction;

  // Fallback polling (only if WebSocket fails)
  Timer? _fallbackTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
    WidgetsBinding.instance.addObserver(this);

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
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _animationController.dispose();
    _auctionUpdateSubscription?.cancel();
    _bidUpdateSubscription?.cancel();
    _fallbackTimer?.cancel();
    WebSocketService.instance.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBids() async {
    try {
      print('Loading bids for auction ID: ${_currentAuction!.auctionId}');
      final response = await BidService.getBids(_currentAuction!.auctionId);
      print(
        'Bid response: ${response.success}, data: ${response.data?.length}',
      );
      if (response.success && response.data != null) {
        // Only update if the number of bids changed
        if (response.data!.length != _bids.length) {
          setState(() {
            _bids = response.data!;
          });
          print('Loaded ${_bids.length} bids');
        } else {
          print('No new bids, skipping update');
        }
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
    }
  }

  void _startRealTimeUpdates() {
    // Connect to WebSocket for real-time updates
    WebSocketService.instance.connect(_currentAuction!.auctionId.toString());

    // Listen for auction updates (price, bid count, status changes)
    _auctionUpdateSubscription = WebSocketService.instance.auctionUpdateStream
        .listen(
          (AuctionUpdate update) {
            if (mounted &&
                update.auction.auctionId == _currentAuction!.auctionId) {
              print(
                '🔄 Auction update received: Price=\$${update.auction.currentPrice}, Bids=${update.auction.bidCount}',
              );
              setState(() {
                _currentAuction = update.auction;
              });
            }
          },
          onError: (error) {
            print('Auction update error: $error');
          },
        );

    // Listen for bid updates (new bids)
    _bidUpdateSubscription = WebSocketService.instance.bidUpdateStream.listen(
      (BidUpdate update) {
        if (mounted && update.bid.auctionId == _currentAuction!.auctionId) {
          print('🆕 New bid received: \$${update.bid.bidAmount}');
          // Add new bid to the list and reload to get fresh data
          setState(() {
            _bids.insert(0, update.bid); // Add to beginning for newest first
          });
          // Also reload full bid list to ensure consistency
          _loadBids();
        }
      },
      onError: (error) {
        print('Bid update error: $error');
      },
    );

    // Check if WebSocket connected after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!WebSocketService.instance.isConnected) {
        print('WebSocket failed to connect, starting fallback polling');
        _startFallbackPolling();
      }
    });
  }

  void _refreshAuctionData() {
    // Refresh the auction data when auction ends
    final appState = context.read<AppState>();
    appState.loadAuctions();

    // Also refresh the current auction data
    if (_currentAuction != null) {
      // Find the updated auction in the global list
      final updatedAuction = appState.auctions.firstWhere(
        (auction) => auction.auctionId == _currentAuction!.auctionId,
        orElse: () => _currentAuction!,
      );

      if (mounted) {
        setState(() {
          _currentAuction = updatedAuction;
        });
      }
    }
  }

  void _startFallbackPolling() {
    // Only start fallback if not already running
    if (_fallbackTimer != null) return;

    print('Starting fallback polling every 30 seconds');
    _fallbackTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshAuctionDataFallback();
      }
    });
  }

  Future<void> _refreshAuctionDataFallback() async {
    try {
      final response = await AuctionService.getAuction(
        _currentAuction!.auctionId,
      );
      if (response.success && response.data != null) {
        if (mounted) {
          final newAuction = response.data!;

          // Only update if data actually changed
          bool hasChanges = false;

          if (newAuction.currentPrice != _currentAuction!.currentPrice) {
            hasChanges = true;
          }

          if (newAuction.bidCount != _currentAuction!.bidCount) {
            hasChanges = true;
          }

          if (newAuction.isActive != _currentAuction!.isActive) {
            hasChanges = true;
          }

          if (newAuction.timeRemaining != _currentAuction!.timeRemaining) {
            hasChanges = true;
          }

          if (hasChanges) {
            setState(() {
              _currentAuction = newAuction;
            });

            // Only load bids if bid count changed
            if (newAuction.bidCount != _currentAuction!.bidCount) {
              _loadBids();
            }
          }
        }
      }
    } catch (e) {
      print('Fallback polling error: $e');
    }
  }

  Future<void> _placeBid() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog first
    final confirmed = await _showBidConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final bidAmount = double.parse(_bidController.text);
      print(
        'Placing bid: $bidAmount for auction: ${_currentAuction!.auctionId}',
      );

      final response = await BidService.placeBid(
        auctionId: _currentAuction!.auctionId,
        bidAmount: bidAmount,
        context: context,
      );

      print('Bid response: ${response.success}, error: ${response.error}');

      if (response.success) {
        setState(() {
          _successMessage = 'Bid placed successfully!';
          _bidController.clear();
        });
        // WebSocket will automatically update the UI with new data
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

  Future<bool> _showBidConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text('Confirm Your Bid'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are about to place a bid of \$${_bidController.text}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please note:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildWarningPoint(
                    '• Once placed, bids are binding and cannot be withdrawn.',
                  ),
                  const SizedBox(height: 8),
                  _buildWarningPoint(
                    '• If you win an auction and decide not to proceed with the purchase, your account may face restrictions.',
                  ),
                  const SizedBox(height: 8),
                  _buildWarningPoint(
                    '• Withdrawing from 2 won auctions will result in a 14-day account suspension.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bid responsibly and only if you\'re committed to completing the purchase.',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm Bid',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildWarningPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshAuctionData();
            },
            child: CustomScrollView(
              slivers: [
                _buildModernAppBar(),
                _buildPropertyDetails(),
                _buildBiddingSection(),
                _buildLeaderboard(),
                _buildChartsSection(),
                _buildPropertyDescription(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
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
            if (_currentAuction!.property?.imageUrl.isNotEmpty == true)
              Image.network(
                _currentAuction!.property!.imageUrl,
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
                    _currentAuction!.property?.name ?? 'Property',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAuction!.property?.location ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _currentAuction!.isActive
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentAuction!.isActive ? 'LIVE AUCTION' : 'ENDED',
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

                if (_currentAuction!.property != null) ...[
                  _buildDetailRow(
                    'Description',
                    _currentAuction!.property!.description,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Bedrooms',
                          '${_currentAuction!.property!.bedrooms}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Bathrooms',
                          '${_currentAuction!.property!.bathrooms}',
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
                          '${_currentAuction!.property!.squareFeet}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Year Built',
                          '${_currentAuction!.property!.yearBuilt}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Category',
                    _currentAuction!.property!.category,
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
                        '${_currentAuction!.bidCount} bids',
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
                    '\$${_currentAuction!.currentPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Starting Price: \$${_currentAuction!.startPrice.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ),

                if (_currentAuction!.buyNowPrice != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Buy Now: \$${_currentAuction!.buyNowPrice!.toStringAsFixed(0)}',
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
                    color: _currentAuction!.isActive
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentAuction!.isActive
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _currentAuction!.isActive
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      _currentAuction!.isActive
                          ? Row(
                              children: [
                                Text(
                                  'Ends in ',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                AuctionTimer(
                                  auction: _currentAuction!,
                                  textStyle: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  onAuctionEnded: _refreshAuctionData,
                                ),
                              ],
                            )
                          : Text(
                              'Auction Ended',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bidding form
                if (_currentAuction!.isActive) ...[
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

                      // Check if user is verified
                      if (!appState.user!.isVerified) {
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
                                Icons.verified_user,
                                color: Colors.orange[700],
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Account Not Verified',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need to verify your account to place bids. Please upload your verification documents from your profile.',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/profile'),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Go to Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Check if user owns this property
                      final userOwnsProperty = appState.userProperties.any(
                        (property) =>
                            property.propertyId == _currentAuction!.propertyId,
                      );

                      if (userOwnsProperty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.red[700],
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cannot bid on your own property',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You cannot place bids on properties you own',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Logged in user can bid (and doesn't own the property)
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
                                if (bidAmount <=
                                    _currentAuction!.currentPrice) {
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

    // Calculate min and max values for better chart display
    final minY = 0.0; // Don't go below 0
    final maxY =
        sortedBids.map((b) => b.bidAmount).reduce((a, b) => a > b ? a : b) *
        1.1;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedBids.length) return const Text('');

                final bid = sortedBids[value.toInt()];
                final now = DateTime.now();
                final difference = now.difference(bid.createdAt);

                String timeLabel;
                if (difference.inMinutes < 60) {
                  timeLabel = '${difference.inMinutes}m';
                } else if (difference.inHours < 24) {
                  timeLabel = '${difference.inHours}h';
                } else {
                  timeLabel = '${difference.inDays}d';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF2E7D32),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '\$${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
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

  String _getBidderName(Bid bid) {
    final firstName = bid.bidder?.firstName;
    final lastName = bid.bidder?.lastName;
    if (firstName != null && firstName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return 'Bidder #${bid.bidderId}';
  }

  Widget _buildPropertyDescription() {
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
                  children: [
                    Icon(
                      Icons.description,
                      color: const Color(0xFF2E7D32),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Property Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Property Overview
                _buildDescriptionSection(
                  'Overview',
                  _currentAuction?.property?.description ??
                      'No description available.',
                  Icons.info_outline,
                ),

                const SizedBox(height: 16),

                // Property Details Grid
                _buildPropertyDetailsGrid(),

                const SizedBox(height: 16),

                // Location & Amenities
                _buildLocationSection(),

                const SizedBox(height: 16),

                // Investment Highlights
                _buildInvestmentHighlights(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsGrid() {
    final property = _currentAuction?.property;
    if (property == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.home, size: 20, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              'Property Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildDetailItem('Bedrooms', '${property.bedrooms}', Icons.bed),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Bathrooms',
              '${property.bathrooms}',
              Icons.bathtub,
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Square Feet',
              '${property.squareFeet}',
              Icons.square_foot,
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Year Built',
              '${property.yearBuilt}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Type',
              property.type.toString().split('.').last.toUpperCase(),
              Icons.category,
            ),
            const SizedBox(height: 8),
            _buildDetailItem('Category', property.category, Icons.label),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final property = _currentAuction?.property;
    if (property == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 20, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              'Location & Accessibility',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                property.location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This property is strategically located in a prime area with excellent connectivity to major business districts, shopping centers, and educational institutions. The location offers great potential for both residential and investment purposes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 20, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              'Investment Highlights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why This Property?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              ..._getInvestmentHighlights().map(
                (highlight) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlight,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getInvestmentHighlights() {
    final property = _currentAuction?.property;
    if (property == null) return [];

    List<String> highlights = [
      'Prime location with excellent growth potential',
      'Modern construction with quality finishes',
      'Strong rental yield potential',
      'Close proximity to major amenities and transport links',
      'Verified property with all legal clearances',
    ];

    if (property.isApproved) {
      highlights.insert(0, 'Approved property with complete documentation');
    }

    if (property.bedrooms >= 3) {
      highlights.add(
        'Spacious ${property.bedrooms}-bedroom layout ideal for families',
      );
    }

    if (property.yearBuilt >= 2020) {
      highlights.add('New construction with modern amenities');
    }

    return highlights;
  }
}
