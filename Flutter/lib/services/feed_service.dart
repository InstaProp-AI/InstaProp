import 'dart:async';
import 'dart:math';
import '../models/feed_item.dart';
import '../models/feed_notification.dart';
import '../models/community_post.dart';
import '../models/community.dart';
import '../models/news_article.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../models/notification.dart';
import '../models/live_stream.dart';
import '../models/valuation_prompt.dart';
import '../models/payment_reminder.dart';
import 'community_post_service.dart';
import 'community_service.dart';
import 'news_service.dart';
import 'project_service.dart';
import 'developer_service.dart';
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
            case 'post':
              itemType = FeedItemType.post;
              itemData = CommunityPost.fromJson(data);
              break;
            case 'auction':
              itemType = FeedItemType.auction;
              itemData = Auction.fromJson(data);
              break;
            case 'community':
              itemType = FeedItemType.community;
              itemData = Community.fromJson(data);
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
            case 'livestream':
              itemType = FeedItemType.livestream;
              itemData = LiveStream.fromJson(data);
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
          }
        } catch (e) {
          print('❌ Error parsing feed item: $e');
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
        _fetchPosts(page),
        _fetchAuctions(),
        _fetchCommunities(),
        _fetchNews(),
        _fetchProjects(),
        _fetchDevelopers(),
      ]);

      final posts = results[0] as List<CommunityPost>;
      final auctions = results[1] as List<Auction>;
      final communities = results[2] as List<Community>;
      final news = results[3] as List<NewsArticle>;
      final projects = results[4] as List<ProjectModel>;
      final developers = results[5] as List<FeaturedDeveloper>;

      final feedItems = <FeedItem>[];

      // Add diverse content (30% posts, 20% auctions, 20% communities, 10% each for news/projects/developers)
      // Use virtual page to ensure unique IDs across pages
      // Use modulo to cycle through items across pages
      final postOffset = (virtualPage * 6) % posts.length;
      for (var i = 0; i < 6 && i < posts.length; i++) {
        final index = (postOffset + i) % posts.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.post,
            data: posts[index],
            id: 'post_${posts[index].postId}_p${virtualPage}',
          ),
        );
      }

      final auctionOffset = (virtualPage * 4) % auctions.length;
      for (var i = 0; i < 4 && i < auctions.length; i++) {
        final index = (auctionOffset + i) % auctions.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.auction,
            data: auctions[index],
            id: 'auction_${auctions[index].auctionId}_p${virtualPage}',
          ),
        );
      }

      final communityOffset = (virtualPage * 4) % communities.length;
      for (var i = 0; i < 4 && i < communities.length; i++) {
        final index = (communityOffset + i) % communities.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.community,
            data: communities[index],
            id: 'community_${communities[index].communityId}_p${virtualPage}',
          ),
        );
      }

      if (news.isNotEmpty) {
        final newsIndex = (virtualPage) % news.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.news,
            data: news[newsIndex],
            id: 'news_${news[newsIndex].newsArticleId}_p${virtualPage}',
          ),
        );
      }

      if (projects.isNotEmpty) {
        final projectIndex = (virtualPage) % projects.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.project,
            data: projects[projectIndex],
            id: 'project_${projects[projectIndex].projectId}_p${virtualPage}',
          ),
        );
      }

      if (developers.isNotEmpty) {
        final developerIndex = (virtualPage) % developers.length;
        feedItems.add(
          FeedItem(
            type: FeedItemType.developer,
            data: developers[developerIndex],
            id: 'developer_${developers[developerIndex].developerId}_p${virtualPage}',
          ),
        );
      }

      // Add REAL notifications from database
      final notifications = await _fetchRealNotifications();
      final notificationsToAdd = notifications.take(3).map((notif) {
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

      print(
        '✅ Generated ${feedItems.length} items from fallback (including ${notifications.length} notifications)',
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
        _fetchPosts(page),
        _fetchCommunities(),
        _fetchNews(),
        _fetchAuctions(),
        _fetchProjects(),
        _fetchDevelopers(),
        _fetchMembers(),
      ]);

      final posts = results[0];
      final communities = results[1];
      final news = results[2];
      final auctions = results[3];
      final projects = results[4];
      final developers = results[5];
      final members = results[6];

      // Generate notifications (not used in new backend implementation)
      // final notifications = _generateNotifications(3);

      // Create feed items according to algorithm
      final feedItems = <FeedItem>[];

      // 50% Posts (10 items)
      final postsToAdd = posts.take(10).toList();
      if (postsToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            postsToAdd,
            FeedItemType.post,
            (post) => 'post_${post.postId}',
          ),
        );
      }

      // 10% Communities (2 items)
      final communitiesToAdd = communities.take(2).toList();
      if (communitiesToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            communitiesToAdd,
            FeedItemType.community,
            (comm) => 'community_${comm.communityId}',
          ),
        );
      }

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

  static Future<List<CommunityPost>> _fetchPosts(int page) async {
    try {
      final response = await CommunityPostService.getFeed(
        sort: 'hot',
        page: page,
        pageSize: 15,
      );
      return response.data ?? [];
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  static Future<List<Community>> _fetchCommunities() async {
    try {
      final trending = await CommunityService.getTrendingCommunities();
      final suggested = await CommunityService.getSuggestedCommunities();

      final all = <Community>[];
      if (trending.success && trending.data != null && trending.data is List) {
        final dataList = trending.data as List<dynamic>;
        for (var item in dataList) {
          if (item is Community) all.add(item);
        }
      }
      if (suggested.success &&
          suggested.data != null &&
          suggested.data is List) {
        final dataList = suggested.data as List<dynamic>;
        for (var item in dataList) {
          if (item is Community) all.add(item);
        }
      }

      return all;
    } catch (e) {
      print('Error fetching communities: $e');
      return [];
    }
  }

  static Future<List<NewsArticle>> _fetchNews() async {
    try {
      return await NewsService(ApiClient.baseUrl).getLatestNews(count: 5);
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
      return await DeveloperService(ApiClient.baseUrl).getFeaturedDevelopers();
    } catch (e) {
      print('Error fetching developers: $e');
      return [];
    }
  }

  static Future<List<dynamic>> _fetchMembers() async {
    try {
      final response = await CommunityService.getPopularMembers();
      return response.data ?? [];
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  static List<FeedNotification> _generateNotifications(int count) {
    final notifications = <FeedNotification>[];
    final types = List<FeedNotificationType>.from(FeedNotificationType.values);
    // Web doesn't support shuffle - just use all types in order

    for (int i = 0; i < count && i < types.length; i++) {
      notifications.add(_createNotification(types[i]));
    }

    return notifications;
  }

  static FeedNotification _createNotification(FeedNotificationType type) {
    switch (type) {
      case FeedNotificationType.outbid:
        return FeedNotification(
          type: type,
          title: 'You\'ve been outbid!',
          message: 'Someone placed a higher bid on Luxury Villa',
          actionText: 'Bid +\$1000',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(60)),
          ),
          metadata: {'auctionId': 123, 'currentBid': 500000},
        );

      case FeedNotificationType.auctionEnding:
        return FeedNotification(
          type: type,
          title: 'Auction ending soon!',
          message: 'Modern Apartment auction ends in 2 hours',
          actionText: 'Place Bid',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(120)),
          ),
          metadata: {'auctionId': 456},
        );

      case FeedNotificationType.auctionRequest:
        return FeedNotification(
          type: type,
          title: 'Request an auction',
          message: 'Get the best price for your property',
          actionText: 'Request Now',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
        );

      case FeedNotificationType.bidPlaced:
        return FeedNotification(
          type: type,
          title: 'New bid on your auction',
          message: 'Someone bid \$450,000 on your property',
          actionText: 'View Auction',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(30)),
          ),
          metadata: {'auctionId': 789, 'bidAmount': 450000},
        );

      case FeedNotificationType.auctionWon:
        return FeedNotification(
          type: type,
          title: 'Congratulations! 🎉',
          message: 'You won the auction for Beachfront Villa',
          actionText: 'View Details',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(12)),
          ),
          metadata: {'auctionId': 321, 'winningBid': 1200000},
        );

      case FeedNotificationType.auctionApproved:
        return FeedNotification(
          type: type,
          title: 'Auction approved!',
          message: 'Your auction request has been approved',
          actionText: 'View Auction',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(6)),
          ),
          metadata: {'auctionId': 654},
        );

      case FeedNotificationType.propertyInspection:
        return FeedNotification(
          type: type,
          title: 'Schedule property inspection',
          message: 'Book a viewing for Downtown Penthouse',
          actionText: 'Book Now',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(48)),
          ),
          metadata: {'propertyId': 111},
        );

      case FeedNotificationType.paymentDue:
        return FeedNotification(
          type: type,
          title: 'Payment reminder',
          message: 'Installment of \$5,000 due in 3 days',
          actionText: 'Pay Now',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
          metadata: {'amount': 5000, 'dueDate': '2025-11-01'},
        );

      case FeedNotificationType.newEvent:
        return FeedNotification(
          type: type,
          title: 'New property event',
          message: 'Open house this Saturday at 2 PM',
          actionText: 'Add to Calendar',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(12)),
          ),
          metadata: {'eventId': 222},
        );

      case FeedNotificationType.achievement:
        return FeedNotification(
          type: type,
          title: 'Achievement unlocked! 🏆',
          message: 'You earned the "Active Bidder" badge',
          actionText: 'View Profile',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(60)),
          ),
          metadata: {'badgeId': 'active_bidder'},
        );

      case FeedNotificationType.communityInvite:
        return FeedNotification(
          type: type,
          title: 'Community invitation',
          message: 'Join "Downtown Property Owners" community',
          actionText: 'Accept',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
          metadata: {'communityId': 333},
        );

      case FeedNotificationType.newFollower:
        return FeedNotification(
          type: type,
          title: 'New follower',
          message: 'John Smith started following you',
          actionText: 'Follow Back',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(12)),
          ),
          metadata: {'userId': 444},
        );

      case FeedNotificationType.postLiked:
        return FeedNotification(
          type: type,
          title: 'Your post is popular!',
          message: 'Your post got 100 likes',
          actionText: 'View Post',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(6)),
          ),
          metadata: {'postId': 555, 'likeCount': 100},
        );

      case FeedNotificationType.commentReply:
        return FeedNotification(
          type: type,
          title: 'New reply',
          message: 'Sarah replied to your comment',
          actionText: 'View Comment',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(120)),
          ),
          metadata: {'commentId': 666},
        );

      case FeedNotificationType.auctionStarted:
        return FeedNotification(
          type: type,
          title: 'New auction nearby',
          message: 'Luxury Condo auction just started in your area',
          actionText: 'View',
          createdAt: DateTime.now().subtract(
            Duration(minutes: _random.nextInt(30)),
          ),
          metadata: {'auctionId': 777},
        );

      case FeedNotificationType.priceDrop:
        return FeedNotification(
          type: type,
          title: 'Price drop alert! 💰',
          message: 'Garden Villa reduced by \$50,000',
          actionText: 'View Deal',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(12)),
          ),
          metadata: {'propertyId': 888, 'discount': 50000},
        );

      case FeedNotificationType.trendingPost:
        return FeedNotification(
          type: type,
          title: 'Your post is trending! 🔥',
          message: 'Your post is getting lots of attention',
          actionText: 'Share',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(6)),
          ),
          metadata: {'postId': 999},
        );

      case FeedNotificationType.milestone:
        return FeedNotification(
          type: type,
          title: 'Milestone reached! 🎯',
          message: 'You reached 1,000 reputation points',
          actionText: 'Claim Reward',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
          metadata: {'reputation': 1000},
        );

      case FeedNotificationType.aiSuggestion:
        return FeedNotification(
          type: type,
          title: 'AI found a match',
          message: 'Property matching your preferences available',
          actionText: 'View',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(12)),
          ),
          metadata: {'propertyId': 1010},
        );

      case FeedNotificationType.referral:
        return FeedNotification(
          type: type,
          title: 'Earn rewards! 💵',
          message: 'Invite friends and earn \$50 per referral',
          actionText: 'Invite Friends',
          createdAt: DateTime.now().subtract(
            Duration(hours: _random.nextInt(48)),
          ),
          metadata: {'rewardAmount': 50},
        );
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
