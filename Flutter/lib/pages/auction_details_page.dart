import '../../theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/property.dart';
import '../models/bid.dart';
import '../services/bid_service.dart';
import '../services/auction_service.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/auction_timer.dart';
import '../widgets/property_image_carousel.dart';
import '../widgets/reward_popup.dart';
import '../models/installment_summary.dart';
import '../models/property_doc.dart';
import '../widgets/country_flag.dart';
import 'property_details_page.dart';
import 'project_details_page.dart';
import 'developer_profile_page.dart';

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
  MarketOverviewResponse? _marketOverview;
  List<BestInvestmentResponse>? _bestInvestments;

  InstallmentSummary? get _installmentSummary =>
      _currentAuction?.property?.installmentSummary;

  double? get _cashToClose {
    final explicit = _currentAuction?.cashToClose;
    if (explicit != null && explicit > 0) {
      return explicit;
    }
    final summary = _installmentSummary;
    if (summary == null) return null;
    if (summary.remainingBalance <= 0) return null;
    return summary.remainingBalance;
  }

  bool get _hasFinancialSummary {
    if (_installmentSummary != null) return true;
    if (_cashToClose != null) return true;
    if (_getMasterPlanUrl() != null) return true;
    return false;
  }

  String? _getMasterPlanUrl() {
    final direct = _currentAuction?.masterPlanUrl;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final docs = _currentAuction?.property?.propertyDocs;
    if (docs == null || docs.isEmpty) return null;

    PropertyDoc? exactPlan;
    try {
      exactPlan =
          docs.firstWhere((doc) => _isMasterPlanType(doc.docType, strict: true));
    } catch (_) {
      exactPlan = null;
    }

    if (exactPlan != null && exactPlan.imgUrl.isNotEmpty) {
      return exactPlan.imgUrl;
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

  Future<void> _openMasterPlan([String? url]) async {
    final planUrl = url ?? _getMasterPlanUrl();
    if (planUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master plan is not available for this property yet.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final size = MediaQuery.of(context).size;
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
                          planUrl,
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

  Auction? _currentAuction;
  double? _previousPrice; // Track previous price to detect changes

  // Audio player for bid notification sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Firestore real-time listeners
  StreamSubscription<Auction?>? _auctionSubscription;
  StreamSubscription<List<Bid>>? _bidsSubscription;

  // Fallback polling (backup only)
  Timer? _fallbackTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
    _previousPrice =
        widget.auction.currentPrice; // Initialize with current price
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
    // Load initial data from API first, then start Firestore listeners
    _loadBids().then((_) {
      // Only start Firestore listeners after initial data is loaded
      // This gives the backend time to sync data to Firestore
      Future.delayed(const Duration(milliseconds: 500), () {
        _startFirestoreListeners();
      });
    });
    // Load market data for strategies
    _loadMarketData();
    // Start fallback polling as backup (less frequent)
    _startFallbackPolling();
  }

  Future<void> _loadMarketData() async {
    if (_currentAuction?.property == null) return;
    
    try {
      // Load market data in parallel
      final results = await Future.wait([
        AnalyticsService.getMarketOverview().catchError((e) => null),
        AnalyticsService.getBestInvestments(limit: 10).catchError((e) => null),
      ]);

      if (!mounted) return;

      setState(() {
        _marketOverview = results[0] as MarketOverviewResponse?;
        _bestInvestments = results[1] as List<BestInvestmentResponse>?;
      });
    } catch (e) {
      print('Error loading market data: $e');
      // Don't show error, just silently fail - market data is optional
    }
  }

  /// Start Firestore real-time listeners for instant updates
  void _startFirestoreListeners() {
    print(
      '🔥 Starting Firestore listeners for auction ${_currentAuction!.auctionId}',
    );

    // Listen to auction updates in real-time
    _auctionSubscription =
        FirestoreService.listenToAuction(_currentAuction!.auctionId).listen(
          (auction) {
            if (auction != null && mounted) {
              print(
                '🔥 Firestore: Auction updated - Price: \$${auction.currentPrice}, Bids: ${auction.bidCount}',
              );

              // Check if price changed and play sound
              if (_previousPrice != null &&
                  auction.currentPrice != _previousPrice) {
                print('🔔 New bid detected! Playing notification sound...');
                _playBidNotificationSound();
              }

              setState(() {
                _currentAuction = auction;
                _previousPrice = auction.currentPrice; // Update previous price
              });
            }
            // Null auction updates are normal when document doesn't exist yet
            // The auto-sync will create it after the first API call
          },
          onError: (error) {
            print('❌ Firestore auction listener error: $error');
          },
        );

    // Listen to bids in real-time
    _bidsSubscription =
        FirestoreService.listenToAuctionBids(_currentAuction!.auctionId).listen(
          (bids) {
            if (mounted) {
              print('🔥 Firestore: Received ${bids.length} bids');
              
              // If Firebase returns 0 bids, verify with database to ensure
              // there wasn't an error storing them in Firebase
              if (bids.isEmpty) {
                print('⚠️ Firebase returned 0 bids, verifying with database...');
                _verifyBidsWithDatabase();
              } else {
                setState(() {
                  _bids = bids;
                });
              }
            }
          },
          onError: (error) {
            print('❌ Firestore bids listener error: $error');
          },
        );
  }

  /// Play notification sound when a new bid is placed
  Future<void> _playBidNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/bid_notification.mp3'));
      print('✅ Notification sound played');
    } catch (e) {
      print('⚠️ Error playing notification sound: $e');
      // Don't throw error, just log it - sound is not critical
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    _fallbackTimer?.cancel();
    _auctionSubscription?.cancel();
    _bidsSubscription?.cancel();
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

  /// Verify bids with database when Firebase returns 0 bids
  /// This ensures we catch cases where bids exist in database but weren't synced to Firebase
  Future<void> _verifyBidsWithDatabase() async {
    try {
      print('🔍 Verifying bids with database for auction ${_currentAuction!.auctionId}');
      final response = await BidService.getBids(_currentAuction!.auctionId);
      
      if (response.success && response.data != null) {
        final dbBidCount = response.data!.length;
        print('📊 Database has $dbBidCount bids');
        
        if (dbBidCount > 0) {
          // Database has bids but Firebase returned 0 - use database data
          print('⚠️ Database has $dbBidCount bids but Firebase returned 0. Using database data.');
          if (mounted) {
            setState(() {
              _bids = response.data!;
            });
          }
        } else {
          // Database also has 0 bids - Firebase is correct
          print('✅ Database confirms: 0 bids (Firebase was correct)');
          if (mounted) {
            setState(() {
              _bids = [];
            });
          }
        }
      } else {
        print('⚠️ Could not verify bids with database: ${response.error}');
        // Keep Firebase result (empty) if database check fails
        if (mounted) {
          setState(() {
            _bids = [];
          });
        }
      }
    } catch (e) {
      print('❌ Error verifying bids with database: $e');
      // Keep Firebase result (empty) if database check fails
      if (mounted) {
        setState(() {
          _bids = [];
        });
      }
    }
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

    // Reduced frequency since we have real-time Firestore updates
    print('Starting fallback polling every 5 minutes (backup)');
    _fallbackTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
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
        // Show reward popup after successful bid
        if (mounted &&
            context.read<AppState>().user?.totalEarnedPoints != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RewardPopup(
                pointsAwarded: 5,
                totalPoints: context.read<AppState>().user!.totalEarnedPoints!,
              ),
            );
          }
        }
        // Reload data to show new bid
        _loadBids();

        // Refresh global auctions list so auctions page gets updated data
        final appState = context.read<AppState>();
        appState.loadAuctions();
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
                    color: AppColors.primary,
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bid responsibly and only if you\'re committed to completing the purchase.',
                            style: TextStyle(
                              color: AppColors.primary,
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
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      color: AppColors.surface,
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
              color: AppColors.textPrimary,
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
                _buildNavigationButtons(),
                if (_hasFinancialSummary) _buildFinancialSummary(),
                _buildPropertyDetails(),
                _buildBiddingSection(),
                _buildLeaderboard(),
                _buildChartsSection(),
                _buildMarketStrategiesAndPricing(),
                _buildPropertyDescription(),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        if (_getMasterPlanUrl() != null)
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: TextButton.icon(
              onPressed: () => _openMasterPlan(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text(
                'Master Plan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Property Image Carousel
            PropertyImageCarousel(
              images: _currentAuction!.property?.propertyImages ?? [],
              fallbackImageUrl: _currentAuction!.property?.imageUrl,
              height: 250,
              showIndicators: true,
              showNavigationButtons: true,
              showImageCounter: true,
              borderRadius: BorderRadius.zero,
            ),

            // Gradient Overlay (IgnorePointer allows touch to pass through)
            IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.textPrimary],
                  ),
                ),
              ),
            ),

            // Property Info (IgnorePointer allows swipes to pass through)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAuction!.property?.name ?? 'Property',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Country Flag
                        CountryFlag(
                          countryCode: CountryFlag.extractCountryCodeFromLocation(
                            _currentAuction!.property?.location,
                          ),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _currentAuction!.property?.location ?? '',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _currentAuction!.isUpcoming
                            ? Colors.blue
                            : (_currentAuction!.isActive
                                  ? Colors.green
                                  : Colors.orange),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentAuction!.isUpcoming
                            ? 'NOT STARTED'
                            : (_currentAuction!.isActive
                                  ? 'LIVE AUCTION'
                                  : 'ENDED'),
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentAuction == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final property = _currentAuction!.property;
    final propertyId = _currentAuction!.propertyId;
    final projectId = property?.projectId;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Navigation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Property Details Button
                _buildNavigationButton(
                  icon: Icons.home,
                  label: 'Property Details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailsPage(
                          propertyId: propertyId,
                        ),
                      ),
                    );
                  },
                ),
                // Project Details Button (if project exists)
                if (projectId != null && projectId.isNotEmpty)
                  _buildNavigationButton(
                    icon: Icons.business,
                    label: 'Project',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsPage(
                            projectId: projectId,
                          ),
                        ),
                      );
                    },
                  ),
                // Developer Profile Button (if project exists, we'll get developer from project)
                if (projectId != null && projectId.isNotEmpty)
                  _buildNavigationButton(
                    icon: Icons.person,
                    label: 'Developer',
                    onTap: () async {
                      // Fetch project to get developer ID
                      try {
                        final projectService = ProjectService(ApiClient.baseUrl);
                        final project = await projectService.getProjectDetails(projectId);
                        if (mounted && project.developerId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeveloperProfilePage(
                                developerId: project.developerId,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to load developer: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _installmentSummary;
    final cashToClose = _cashToClose ?? summary?.remainingBalance;
    final textTheme = Theme.of(context).textTheme;

    final String cashHeadline;
    final String cashSubtitle;
    if (cashToClose != null) {
      cashHeadline = _formatCurrency(cashToClose);
      cashSubtitle = 'Remaining balance after recorded payments';
    } else {
      cashHeadline = 'Cash to close not provided';
      cashSubtitle =
          'Financing details haven\'t been shared yet. Ask the seller to add contract and payment data so bidders know what\'s outstanding.';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financing & Cash to Close',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash to Close',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cashHeadline,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cashSubtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (summary != null)
                  ..._buildSummaryDetailWidgets(summary, textTheme)
                else ...[
                  Text(
                    'Financial summary not yet shared for this property.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encourage the seller or developer to add the contract price, paid-to-date amount, and payment schedule so bidders can see the remaining exposure.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_getMasterPlanUrl() != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openMasterPlan(),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Master Plan'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetails() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildPropertyTypeTag(
                              _currentAuction!.property!.listingType,
                            ),
                          ],
                        ),
                      ),
                    ],
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
            color: AppColors.primary,
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

  Widget _buildFinancialMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSummaryDetailWidgets(
    InstallmentSummary summary,
    TextTheme textTheme,
  ) {
    final endDate = summary.installmentEndDate;

    return [
      Row(
        children: [
          _buildFinancialMetric(
            label: 'Contract Price',
            value: _formatCurrency(summary.contractedPrice),
            icon: Icons.description_outlined,
            iconColor: Colors.blueAccent,
          ),
          const SizedBox(width: 12),
          _buildFinancialMetric(
            label: 'Total Paid',
            value: _formatCurrency(summary.totalPaid),
            icon: Icons.payments_outlined,
            iconColor: Colors.green,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _buildFinancialMetric(
            label: 'Down Payment',
            value:
                '${_formatCurrency(summary.downPaymentAmount)} (${_formatPercent(summary.downPaymentPercent)})',
            icon: Icons.savings_outlined,
            iconColor: Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildFinancialMetric(
            label: 'Balance Outstanding',
            value: _formatCurrency(summary.remainingBalance),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.deepPurple,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (summary.termYears != null && summary.termYears! > 0)
            _buildInfoChip(
              icon: Icons.schedule_outlined,
              label: '${summary.termYears} year plan',
            ),
          if (endDate != null)
            _buildInfoChip(
              icon: Icons.event_outlined,
              label: 'Ends ${endDate.year}',
            ),
          _buildInfoChip(
            icon: summary.isFullyPaid ? Icons.verified : Icons.timelapse,
            label: summary.isFullyPaid ? 'Fully paid' : 'Outstanding',
            color: summary.isFullyPaid ? Colors.green : Colors.orange,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Installment events added via calendar scans update these figures automatically so bidders always see fresh financials.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: chipColor.withOpacity(0.3)),
      ),
      backgroundColor: chipColor.withOpacity(0.08),
    );
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

  String _formatPercent(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
  }

  Widget _buildBiddingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentAuction!.bidCount} bids',
                        style: const TextStyle(
                          color: AppColors.primary,
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
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Starting Price: \$${_currentAuction!.startPrice.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                  ),
                ),

                Consumer<AppState>(
                  builder: (context, appState, child) {
                    // Only show buy now button if user is logged in, verified, active auction
                    if (!appState.isLoggedIn ||
                        !appState.user!.isVerified ||
                        !_currentAuction!.isActive) {
                      return const SizedBox.shrink();
                    }

                    // Check if user owns this property
                    final userOwnsProperty = appState.userProperties.any(
                      (property) =>
                          property.propertyId == _currentAuction!.propertyId,
                    );

                    if (userOwnsProperty) {
                      return const SizedBox.shrink();
                    }

                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 24),

                // Time remaining
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentAuction!.isUpcoming
                        ? AppColors.background
                        : (_currentAuction!.isActive
                              ? AppColors.background
                              : AppColors.background),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentAuction!.isUpcoming
                          ? AppColors.secondary
                          : (_currentAuction!.isActive
                                ? AppColors.secondary
                                : AppColors.secondary),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _currentAuction!.isUpcoming
                            ? AppColors.primary
                            : (_currentAuction!.isActive
                                  ? AppColors.primary
                                  : AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      _currentAuction!.isUpcoming
                          ? Row(
                              children: [
                                Text(
                                  'Starts in ',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _currentAuction!.timeRemaining,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : (_currentAuction!.isActive
                                ? Row(
                                    children: [
                                      Text(
                                        'Ends in ',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      AuctionTimer(
                                        auction: _currentAuction!,
                                        textStyle: TextStyle(
                                          color: AppColors.primary,
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
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  )),
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
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),

                  // Check if user is logged in
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      if (!appState.isLoggedIn) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Login to place a bid',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need to be logged in to participate in this auction',
                                style: TextStyle(
                                  color: AppColors.primary,
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Account Not Verified',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need to verify your account to place bids. Please upload your verification documents from your profile.',
                                style: TextStyle(
                                  color: AppColors.primary,
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
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.surface,
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.block,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cannot bid on your own property',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You cannot place bids on properties you own',
                                style: TextStyle(
                                  color: AppColors.primary,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bidding Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

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
            return FlLine(color: AppColors.secondary, strokeWidth: 1);
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
                    color: AppColors.primary,
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
                      color: AppColors.primary,
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
            bottom: BorderSide(color: AppColors.secondary, width: 1),
            left: BorderSide(color: AppColors.secondary, width: 1),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '\$${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: AppColors.surface,
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
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Bidders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

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
    final Map<String, Bid> topBids = {};
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
          return AppColors.secondary;
        case 3:
          return AppColors.primary;
        default:
          return AppColors.secondary;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: position <= 3
            ? getPositionColor(position).withOpacity(0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: position <= 3
              ? getPositionColor(position)
              : AppColors.background,
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
                  color: AppColors.surface,
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
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${bid.bidAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
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
          Icon(icon, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
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
    final baseName = (firstName != null && firstName.isNotEmpty)
        ? '$firstName $lastName'
        : 'Bidder #${bid.bidderId}';
    // Append top badge icon if available (from API's bidder payload)
    try {
      final dynamic raw = (bid.toJson()['bidder']);
      final String? topIcon = raw != null
          ? raw['TopBadgeIcon'] ?? raw['topBadgeIcon']
          : null;
      if (topIcon != null && topIcon.isNotEmpty) {
        return '$baseName  $topIcon';
      }
    } catch (_) {}
    return baseName;
  }

  Widget _buildMarketStrategiesAndPricing() {
    final property = _currentAuction?.property;
    if (property == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final currentPrice = _currentAuction!.currentPrice;
    final startPrice = _currentAuction!.startPrice;
    final priceIncrease = currentPrice - startPrice;
    final priceIncreasePercent = startPrice > 0 ? (priceIncrease / startPrice * 100).toDouble() : 0.0;
    final pricePerSqft = property.squareFeet > 0 ? (currentPrice / property.squareFeet).toDouble() : 0.0;
    final timeRemaining = _currentAuction!.endAt.difference(DateTime.now());
    final isActive = _currentAuction!.isActive;
    final bidCount = _currentAuction!.bidCount;

    // Get real market data for comparison
    double? marketAvgPrice;
    double? marketAvgPricePerSqft;
    
    if (_marketOverview != null && _marketOverview!.areaPrices.isNotEmpty) {
      // Find matching area or use overall average
      final matchingArea = _marketOverview!.areaPrices.firstWhere(
        (ap) => ap.area.toLowerCase().contains(property.location.toLowerCase()) ||
                property.location.toLowerCase().contains(ap.area.toLowerCase()),
        orElse: () => _marketOverview!.areaPrices.first,
      );
      marketAvgPrice = matchingArea.averagePrice;
    }
    
    if (_bestInvestments != null && _bestInvestments!.isNotEmpty) {
      // Find similar properties in best investments
      final propertyTypeLabel = property.typeLabel;
      final similarProperties = _bestInvestments!.where((inv) =>
        inv.propertyType.toLowerCase() == propertyTypeLabel.toLowerCase() ||
        inv.location.toLowerCase().contains(property.location.toLowerCase())
      ).toList();
      
      if (similarProperties.isNotEmpty) {
        marketAvgPricePerSqft = similarProperties
            .map((inv) => inv.pricePerSqm)
            .reduce((a, b) => a + b) / similarProperties.length;
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market Strategies Card
            Card(
              elevation: 3,
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Market Strategies & Insights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Pricing Analysis
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pricing Analysis',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPricingMetric(
                                  'Current Bid',
                                  _formatCurrency(currentPrice),
                                  Icons.price_check,
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPricingMetric(
                                  'Price/Sqft',
                                  _formatCurrency(pricePerSqft),
                                  Icons.square_foot,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPricingMetric(
                                  'From Start',
                                  '${priceIncreasePercent.toStringAsFixed(1)}%',
                                  priceIncreasePercent >= 0 
                                      ? Icons.trending_up 
                                      : Icons.trending_down,
                                  priceIncreasePercent >= 0 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPricingMetric(
                                  'Total Bids',
                                  '$bidCount',
                                  Icons.gavel,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bidding Strategies
                    const Text(
                      'Bidding Strategies',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStrategyTip(
                      Icons.timer,
                      'Timing Strategy',
                      isActive && timeRemaining.inHours < 2
                          ? 'Last hour bidding! Prices typically increase 15-25% in final hour.'
                          : isActive
                              ? 'Early bidding establishes your presence. Consider strategic bids.'
                              : 'Auction ${_currentAuction!.isEnded ? "ended" : "not started yet"}.',
                      Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildStrategyTip(
                      Icons.psychology,
                      'Smart Bidding',
                      _getSmartBiddingTip(bidCount, currentPrice, marketAvgPrice),
                      Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildStrategyTip(
                      Icons.trending_up,
                      'Market Position',
                      priceIncreasePercent > 20
                          ? 'Strong momentum! Property is gaining value rapidly.'
                          : priceIncreasePercent > 10
                              ? 'Steady growth. Good investment potential.'
                              : 'Early stage. Opportunity for early entry.',
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    // Investment Potential with real market data
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights, color: Colors.purple.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Investment Potential',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getInvestmentPotential(
                              pricePerSqft, 
                              priceIncreasePercent, 
                              bidCount,
                              marketAvgPrice,
                              marketAvgPricePerSqft,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade800,
                              height: 1.4,
                            ),
                          ),
                          if (marketAvgPrice != null && marketAvgPrice > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    currentPrice < marketAvgPrice 
                                        ? Icons.trending_down 
                                        : Icons.trending_up,
                                    size: 16,
                                    color: currentPrice < marketAvgPrice 
                                        ? Colors.green 
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Market avg: ${_formatCurrency(marketAvgPrice)} '
                                      '(${currentPrice < marketAvgPrice ? "Below" : "Above"} market)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTip(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getDarkerColor(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    if (color is MaterialColor) {
      return color[900] ?? color;
    }
    return Color.fromRGBO(
      (color.red * 0.5).round(),
      (color.green * 0.5).round(),
      (color.blue * 0.5).round(),
      1.0,
    );
  }

  String _getSmartBiddingTip(int bidCount, double currentPrice, double? marketAvgPrice) {
    if (marketAvgPrice != null && marketAvgPrice > 0) {
      final priceDiff = ((currentPrice - marketAvgPrice) / marketAvgPrice * 100);
      if (priceDiff < -5) {
        return 'Great value! Current bid is ${priceDiff.abs().toStringAsFixed(1)}% below market average. Strong opportunity.';
      } else if (priceDiff > 10) {
        return 'Premium pricing. Current bid is ${priceDiff.toStringAsFixed(1)}% above market. High demand property.';
      } else {
        return 'Fair market pricing. Aligned with market average. Good investment opportunity.';
      }
    }
    
    // Fallback to bid count analysis
    if (bidCount > 5) {
      return 'High competition detected. Consider bidding above market average if you\'re serious.';
    } else if (bidCount > 2) {
      return 'Moderate competition. You have a good chance with strategic bidding.';
    } else {
      return 'Low competition. Early stage auction with good opportunity.';
    }
  }

  String _getInvestmentPotential(
    double pricePerSqft, 
    double priceIncreasePercent, 
    int bidCount,
    double? marketAvgPrice,
    double? marketAvgPricePerSqft,
  ) {
    // Use real market data for assessment
    if (marketAvgPricePerSqft != null && marketAvgPricePerSqft > 0) {
      final sqftDiff = ((pricePerSqft - marketAvgPricePerSqft) / marketAvgPricePerSqft * 100);
      if (sqftDiff < -10 && priceIncreasePercent > 15 && bidCount > 8) {
        return '🔥 Exceptional value! Price per sqft is ${sqftDiff.abs().toStringAsFixed(1)}% below market with strong momentum. High demand property.';
      } else if (sqftDiff < -5 && priceIncreasePercent > 10) {
        return '✅ Great investment opportunity. Below market pricing with steady growth potential.';
      } else if (sqftDiff > 15) {
        return '💎 Premium property. Above market pricing indicates high-end location/features.';
      }
    }
    
    // Fallback to original logic
    if (pricePerSqft > 0 && priceIncreasePercent > 15 && bidCount > 8) {
      return '🔥 High demand property with strong price appreciation. Competitive bidding expected.';
    } else if (priceIncreasePercent > 10 && bidCount > 5) {
      return '✅ Good investment opportunity with steady growth and moderate competition.';
    } else if (bidCount < 3) {
      return '💡 Early stage auction. Lower competition means better chance to secure at good price.';
    } else {
      return '📊 Moderate investment potential. Monitor bidding activity closely.';
    }
  }

  Widget _buildPropertyDescription() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Property Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: AppColors.textPrimary,
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
            Icon(Icons.home, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Property Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
              property.typeLabel,
              Icons.category,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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
            Icon(Icons.location_on, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Location & Accessibility',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.background),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Country Flag
                  CountryFlag(
                    countryCode: CountryFlag.extractCountryCodeFromLocation(
                      property.location,
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This property is strategically located in a prime area with excellent connectivity to major business districts, shopping centers, and educational institutions. The location offers great potential for both residential and investment purposes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
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
            Icon(Icons.trending_up, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Investment Highlights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
              colors: [AppColors.background, AppColors.background],
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
                  color: AppColors.primary,
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
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlight,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
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

  Widget _buildPropertyTypeTag(ListingType? listingType) {
    final isPrimary = listingType == ListingType.primary;
    final backgroundColor = isPrimary ? Colors.blue[100]! : Colors.purple[100]!;
    final borderColor = isPrimary ? Colors.blue[400]! : Colors.purple[400]!;
    final textColor = isPrimary ? Colors.blue[900]! : Colors.purple[900]!;
    final text = isPrimary ? 'Primary' : 'Resale';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.new_releases : Icons.recycling,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
