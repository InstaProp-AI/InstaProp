import 'dart:math';
import '../models/feed_item.dart';
import '../models/feed_notification.dart';
import '../models/community_post.dart';
import '../models/community.dart';
import '../models/news_article.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import 'community_post_service.dart';
import 'community_service.dart';
import 'news_service.dart';
import 'project_service.dart';
import 'developer_service.dart';
import 'api_client.dart';

class FeedService {
  static final Random _random = Random();

  /// Get mixed feed with 20 items per batch
  static Future<List<FeedItem>> getMixedFeed({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      // Fetch all content types in parallel with error handling
      final results = await Future.wait([
        _fetchPosts(page).catchError((e) {
          print('Error fetching posts: $e');
          return <CommunityPost>[];
        }),
        _fetchCommunities().catchError((e) {
          print('Error fetching communities: $e');
          return <Community>[];
        }),
        _fetchNews().catchError((e) {
          print('Error fetching news: $e');
          return <NewsArticle>[];
        }),
        _fetchAuctions().catchError((e) {
          print('Error fetching auctions: $e');
          return <Auction>[];
        }),
        _fetchProjects().catchError((e) {
          print('Error fetching projects: $e');
          return <ProjectModel>[];
        }),
        _fetchDevelopers().catchError((e) {
          print('Error fetching developers: $e');
          return <FeaturedDeveloper>[];
        }),
        _fetchMembers().catchError((e) {
          print('Error fetching members: $e');
          return <dynamic>[];
        }),
      ]);

      final posts = (results[0] as List).cast<CommunityPost>();
      final communities = (results[1] as List).cast<Community>();
      final news = (results[2] as List).cast<NewsArticle>();
      final auctions = (results[3] as List).cast<Auction>();
      final projects = (results[4] as List).cast<ProjectModel>();
      final developers = (results[5] as List).cast<FeaturedDeveloper>();
      final members = (results[6] as List);

      // Generate notifications
      final notifications = _generateSmartNotifications(2);

      // Create feed items according to algorithm
      final feedItems = <FeedItem>[];

      // 40% Posts (8 items)
      final postsToAdd = posts.take(8).toList();
      if (postsToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            postsToAdd,
            FeedItemType.post,
            (post) => 'post_${post.postId}',
          ),
        );
      }

      // 15% Communities (3 items)
      final communitiesToAdd = communities.take(3).toList();
      if (communitiesToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            communitiesToAdd,
            FeedItemType.community,
            (comm) => 'community_${comm.communityId}',
          ),
        );
      }

      // 15% Auctions (3 items)
      final auctionsToAdd = auctions.take(3).toList();
      if (auctionsToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            auctionsToAdd,
            FeedItemType.auction,
            (auction) => 'auction_${auction.auctionId}',
          ),
        );
      }

      // 10% News (2 items)
      if (news.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.news,
            data: news.first,
            id: 'news_${news.first.newsArticleId}',
          ),
        );
      }

      // 10% Projects (2 items)
      final projectsToAdd = projects.take(2).toList();
      if (projectsToAdd.isNotEmpty) {
        feedItems.addAll(
          _createFeedItems(
            projectsToAdd,
            FeedItemType.project,
            (project) => 'project_${project.projectId}',
          ),
        );
      }

      // 5% Notifications (1 item)
      if (notifications.isNotEmpty) {
        feedItems.add(
          FeedItem(
            type: FeedItemType.notification,
            data: notifications.first,
            id: notifications.first.id,
          ),
        );
      }

      // 5% Developers/Members (1 item)
      if (developers.isNotEmpty) {
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

      // For infinite scroll, shuffle and return items
      feedItems.shuffle(_random);

      // Return all generated items (deduplication handled by explore_page)
      return feedItems;
    } catch (e) {
      print('❌ Error fetching mixed feed: $e');
      // Return fallback notifications on error
      final fallbackNotifications = _generateSmartNotifications(4);
      return fallbackNotifications.map((notif) {
        return FeedItem(
          type: FeedItemType.notification,
          data: notif,
          id: notif.id,
        );
      }).toList();
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

      // Generate notifications
      final notifications = _generateNotifications(3);

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
