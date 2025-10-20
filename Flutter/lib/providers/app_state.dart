import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/auction_service.dart';
import '../services/property_service.dart';
import '../services/bid_service.dart';
import '../services/notification_service.dart';
import '../services/dashboard_service.dart';
import '../services/firestore_service.dart';
import '../services/api_client.dart';
import '../models/user.dart';
import '../models/auction.dart';
import '../models/property.dart';
import '../models/bid.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  Timer? _fallbackTimer;
  StreamSubscription<List<Auction>>? _auctionsSubscription;

  // Expose notification service
  NotificationService get notificationService => _notificationService;

  // Auth state
  Account? get user => _authService.user;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isLoading => _authService.isLoading;
  String? get token => _authService.token;
  AuthService get authService => _authService;

  // Data caches
  List<Auction> _auctions = [];
  List<Property> _properties = [];
  List<Bid> _userBids = [];
  DashboardStats? _dashboardStats;

  // Loading states
  bool _loadingAuctions = false;
  bool _loadingProperties = false;
  bool _loadingBids = false;
  bool _loadingStats = false;
  bool _isRefreshing = false;

  // Floating AI Broker button visibility
  bool _isFloatingButtonHidden = false;

  // Active AI Broker chat ID
  int? _activeAIChatId;

  // Getters
  List<Auction> get auctions => _auctions;
  List<Property> get properties => _properties;
  List<Bid> get userBids => _userBids;
  DashboardStats? get dashboardStats => _dashboardStats;

  bool get loadingAuctions => _loadingAuctions;
  bool get loadingProperties => _loadingProperties;
  bool get loadingBids => _loadingBids;
  bool get loadingStats => _loadingStats;
  bool get isRefreshing => _isRefreshing;
  bool get isFloatingButtonHidden => _isFloatingButtonHidden;
  int? get activeAIChatId => _activeAIChatId;

  // Featured auctions (top 2 by bid count)
  List<Auction> get featuredAuctions {
    final sorted = List<Auction>.from(_auctions)
      ..sort((a, b) => b.bidCount.compareTo(a.bidCount));
    return sorted.take(2).toList();
  }

  // Active auctions (started and not ended)
  List<Auction> get activeAuctions {
    return _auctions.where((auction) => auction.isActive).toList();
  }

  // Upcoming auctions (approved but not started yet)
  List<Auction> get upcomingAuctions {
    return _auctions.where((auction) => auction.isUpcoming).toList();
  }

  // User's properties
  List<Property> get userProperties {
    if (user == null) {
      print('⚠️ userProperties: No user logged in');
      return [];
    }

    final filtered = _properties
        .where((property) => property.ownerId == user!.accountId)
        .toList();

    print('🏠 userProperties getter:');
    print('  User ID: ${user!.accountId}');
    print('  Total properties: ${_properties.length}');
    print('  Filtered (user owns): ${filtered.length}');

    return filtered;
  }

  // User's auctions
  List<Auction> get userAuctions {
    if (user == null) return [];
    final userPropertyIds = userProperties.map((p) => p.propertyId).toSet();
    return _auctions
        .where((auction) => userPropertyIds.contains(auction.propertyId))
        .toList();
  }

  Future<void> init() async {
    await _authService.init();
    _authService.addListener(_onAuthChanged);
    notifyListeners();
    // Load initial data for freemium experience
    loadInitialData();
    // Start real-time listeners for Firebase
    _startFirestoreListeners();
    // Start fallback polling as backup (less frequent now)
    _startFallbackPolling();

    // Start notification listeners if user is already logged in
    if (isLoggedIn && user != null) {
      _notificationService.startNotificationListeners(user!.accountId);
    }
  }

  /// Start Firestore real-time listeners for instant updates
  void _startFirestoreListeners() {
    print('🔥 Starting Firestore real-time listeners for auctions...');

    // Listen to all auctions in real-time
    _auctionsSubscription = FirestoreService.listenToAllAuctions().listen(
      (auctions) {
        if (auctions.isNotEmpty) {
          print('🔥 Firestore: Received ${auctions.length} auctions');
          _auctions = auctions;
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ Firestore auction listener error: $error');
        // Fallback to API if Firestore fails
        print('⚠️ Falling back to API for auctions');
      },
    );
  }

  void _startFallbackPolling() {
    // Only start fallback if not already running
    if (_fallbackTimer != null) return;

    // Reduced frequency since we have real-time Firestore updates
    print('Starting fallback polling every 5 minutes (backup)');
    _fallbackTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshDataFallback();
    });
  }

  Future<void> _refreshDataFallback() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      // Only refresh bid counts and check for new auctions
      await _refreshBidCounts();
      await _checkForNewAuctions();
    } catch (e) {
      print('Error during fallback refresh: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshBidCounts() async {
    try {
      // Get fresh auction data to update bid counts
      final response = await AuctionService.getAuctions();
      if (response.success && response.data != null) {
        // Update existing auctions with new bid counts
        for (final newAuction in response.data!) {
          final existingIndex = _auctions.indexWhere(
            (a) => a.auctionId == newAuction.auctionId,
          );
          if (existingIndex != -1) {
            _auctions[existingIndex] = newAuction;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing bid counts: $e');
    }
  }

  Future<void> _checkForNewAuctions() async {
    try {
      // Get fresh auction data to check for new auctions
      final response = await AuctionService.getAuctions();
      if (response.success && response.data != null) {
        final newAuctionCount = response.data!.length;
        final currentAuctionCount = _auctions.length;

        // Only refresh if there are new auctions
        if (newAuctionCount != currentAuctionCount) {
          _auctions = response.data!;
          notifyListeners();
          print('New auctions detected, refreshed auction list');
        }
      }
    } catch (e) {
      print('Error checking for new auctions: $e');
    }
  }

  void _onAuthChanged() {
    notifyListeners();
    // Always load initial data for freemium experience
    loadInitialData();

    // Start/stop notification listeners based on login status
    if (isLoggedIn && user != null) {
      _notificationService.startNotificationListeners(user!.accountId);
    } else {
      _notificationService.stopNotificationListeners();
    }
  }

  Future<void> loadInitialData() async {
    print('loadInitialData called');
    // Load public data for all users (freemium experience)
    await Future.wait([loadAuctions(), loadProperties(), loadDashboardStats()]);

    // Load user-specific data only if logged in
    if (isLoggedIn) {
      await loadUserBids();
    }
  }

  Future<void> loadDashboardStats() async {
    _loadingStats = true;
    notifyListeners();

    try {
      print('Loading dashboard stats...');
      final response = await DashboardService.getPublicStats();
      if (response.success && response.data != null) {
        _dashboardStats = response.data;
        print('Loaded dashboard stats successfully');
      } else {
        print('Error loading stats: ${response.error}');
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
    } finally {
      _loadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadAuctions() async {
    print('loadAuctions called - current auctions length: ${_auctions.length}');
    _loadingAuctions = true;
    notifyListeners();

    try {
      print('Loading auctions...');
      // Add a small delay to ensure API is ready
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await AuctionService.getAuctions();
      print(
        'Auction response: ${response.success}, data: ${response.data?.length}',
      );
      if (response.success && response.data != null) {
        _auctions = response.data!;
        print('Loaded ${_auctions.length} auctions');
      } else {
        print('Error loading auctions: ${response.error}');
        _auctions = [];
      }
    } catch (e) {
      print('Error loading auctions: $e');
      _auctions = [];
    } finally {
      _loadingAuctions = false;
      notifyListeners();
      print(
        'loadAuctions completed - final auctions length: ${_auctions.length}',
      );
    }
  }

  Future<void> loadProperties() async {
    _loadingProperties = true;
    notifyListeners();

    try {
      print('Loading properties...');
      // Add a small delay to ensure API is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Use my-properties endpoint for logged-in users, public endpoint for non-authenticated users
      final response = isLoggedIn
          ? await PropertyService.getMyProperties()
          : await PropertyService.getProperties();

      print(
        'Property response: ${response.success}, data: ${response.data?.length}',
      );
      if (response.success && response.data != null) {
        _properties = response.data!;
        print('Loaded ${_properties.length} properties');
        // Debug: Log each property
        for (var prop in _properties) {
          print(
            '  Property: ${prop.name} (ID: ${prop.propertyId}, Owner: ${prop.ownerId})',
          );
        }
      } else {
        print('Error loading properties: ${response.error}');
        _properties = [];
      }
    } catch (e) {
      print('Error loading properties: $e');
      _properties = [];
    } finally {
      _loadingProperties = false;
      notifyListeners();
    }
  }

  Future<void> loadUserBids() async {
    if (!isLoggedIn) return;

    _loadingBids = true;
    notifyListeners();

    try {
      final response = await BidService.getUserBids();
      if (response.success && response.data != null) {
        _userBids = response.data!;
      } else {
        print('Error loading user bids: ${response.error}');
        _userBids = [];
      }
    } catch (e) {
      print('Error loading user bids: $e');
      _userBids = [];
    } finally {
      _loadingBids = false;
      notifyListeners();
    }
  }

  Future<ApiResponse<void>> deleteProperty(int propertyId) async {
    try {
      final response = await PropertyService.deleteProperty(propertyId);
      if (response.success) {
        // Remove from local list
        _properties.removeWhere((p) => p.propertyId == propertyId);
        notifyListeners();
      }
      return response;
    } catch (e) {
      print('Error deleting property: $e');
      return ApiResponse.error('Failed to delete property: $e');
    }
  }

  void clearData() {
    _auctions = [];
    _properties = [];
    _userBids = [];
    notifyListeners();
  }

  // Auth methods
  Future<ApiResponse<Account>> login(String email, String password) async {
    final response = await _authService.login(email, password);
    return response;
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final response = await _authService.signup(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );
    return response.success;
  }

  // KYC document upload is now handled by KycService
  // This keeps app_state focused on app-wide state management only

  Future<void> refreshUserProfile() async {
    if (!isLoggedIn) return;

    try {
      final response = await _authService.getCurrentUser();
      if (response.success) {
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    clearData();
    _notificationService.clear();
  }

  // Floating button visibility management
  void hideFloatingButton() {
    _isFloatingButtonHidden = true;
    notifyListeners();
  }

  void showFloatingButton() {
    _isFloatingButtonHidden = false;
    notifyListeners();
  }

  // AI Chat management
  void setActiveAIChatId(int? chatId) {
    _activeAIChatId = chatId;
    notifyListeners();
  }

  void clearActiveAIChat() {
    _activeAIChatId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _auctionsSubscription?.cancel();
    _authService.removeListener(_onAuthChanged);
    _notificationService.dispose();
    super.dispose();
  }
}
