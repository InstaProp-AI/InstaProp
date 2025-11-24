class AppNotification {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? auctionId;
  final String? bidId;
  final String? propertyId;
  final String? eventId;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.auctionId,
    this.bidId,
    this.propertyId,
    this.eventId,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Parse notification type (can be int or string)
    NotificationType parseType() {
      final typeValue = json['type'] ?? json['Type'];
      if (typeValue == null) return NotificationType.general;

      // If it's an int, use fromInt
      if (typeValue is int) {
        return NotificationType.fromInt(typeValue);
      }

      // If it's a string, use fromString
      if (typeValue is String) {
        return NotificationType.fromString(typeValue);
      }

      return NotificationType.general;
    }

    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return AppNotification(
      notificationId: parseId(json['notificationId'] ?? json['NotificationId']),
      userId: parseId(json['userId'] ?? json['UserId']),
      title: json['title'] ?? json['Title'] ?? '',
      message: json['message'] ?? json['Message'] ?? '',
      type: parseType(),
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      auctionId: parseOptionalId(json['auctionId'] ?? json['AuctionId']),
      bidId: parseOptionalId(json['bidId'] ?? json['BidId']),
      propertyId: parseOptionalId(json['propertyId'] ?? json['PropertyId']),
      eventId: parseOptionalId(json['eventId'] ?? json['EventId']),
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      readAt: json['readAt'] != null || json['ReadAt'] != null
          ? DateTime.parse(json['readAt'] ?? json['ReadAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.value,
      'isRead': isRead,
      'auctionId': auctionId,
      'bidId': bidId,
      'propertyId': propertyId,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    }
  }
}

enum NotificationType {
  bidPlaced(0),
  outbid(1),
  auctionStarted(2),
  auctionEnding(3),
  auctionWon(4),
  auctionLost(5),
  eventReminder(6),
  publicEvent(7),
  auctionApproved(8),
  auctionRejected(9),
  general(10);

  final int value;
  const NotificationType(this.value);

  static NotificationType fromInt(int value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }

  static NotificationType fromString(String value) {
    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'bidplaced':
      case 'bid_placed':
        return NotificationType.bidPlaced;
      case 'outbid':
        return NotificationType.outbid;
      case 'auctionstarted':
      case 'auction_started':
        return NotificationType.auctionStarted;
      case 'auctionending':
      case 'auction_ending':
        return NotificationType.auctionEnding;
      case 'auctionwon':
      case 'auction_won':
        return NotificationType.auctionWon;
      case 'auctionlost':
      case 'auction_lost':
        return NotificationType.auctionLost;
      case 'eventreminder':
      case 'event_reminder':
        return NotificationType.eventReminder;
      case 'publicevent':
      case 'public_event':
        return NotificationType.publicEvent;
      case 'auctionapproved':
      case 'auction_approved':
        return NotificationType.auctionApproved;
      case 'auctionrejected':
      case 'auction_rejected':
        return NotificationType.auctionRejected;
      default:
        return NotificationType.general;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.bidPlaced:
        return 'Bid Placed';
      case NotificationType.outbid:
        return 'Outbid';
      case NotificationType.auctionStarted:
        return 'Auction Started';
      case NotificationType.auctionEnding:
        return 'Auction Ending';
      case NotificationType.auctionWon:
        return 'Auction Won';
      case NotificationType.auctionLost:
        return 'Auction Lost';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.publicEvent:
        return 'Public Event';
      case NotificationType.auctionApproved:
        return 'Auction Approved';
      case NotificationType.auctionRejected:
        return 'Auction Rejected';
      case NotificationType.general:
        return 'Notification';
    }
  }
}
