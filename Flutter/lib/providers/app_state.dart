import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/auction_service.dart';
import '../services/property_service.dart';
import '../services/bid_service.dart';
import '../models/user.dart';
import '../models/auction.dart';
import '../models/property.dart';
import '../models/bid.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Timer? _refreshTimer;

  // Auth state
  Account? get user => _authService.user;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isLoading => _authService.isLoading;

  // Data caches
  List<Auction> _auctions = [];
  List<Property> _properties = [];
  List<Bid> _userBids = [];

  // Loading states
  bool _loadingAuctions = false;
  bool _loadingProperties = false;
  bool _loadingBids = false;
  bool _isRefreshing = false;

  // Getters
  List<Auction> get auctions => _auctions;
  List<Property> get properties => _properties;
  List<Bid> get userBids => _userBids;

  bool get loadingAuctions => _loadingAuctions;
  bool get loadingProperties => _loadingProperties;
  bool get loadingBids => _loadingBids;
  bool get isRefreshing => _isRefreshing;

  // Featured auctions (top 2 by bid count)
  List<Auction> get featuredAuctions {
    final sorted = List<Auction>.from(_auctions)
      ..sort((a, b) => b.bidCount.compareTo(a.bidCount));
    return sorted.take(2).toList();
  }

  // Active auctions
  List<Auction> get activeAuctions {
    return _auctions.where((auction) => auction.isActive).toList();
  }

  // User's properties
  List<Property> get userProperties {
    if (user == null) return [];
    return _properties
        .where((property) => property.ownerId == user!.userId)
        .toList();
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
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _refreshData();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      // Only refresh bid counts and check for new auctions
      await _refreshBidCounts();
      await _checkForNewAuctions();
    } catch (e) {
      print('Error during auto-refresh: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshBidCounts() async {
    try {
      // Get fresh auction data to update bid counts
      final response =
          await AuctionService.getAuctions(); // Changed to get all auctions
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
      final response =
          await AuctionService.getAuctions(); // Changed to get all auctions
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
  }

  Future<void> loadInitialData() async {
    print('loadInitialData called');
    // Load public data for all users (freemium experience)
    await Future.wait([loadAuctions(), loadProperties()]);

    // Load user-specific data only if logged in
    if (isLoggedIn) {
      await loadUserBids();
    }
  }

  Future<void> loadAuctions() async {
    _loadingAuctions = true;
    notifyListeners();

    try {
      print('Loading auctions...');
      // Add a small delay to ensure API is ready
      await Future.delayed(const Duration(milliseconds: 500));
      final response =
          await AuctionService.getAuctions(); // Changed to get all auctions
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
    }
  }

  Future<void> loadProperties() async {
    _loadingProperties = true;
    notifyListeners();

    try {
      print('Loading properties...');
      // Add a small delay to ensure API is ready
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await PropertyService.getProperties();
      print(
        'Property response: ${response.success}, data: ${response.data?.length}',
      );
      if (response.success && response.data != null) {
        _properties = response.data!;
        print('Loaded ${_properties.length} properties');
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

  void clearData() {
    _auctions = [];
    _properties = [];
    _userBids = [];
    notifyListeners();
  }

  // Auth methods
  Future<bool> login(String email, String password) async {
    final response = await _authService.login(email, password);
    return response.success;
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

  Future<void> logout() async {
    await _authService.logout();
    clearData();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
