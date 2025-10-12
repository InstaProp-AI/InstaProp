import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AdminNotificationService extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Get user statistics
  Future<ApiResponse<UserStats>> getUserStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        '/api/notification/admin/stats',
        UserStats.fromJson,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Failed to fetch stats: $e');
    }
  }

  // Get users with optional filter
  Future<ApiResponse<List<UserSummary>>> getUsers({String? filter}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = filter != null
          ? '/api/notification/admin/users?filter=$filter'
          : '/api/notification/admin/users';

      final response = await ApiClient.getList(endpoint, UserSummary.fromJson);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Failed to fetch users: $e');
    }
  }

  // Send notification
  Future<ApiResponse<SendNotificationResponse>> sendNotification({
    required String targetType,
    required String title,
    required String message,
    List<int>? userIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post('/api/notification/admin/send', {
        'targetType': targetType,
        'title': title,
        'message': message,
        if (userIds != null) 'userIds': userIds,
      }, SendNotificationResponse.fromJson);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Failed to send notification: $e');
    }
  }

  // Get notification history
  Future<ApiResponse<NotificationHistory>> getNotificationHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        '/api/notification/admin/history?page=$page&pageSize=$pageSize',
        NotificationHistory.fromJson,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Failed to fetch history: $e');
    }
  }
}

// Models
class UserStats {
  final int totalUsers;
  final int propertyOwnersCount;
  final int auctionOwnersCount;
  final int biddersCount;
  final int verifiedCount;
  final int unverifiedCount;

  UserStats({
    required this.totalUsers,
    required this.propertyOwnersCount,
    required this.auctionOwnersCount,
    required this.biddersCount,
    required this.verifiedCount,
    required this.unverifiedCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalUsers: json['totalUsers'] ?? 0,
      propertyOwnersCount: json['propertyOwnersCount'] ?? 0,
      auctionOwnersCount: json['auctionOwnersCount'] ?? 0,
      biddersCount: json['biddersCount'] ?? 0,
      verifiedCount: json['verifiedCount'] ?? 0,
      unverifiedCount: json['unverifiedCount'] ?? 0,
    );
  }
}

class UserSummary {
  final int accountId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String status;
  final DateTime createdAt;

  UserSummary({
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.status,
    required this.createdAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      accountId: json['accountId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get fullName => '$firstName $lastName';
}

class SendNotificationResponse {
  final String message;
  final int recipientCount;

  SendNotificationResponse({
    required this.message,
    required this.recipientCount,
  });

  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) {
    return SendNotificationResponse(
      message: json['message'] ?? '',
      recipientCount: json['recipientCount'] ?? 0,
    );
  }
}

class NotificationHistory {
  final List<NotificationHistoryItem> notifications;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  NotificationHistory({
    required this.notifications,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      notifications: (json['notifications'] as List? ?? [])
          .map((item) => NotificationHistoryItem.fromJson(item))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class NotificationHistoryItem {
  final int notificationId;
  final int userId;
  final String userName;
  final String title;
  final String message;
  final int type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationHistoryItem({
    required this.notificationId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      notificationId: json['notificationId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 0,
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}
