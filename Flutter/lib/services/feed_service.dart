import 'dart:async';
import 'dart:math';
import '../models/feed_item.dart';
import '../models/feed_notification.dart';
// Community models removed
import '../models/news_article.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../models/deal_highlight.dart';
import '../models/project_story.dart';
import '../models/investor_milestone.dart';
import '../models/notification.dart';
import '../models/live_stream.dart';
import '../models/valuation_prompt.dart';
import '../models/payment_reminder.dart';
// Community services removed
import 'news_service.dart';
import 'project_service.dart';
import 'developer_service.dart';
import 'live_stream_service.dart';
import 'api_client.dart';

// Backend response model
class FeedResponseDto {
  final List<FeedItem> items;
  final int page;
  final bool hasMore;

  FeedResponseDto({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  factory FeedResponseDto.fromJson(Map<String, dynamic> json) {
    final items = <FeedItem>[];

    if (json['items'] is List) {
      for (var item in json['items']) {
        try {
          final type = item['type'] as String;
          final data = item['data'] as Map<String, dynamic>;
          final id = item['id'] as String;

          FeedItemType? itemType;
          dynamic itemData;

          switch (type) {
            case 'auction':
              itemType = FeedItemType.auction;
              itemData = Auction.fromJson(data);
              break;
            case 'news':
              itemType = FeedItemType.news;
              itemData = NewsArticle.fromJson(data);
              break;
            case 'project':
              itemType = FeedItemType.project;
              itemData = ProjectModel.fromJson(data);
              break;
            case 'developer':
              itemType = FeedItemType.developer;
              itemData = FeaturedDeveloper.fromJson(data);
              break;
            case 'deal_highlight':
              itemType = FeedItemType.dealHighlight;
              itemData = DealHighlight.fromJson(data);
              break;
            case 'project_story':
              itemType = FeedItemType.projectStory;
              itemData = ProjectStory.fromJson(data);
              break;
            case 'investor_milestone':
              itemType = FeedItemType.investorMilestone;
              itemData = InvestorMilestone.fromJson(data);
              break;
            case 'livestream':
              try {
                print('🔍 Parsing livestream item...');
                print('   Raw data keys: ${data.keys.toList()}');
                itemType = FeedItemType.livestream;
                final stream = LiveStream.fromJson(data);
                itemData = stream;
                print('✅ Successfully parsed livestream item: ${stream.title} (ID: ${stream.streamId})');
              } catch (e, stackTrace) {
                print('❌ Error parsing livestream item: $e');
                print('   Stack trace: $stackTrace');
                print('   Data: $data');
                // Set itemType to null so this item is skipped
                itemType = null;
                itemData = null;
              }
              break;
            case 'valuationPrompt':
              itemType = FeedItemType.valuationPrompt;
              itemData = ValuationPrompt.fromJson(data);
              break;
            case 'paymentReminder':
              itemType = FeedItemType.paymentReminder;
              itemData = PaymentReminder.fromJson(data);
              break;
          }

          if (itemType != null) {
            items.add(FeedItem(type: itemType, data: itemData, id: id));
          } else {
            print('⚠️ Skipped feed item with null type: $type');
          }
        } catch (e, stackTrace) {
          print('❌ Error parsing feed item (type: ${item['type']}, id: ${item['id']}): $e');
          print('   Stack trace: $stackTrace');
        }
      }
    }

    return FeedResponseDto(
      items: items,
      page: json['page'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class FeedService {
  static Random _random = Random();
  static int _virtualPage = 0; // Track virtual pages for infinite looping

  // Cache latest non-empty datasets to keep fallback balanced
  static List<Auction> _cachedAuctions = [];
  static List<NewsArticle> _cachedNews = [];
  static List<ProjectModel> _cachedProjects = [];
  static List<FeaturedDeveloper> _cachedDevelopers = [];
  static List<LiveStream> _cachedLiveStreams = [];

  static const int _fallbackAuctionTarget = 4;
  static const int _fallbackNewsTarget = 1;
  static const int _fallbackProjectTarget = 1;
  static const int _fallbackDeveloperTarget = 1;
  static const int _fallbackLiveStreamTarget = 2;
  static const int _fallbackNotificationCap = 2;

  /// Get mixed feed from backend API (now completely randomized server-side!)
  /// Uses virtual page counter to enable infinite scrolling
  static Future<List<FeedItem>> getMixedFeed({
    required int page,
    int pageSize = 20,
  }) async {
    _virtualPage++; // Always increment virtual page

    // Don't cycle pages - just keep going forward to prevent scroll jumps
    // Use virtual page seed for variety instead
    int actualPage = page;

    // Create a unique seed based on both virtual page and actual page
    // This ensures variety in content ordering without going backwards
    final pageSeed = _virtualPage * 1000 + page;
    _random = Random(pageSeed);

    print(
      '🔄 Fetching feed virtual page $_virtualPage (actual page $page, seed $pageSeed)...',
    );

    try {
      // Try backend first with timeout
      print('🌐 Calling backend API...');
      final response =
          await ApiClient.get(
            '/api/feed/explore?page=$actualPage&pageSize=$pageSize',
            (json) => _parseFeedResponse(json),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⏱️ Backend API timeout after 5 seconds');
              throw TimeoutException('Backend API timeout');
            },
          );

      print('📥 Backend response received: success=${response.success}');

      if (response.success &&
          response.data != null &&
          response.data!.items.isNotEmpty) {
        print('✅ Received ${response.data!.items.length} items from backend');
        
        // Debug: Count live streams in response
        final livestreamCount = response.data!.items.where((item) => item.type == FeedItemType.livestream).length;
        if (livestreamCount > 0) {
          print('📹 Found $livestreamCount live stream(s) in backend response');
        } else {
          print('⚠️ No live streams found in backend response');
        }
        
        return response.data!.items;
      }

      print(
        '⚠️ No feed data received from backend (empty or null), using fallback...',
      );
    } catch (e) {
      print('❌ Error fetching feed from backend: $e');
    }

    // ALWAYS fallback to ensure content is always available
    // Pass both virtual and actual page for variety
    print('📦 Using fallback feed generation');
    return await _getFallbackFeed(actualPage, _virtualPage);
  }

  static FeedResponseDto _parseFeedResponse(Map<String, dynamic> json) {
    return FeedResponseDto.fromJson(json);
  }

  static Future<List<FeedItem>> _getFallbackFeed(
    int page,
    int virtualPage,
  ) async {
    print(
      '⚠️ Using fallback feed generation - fetching real content (virtual page $virtualPage)',
    );

    try {
      // Fetch real content as fallback
      // Use actual page for fetching, virtual page for randomization seed
      final results = await Future.wait([
        _fetchAuctions(),
        _fetchNews(),
        _fetchProjects(),
        _fetchDevelopers(),
        _fetchLiveStreams(),
      ]);

      var auctions = List<Auction>.from(results[0] as List<Auction>);
      var news = List<NewsArticle>.from(results[1] as List<NewsArticle>);
      var projects = List<ProjectModel>.from(results[2] as List<ProjectModel>);
      var developers =
          List<FeaturedDeveloper>.from(results[3] as List<FeaturedDeveloper>);
      var liveStreams = List<LiveStream>.from(results[4] as List<LiveStream>);

      if (auctions.isNotEmpty) {
        _cachedAuctions = auctions;
      } else if (_cachedAuctions.isNotEmpty) {
        auctions = _cachedAuctions;
      }

      if (news.isNotEmpty) {
        _cachedNews = news;
      } else if (_cachedNews.isNotEmpty) {
        news = _cachedNews;
      }

      if (projects.isNotEmpty) {
        _cachedProjects = projects;
      } else if (_cachedProjects.isNotEmpty) {
        projects = _cachedProjects;
      }

      if (developers.isNotEmpty) {
        _cachedDevelopers = developers;
      } else if (_cachedDevelopers.isNotEmpty) {
        developers = _cachedDevelopers;
      }

      if (liveStreams.isNotEmpty) {
        _cachedLiveStreams = liveStreams;
      } else if (_cachedLiveStreams.isNotEmpty) {
        liveStreams = _cachedLiveStreams;
      }

      final feedItems = <FeedItem>[];

      void appendContent<T>({
        required List<T> source,
        required int desiredCount,
        required FeedItemType type,
        required String Function(T item, int index) idBuilder,
      }) {
        if (source.isEmpty || desiredCount <= 0) {
          return;
        }

        final safeCount = desiredCount >= source.length
            ? source.length
            : desiredCount;

        final indices = List<int>.generate(source.length, (i) => i);
        indices.shuffle(_random);

        for (var i = 0; i < safeCount; i++) {
          final index = indices[(virtualPage + i) % source.length];
          final item = source[index];
          feedItems.add(
            FeedItem(
              type: type,
              data: item,
              id: idBuilder(item, i),
            ),
          );
        }
      }

      appendContent<Auction>(
        source: auctions,
        desiredCount: _fallbackAuctionTarget,
        type: FeedItemType.auction,
        idBuilder: (auction, index) =>
            'auction_${auction.auctionId}_vp${virtualPage}_$index',
      );

      appendContent<NewsArticle>(
        source: news,
        desiredCount: _fallbackNewsTarget,
        type: FeedItemType.news,
        idBuilder: (article, index) =>
            'news_${article.newsArticleId}_vp${virtualPage}_$index',
      );

      appendContent<ProjectModel>(
        source: projects,
        desiredCount: _fallbackProjectTarget,
        type: FeedItemType.project,
        idBuilder: (project, index) =>
            'project_${project.projectId}_vp${virtualPage}_$index',
      );

      appendContent<FeaturedDeveloper>(
        source: developers,
        desiredCount: _fallbackDeveloperTarget,
        type: FeedItemType.developer,
        idBuilder: (developer, index) =>
            'developer_${developer.developerId}_vp${virtualPage}_$index',
      );

      if (liveStreams.isNotEmpty) {
        print('📹 Adding ${liveStreams.length} live stream(s) to fallback feed');
        appendContent<LiveStream>(
          source: liveStreams,
          desiredCount: _fallbackLiveStreamTarget,
          type: FeedItemType.livestream,
          idBuilder: (stream, index) =>
              'livestream_${stream.streamId}_vp${virtualPage}_$index',
        );
      } else {
        print('⚠️ No live streams available for fallback feed');
      }

      // Add REAL notifications from database with sensible limits
      final notifications = await _fetchRealNotifications();
      var notificationLimit = 0;
      if (feedItems.isEmpty) {
        notificationLimit = 1;
      } else {
        notificationLimit = (feedItems.length / 4).round();
        notificationLimit = notificationLimit.clamp(1, _fallbackNotificationCap);
      }

      final notificationsToAdd = notifications.take(notificationLimit).map((notif) {
        // Update ID to include page number for uniqueness
        return FeedItem(
          type: FeedItemType.notification,
          data: notif.data,
          id: '${notif.id}_p${virtualPage}',
        );
      }).toList();
      feedItems.addAll(notificationsToAdd);

      // Shuffle for randomness
      feedItems.shuffle(_random);

      final notificationCount = notificationsToAdd.length;
      print(
        '✅ Generated ${feedItems.length} items from fallback (including $notificationCount notifications)',
      );
      return feedItems;
    } catch (e) {
      print('❌ Error in fallback: $e');
      // Final fallback - generate smart notifications
      return _generateSmartNotifications(4).map((notif) {
        return FeedItem(
          type: FeedItemType.notification,
          data: notif,
          id: notif.id,
        );
      }).toList();
    }
  }

  static Future<List<FeedItem>> _fetchRealNotifications() async {
    try {
      final response = await ApiClient.getList(
        '/api/notification?unreadOnly=false',
        AppNotification.fromJson,
      );

      if (response.success && response.data != null) {
        print(
          '📧 Fetched ${response.data!.length} real notifications from backend',
        );
        // Convert AppNotification to FeedNotification format
        return response.data!.map((notification) {
          return FeedItem(
            type: FeedItemType.notification,
            data: _convertToFeedNotification(notification),
            id: 'notification_${notification.notificationId}',
          );
        }).toList();
      }
      print('⚠️ No notifications received from backend');
      return [];
    } catch (e) {
      print('❌ Error fetching real notifications: $e');
      return [];
    }
  }

  static FeedNotification _convertToFeedNotification(AppNotification appNotif) {
    return FeedNotification(
      type: _mapNotificationType(appNotif.type),
      title: appNotif.title,
      message: appNotif.message,
      createdAt: appNotif.createdAt,
      metadata: {
        'notificationId': appNotif.notificationId,
        'auctionId': appNotif.auctionId,
        'bidId': appNotif.bidId,
        'propertyId': appNotif.propertyId,
        'eventId': appNotif.eventId,
      },
    );
  }

  static FeedNotificationType _mapNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.bidPlaced:
        return FeedNotificationType.bidPlaced;
      case NotificationType.outbid:
        return FeedNotificationType.outbid;
      case NotificationType.auctionStarted:
        return FeedNotificationType.auctionStarted;
      case NotificationType.auctionEnding:
        return FeedNotificationType.auctionEnding;
      case NotificationType.auctionWon:
        return FeedNotificationType.auctionWon;
      case NotificationType.auctionLost:
        return FeedNotificationType.auctionWon; // Fallback
      case NotificationType.eventReminder:
      case NotificationType.publicEvent:
        return FeedNotificationType.newEvent;
      case NotificationType.auctionApproved:
        return FeedNotificationType.auctionApproved;
      case NotificationType.auctionRejected:
        return FeedNotificationType.auctionApproved; // Fallback
      case NotificationType.general:
        return FeedNotificationType.achievement;
    }
  }

  static List<FeedNotification> _generateSmartNotifications(int count) {
    final notifications = <FeedNotification>[];
    final now = DateTime.now();

    // Sample notification types with rich data
    final types = [
      FeedNotificationType.outbid,
      FeedNotificationType.auctionEnding,
      FeedNotificationType.paymentDue,
      FeedNotificationType.achievement,
    ];

    for (int i = 0; i < count && i < types.length; i++) {
      try {
        final type = types[i];
        final notification = _createSmartNotification(
          type,
          now.subtract(Duration(minutes: _random.nextInt(60))),
        );
        notifications.add(notification);
      } catch (e) {
        print('❌ Error creating notification $i: $e');
      }
    }

    return notifications;
  }

  static FeedNotification _createSmartNotification(
    FeedNotificationType type,
    DateTime createdAt,
  ) {
    switch (type) {
      case FeedNotificationType.outbid:
        return FeedNotification(
          type: type,
          title: 'You\'ve been outbid!',
          message: 'Someone placed a higher bid on Luxury Garden Villa',
          actionText: 'Bid +\$1000',
          createdAt: createdAt,
          metadata: {
            'propertyImage':
                'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
            'currentBid': 850000,
            'yourBid': 800000,
            'priceHistory': [700000, 750000, 780000, 800000, 850000],
          },
        );

      case FeedNotificationType.auctionEnding:
        return FeedNotification(
          type: type,
          title: 'Auction ending soon!',
          message: 'Modern Downtown Penthouse - Only 2h 15m left',
          actionText: 'Place Bid',
          createdAt: createdAt,
          metadata: {
            'propertyImage':
                'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800',
            'timeRemaining': '2h 15m',
            'currentBid': 1250000,
            'bidCount': 23,
          },
        );

      case FeedNotificationType.paymentDue:
        return FeedNotification(
          type: type,
          title: 'Payment reminder',
          message: 'Installment due soon for Garden Villa',
          actionText: 'Pay Now',
          createdAt: createdAt,
          metadata: {
            'amount': 5000,
            'dueDate': 'Nov 15, 2024',
            'paymentHistory': [5000, 5000, 4800, 5200, 5000],
          },
        );

      case FeedNotificationType.achievement:
        return FeedNotification(
          type: type,
          title: 'Achievement unlocked!',
          message: 'You earned the "Top Bidder" badge',
          actionText: 'View Profile',
          createdAt: createdAt,
          metadata: {'badgeName': 'Top Bidder', 'points': 150},
        );

      default:
        return FeedNotification(
          type: type,
          title: 'Notification',
          message: 'Check out this update',
          createdAt: createdAt,
        );
    }
  }

  // Old implementation - commented out for testing
  static Future<List<FeedItem>> getMixedFeed_OLD({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      // Fetch all content types in parallel
      final results = await Future.wait([
        _fetchNews(),
        _fetchAuctions(),
        _fetchProjects(),
        _fetchDevelopers(),
        _fetchMembers(),
      ]);

      final news = results[0];
      final auctions = results[1];
      final projects = results[2];
      final developers = results[3];
      final members = results[4];

      // Generate notifications (not used in new backend implementation)
      // final notifications = _generateNotifications(3);

      // Create feed items according to algorithm
      final feedItems = <FeedItem>[];

      // 10% Auctions (2 items)
      final auctionsToAdd = auctions.take(2).toList();
      if (auctionsToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            auctionsToAdd,
            FeedItemType.auction,
            (auction) => 'auction_${auction.auctionId}',
          ),
        );
      }

      // 5% News (1 item)
      if (news.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.news,
            data: news.first,
            id: 'news_${news.first.newsArticleId}',
          ),
        );
      }

      // 5% Projects (1 item)
      if (projects.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.project,
            data: projects.first,
            id: 'project_${projects.first.projectId}',
          ),
        );
      }

      // 5% Developers/Members (1 item)
      if (_random.nextBool() && developers.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.developer,
            data: developers.first,
            id: 'developer_${developers.first.developerId}',
          ),
        );
      } else if (members.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.member,
            data: members.first,
            id: 'member_${members.first['accountId']}',
          ),
        );
      }

      print('   Total feed items before shuffle: ${feedItems.length}');

      // Randomize order ensuring no same type twice in a row
      final shuffled = _shuffleWithoutConsecutiveDuplicates(feedItems);

      print('   Total feed items after shuffle: ${shuffled.length}');
      print('   Returning ${shuffled.take(pageSize).length} items');

      return shuffled.take(pageSize).toList();
    } catch (e) {
      print('❌ Error fetching mixed feed: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Community fetch methods removed

  static Future<List<NewsArticle>> _fetchNews() async {
    try {
      // Get token for authentication
      final token = await ApiClient.getToken();
      final newsService = NewsService(ApiClient.baseUrl, token: token);
      return await newsService.getLatestNews(count: 5);
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }

  static Future<List<Auction>> _fetchAuctions() async {
    try {
      // Get from API
      final response = await ApiClient.getList<Auction>(
        '/api/auction',
        (json) => Auction.fromJson(json),
      );
      return response.data ?? [];
    } catch (e) {
      print('Error fetching auctions: $e');
      return [];
    }
  }

  static Future<List<ProjectModel>> _fetchProjects() async {
    try {
      return await ProjectService(ApiClient.baseUrl).getTrendingProjects();
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  static Future<List<FeaturedDeveloper>> _fetchDevelopers() async {
    try {
      final developers = await DeveloperService(ApiClient.baseUrl).getFeaturedDevelopers();
      
      // Filter to only include developers with valid IDs and profiles
      // This ensures only real developers that can be viewed are shown
      final validDevelopers = developers.where((developer) {
        // Validate developer has a non-empty ID
        if (developer.developerId.isEmpty) {
          print('⚠️ Filtered out developer with empty ID');
          return false;
        }
        
        // Validate developer has a name (company or full name)
        final hasName = (developer.companyName != null && developer.companyName!.isNotEmpty) ||
                       (developer.firstName.isNotEmpty || developer.lastName.isNotEmpty);
        if (!hasName) {
          print('⚠️ Filtered out developer without name: ${developer.developerId}');
          return false;
        }
        
        // Validate GUID format (should be a valid GUID)
        final guidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        if (!guidPattern.hasMatch(developer.developerId)) {
          print('⚠️ Filtered out developer with invalid GUID format: ${developer.developerId}');
          return false;
        }
        
        return true;
      }).toList();
      
      print('✅ Filtered developers: ${developers.length} -> ${validDevelopers.length} valid');
      return validDevelopers;
    } catch (e) {
      print('Error fetching developers: $e');
      return [];
    }
  }

  static Future<List<LiveStream>> _fetchLiveStreams() async {
    try {
      final response = await LiveStreamService.getActiveStreams();
      if (response.success && response.data != null) {
        print('✅ Fetched ${response.data!.length} live streams');
        return response.data!;
      }
      print('⚠️ No live streams found or error: ${response.error}');
      return [];
    } catch (e) {
      print('Error fetching live streams: $e');
      return [];
    }
  }

  static Future<List<dynamic>> _fetchMembers() async {
    try {
      // Popular members endpoint removed (was part of community features)
      return [];
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  static List<FeedItem> _createFeedItems<T>(
    List<T> items,
    FeedItemType type,
    String Function(T) idGenerator,
  ) {
    return items.map((item) {
      return FeedItem(type: type, data: item, id: idGenerator(item));
    }).toList();
  }

  /// Shuffle items ensuring no same type appears twice in a row
  static List<FeedItem> _shuffleWithoutConsecutiveDuplicates(
    List<FeedItem> items,
  ) {
    if (items.length <= 1) return items;

    final shuffled = List<FeedItem>.from(items)..shuffle(_random);
    final result = <FeedItem>[shuffled.first];

    for (int i = 1; i < shuffled.length; i++) {
      if (shuffled[i].type == result.last.type) {
        // Find next item with different type
        int nextIndex = i + 1;
        while (nextIndex < shuffled.length &&
            shuffled[nextIndex].type == result.last.type) {
          nextIndex++;
        }

        if (nextIndex < shuffled.length) {
          // Swap
          final temp = shuffled[i];
          shuffled[i] = shuffled[nextIndex];
          shuffled[nextIndex] = temp;
        }
      }
      result.add(shuffled[i]);
    }

    return result;
  }
}
