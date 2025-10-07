import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/auction.dart';
import '../models/bid.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<AuctionUpdate>? _auctionUpdateController;
  StreamController<BidUpdate>? _bidUpdateController;
  String? _currentAuctionId;
  bool _isConnected = false;

  WebSocketService._();

  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  Stream<AuctionUpdate> get auctionUpdateStream {
    _auctionUpdateController ??= StreamController<AuctionUpdate>.broadcast();
    return _auctionUpdateController!.stream;
  }

  Stream<BidUpdate> get bidUpdateStream {
    _bidUpdateController ??= StreamController<BidUpdate>.broadcast();
    return _bidUpdateController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect(String auctionId) async {
    if (_isConnected && _currentAuctionId == auctionId) {
      return; // Already connected to this auction
    }

    await disconnect(); // Disconnect from previous auction if any

    // Try different ports in case the API is running on different ports
    final List<String> possibleUrls = [
      'ws://localhost:5000/ws/auction',
      'ws://localhost:5284/ws/auction',
      'ws://localhost:7135/ws/auction',
    ];

    for (String wsUrl in possibleUrls) {
      try {
        print('Attempting to connect to: $wsUrl');
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _currentAuctionId = auctionId;

        // Send subscription message
        _channel!.sink.add(
          jsonEncode({'type': 'subscribe', 'auctionId': auctionId}),
        );

        // Listen for messages
        _channel!.stream.listen(
          _handleMessage,
          onError: _handleError,
          onDone: _handleDisconnect,
        );

        _isConnected = true;
        print('WebSocket connected for auction: $auctionId on $wsUrl');
        return; // Success, exit the loop
      } catch (e) {
        print('WebSocket connection error on $wsUrl: $e');
        _isConnected = false;
        // Continue to next URL
      }
    }

    print(
      'Failed to connect to WebSocket on any port. Real-time updates disabled.',
    );
    _isConnected = false;
  }

  Future<void> connectToGeneralFeed() async {
    if (_isConnected && _currentAuctionId == 'general') {
      return; // Already connected to general feed
    }

    await disconnect(); // Disconnect from previous connection if any

    // Try different ports in case the API is running on different ports
    final List<String> possibleUrls = [
      'ws://localhost:5000/ws/auction',
      'ws://localhost:5284/ws/auction',
      'ws://localhost:7135/ws/auction',
      'ws://127.0.0.1:5000/ws/auction',
      'ws://127.0.0.1:5284/ws/auction',
    ];

    for (String wsUrl in possibleUrls) {
      try {
        print('🔌 Attempting to connect to general feed: $wsUrl');
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _currentAuctionId = 'general';

        // Wait a bit for connection to establish
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if connection is still valid
        if (_channel == null) {
          print('❌ Channel is null after connection attempt');
          continue;
        }

        // Send subscription message for general feed
        try {
          _channel!.sink.add(
            jsonEncode({'type': 'subscribe', 'auctionId': 'general'}),
          );
          print('📤 Sent subscription message for general feed');
        } catch (e) {
          print('❌ Error sending subscription message: $e');
          continue;
        }

        // Listen for messages
        _channel!.stream.listen(
          _handleMessage,
          onError: (error) {
            print('❌ WebSocket stream error: $error');
            _handleError(error);
          },
          onDone: () {
            print('🔌 WebSocket connection closed');
            _handleDisconnect();
          },
        );

        _isConnected = true;
        print('✅ WebSocket connected to general feed on $wsUrl');
        return; // Success, exit the loop
      } catch (e) {
        print('❌ WebSocket connection error on $wsUrl: $e');
        _isConnected = false;
        // Continue to next URL
      }
    }

    print(
      'Failed to connect to WebSocket general feed on any port. Real-time updates disabled.',
    );
    _isConnected = false;
  }

  void _handleMessage(dynamic message) {
    try {
      print('📨 Received WebSocket message: $message');
      final data = jsonDecode(message);
      final type = data['type'] as String?;
      print('📋 Message type: $type');

      switch (type) {
        case 'auction_update':
          print('🔄 Processing auction update');
          final auctionData = data['data'];
          final auction = Auction.fromJson(auctionData);
          _auctionUpdateController?.add(AuctionUpdate(auction));
          print('✅ Auction update processed');
          break;
        case 'bid_update':
          print('💰 Processing bid update');
          final bidData = data['data'];
          final bid = Bid.fromJson(bidData);
          _bidUpdateController?.add(BidUpdate(bid));
          print('✅ Bid update processed');
          break;
        case 'new_bid':
          print('🆕 Processing new bid');
          final bidData = data['data'];
          final bid = Bid.fromJson(bidData);
          _bidUpdateController?.add(BidUpdate(bid, isNewBid: true));
          print('✅ New bid processed');
          break;
        default:
          print('❓ Unknown WebSocket message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
      print('❌ Raw message: $message');
    }
  }

  void _handleError(error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
  }

  void _handleDisconnect() {
    print('🔌 WebSocket disconnected');
    _isConnected = false;
    _currentAuctionId = null;
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    _isConnected = false;
    _currentAuctionId = null;
  }

  void dispose() {
    disconnect();
    _auctionUpdateController?.close();
    _bidUpdateController?.close();
    _auctionUpdateController = null;
    _bidUpdateController = null;
  }
}

class AuctionUpdate {
  final Auction auction;
  final DateTime timestamp;

  AuctionUpdate(this.auction) : timestamp = DateTime.now();
}

class BidUpdate {
  final Bid bid;
  final bool isNewBid;
  final DateTime timestamp;

  BidUpdate(this.bid, {this.isNewBid = false}) : timestamp = DateTime.now();
}
