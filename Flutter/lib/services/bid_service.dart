import 'api_client.dart';
import '../models/bid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class BidService {
  static Future<ApiResponse<List<Bid>>> getBids(int auctionId) async {
    return await ApiClient.getList(
      '/api/bids/by-auction/$auctionId',
      Bid.fromJson,
    );
  }

  static Future<ApiResponse<Bid>> placeBid({
    required int auctionId,
    required double bidAmount,
    required BuildContext context,
  }) async {
    // First check if user was the last bidder
    final canBidResponse = await _canPlaceBid(auctionId, context);
    if (!canBidResponse.success) {
      return ApiResponse<Bid>(
        success: false,
        error: canBidResponse.error,
        statusCode: 400,
      );
    }

    final response = await ApiClient.post('/api/bids', {
      'auctionId': auctionId,
      'bidAmount': bidAmount,
    }, Bid.fromJson);
    // On success, refresh user profile to update points
    if (response.success) {
      try {
        final appState = context.read<AppState>();
        await appState.refreshUserProfile();
      } catch (_) {}
    }
    return response;
  }

  // Helper method to check if user can place a bid
  static Future<ApiResponse<bool>> _canPlaceBid(
    int auctionId,
    BuildContext context,
  ) async {
    try {
      // Get current user from AppState
      final appState = context.read<AppState>();
      if (!appState.isLoggedIn || appState.user == null) {
        return ApiResponse<bool>(
          success: false,
          error: 'User not authenticated',
          statusCode: 401,
        );
      }

      final user = appState.user!;

      // Check if user is suspended
      if (user.isSuspended) {
        final suspensionMessage =
            user.suspensionReason ??
            'Your account is suspended. You cannot place bids at this time.';
        return ApiResponse<bool>(
          success: false,
          error: suspensionMessage,
          statusCode: 403,
        );
      }

      // Check if user is verified (same as unverified accounts)
      if (!user.isVerified) {
        return ApiResponse<bool>(
          success: false,
          error: 'Your account must be verified before you can place bids.',
          statusCode: 403,
        );
      }

      // Get bid history for this auction
      final bidsResponse = await getBidsPublic(auctionId);
      if (!bidsResponse.success ||
          bidsResponse.data == null ||
          bidsResponse.data!.isEmpty) {
        // No bids yet, user can bid
        return ApiResponse<bool>(success: true, data: true, statusCode: 200);
      }

      // Get the latest bid
      final latestBid = bidsResponse.data!.first;

      // Get current user ID
      final currentUserId = appState.user!.accountId;

      // Check if current user was the last bidder
      if (latestBid.bidderId == currentUserId) {
        return ApiResponse<bool>(
          success: false,
          error:
              'You cannot place consecutive bids. Please wait for another bidder.',
          statusCode: 400,
        );
      }

      return ApiResponse<bool>(success: true, data: true, statusCode: 200);
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'Error checking bid eligibility: $e',
        statusCode: 500,
      );
    }
  }

  // Public method to check if user can place a bid (useful for UI state)
  static Future<ApiResponse<bool>> canUserBid(
    int auctionId,
    BuildContext context,
  ) async {
    return await _canPlaceBid(auctionId, context);
  }

  static Future<ApiResponse<List<Bid>>> getUserBids() async {
    return await ApiClient.getList('/api/bids/user', Bid.fromJson);
  }

  static Future<ApiResponse<Bid>> getBid(int bidId) async {
    return await ApiClient.get('/api/bids/$bidId', Bid.fromJson);
  }

  static Future<ApiResponse<void>> retractBid(int bidId) async {
    return await ApiClient.delete('/api/bids/$bidId');
  }

  // PUBLIC ENDPOINTS (No authentication required)

  // Get bid history for an auction (Public - No auth required)
  static Future<ApiResponse<List<Bid>>> getBidsPublic(int auctionId) async {
    return await ApiClient.getList(
      '/api/bids/by-auction/$auctionId',
      Bid.fromJson,
    );
  }

  // Get bidders for an auction (Public - No auth required)
  static Future<ApiResponse<List<Map<String, dynamic>>>> getBiddersPublic(
    int auctionId,
  ) async {
    return await ApiClient.getList(
      '/api/bids/bidders/$auctionId',
      (json) => json,
    );
  }
}
