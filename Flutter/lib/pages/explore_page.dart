import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../models/feed_notification.dart';
import '../models/community_post.dart';
import '../models/community.dart';
import '../models/news_article.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../services/feed_service.dart';
import '../services/community_post_service.dart';
import '../widgets/feed_notification_card.dart';
import '../widgets/feed_community_card.dart';
import '../widgets/feed_news_card.dart';
import '../widgets/feed_auction_card.dart';
import '../widgets/feed_project_card.dart';
import '../widgets/feed_developer_card.dart';
import '../widgets/feed_member_card.dart';
import '../widgets/post_card.dart';
import 'post_details_page.dart';
import 'auction_details_page.dart';
import 'community_details_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final List<FeedItem> _feedItems = [];
  final ScrollController _scrollController = ScrollController();
  final Set<String> _loadedIds = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Delay initial load to avoid init conflicts
    Future.delayed(Duration.zero, () {
      if (mounted && _feedItems.isEmpty) {
        _loadInitialFeed();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Only check if we can load more
    if (_isLoading || !_hasMore) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    // Load more when within 200px of bottom
    final threshold = position.maxScrollExtent - 200;
    if (position.pixels >= threshold) {
      _loadMoreFeed();
    }
  }

  Future<void> _loadInitialFeed() async {
    if (_isLoading || _feedItems.isNotEmpty) {
      print('⏭️ Skipping initial load - already loading or has items');
      return;
    }

    print('✅ Starting initial feed load');
    setState(() {
      _isLoading = true;
      _feedItems.clear();
      _loadedIds.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    await _loadFeedBatch();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    print('🔄 Loading more feed (page $_currentPage)');
    setState(() => _isLoading = true);

    try {
      _currentPage++;
      await _loadFeedBatch();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFeedBatch() async {
    try {
      print('🔄 Loading feed batch page $_currentPage');

      // Load mixed feed from backend (now handles randomization server-side!)
      final newItems = await FeedService.getMixedFeed(
        page: _currentPage,
        pageSize: 20,
      );

      print('📦 Received ${newItems.length} items from backend feed service');

      // Filter out duplicates (backend should handle this, but double-check)
      final uniqueItems = newItems.where((item) {
        if (_loadedIds.contains(item.id)) {
          return false;
        }
        _loadedIds.add(item.id);
        return true;
      }).toList();

      print('✅ Adding ${uniqueItems.length} unique items to feed');

      if (mounted) {
        setState(() {
          _feedItems.addAll(uniqueItems);
          // Backend now tells us if there's more content
          _hasMore =
              uniqueItems.length >= 20; // Assume more if we got full page
        });
      }
    } catch (e) {
      print('Error loading feed: $e');
      if (mounted) {
        setState(() => _hasMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No content available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount:
          _feedItems.length + (_hasMore ? 1 : (_feedItems.isEmpty ? 0 : 1)),
      itemBuilder: (context, index) {
        // Show loading indicator while loading more
        if (index >= _feedItems.length && _hasMore) {
          return const Padding(
            key: ValueKey('loading_indicator'),
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Show end message if we have items but no more to load
        if (index >= _feedItems.length && !_hasMore && _feedItems.isNotEmpty) {
          return const Padding(
            key: ValueKey('end_message'),
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'You\'ve reached the end! ✨',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        try {
          final item = _feedItems[index];
          // Wrap items in RepaintBoundary with unique keys to prevent layout errors
          return RepaintBoundary(
            key: ValueKey(item.id),
            child: _buildFeedItem(item),
          );
        } catch (e) {
          print('❌ Error building item $index: $e');
          return Card(
            key: ValueKey('error_$index'),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          );
        }
      },
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    try {
      switch (item.type) {
        case FeedItemType.post:
          return _buildPostItem(item.data as CommunityPost);

        case FeedItemType.notification:
          final notif = item.data as FeedNotification;
          return FeedNotificationCard(
            notification: notif,
            onAction: () => _handleNotificationAction(notif),
          );

        case FeedItemType.community:
          final community = item.data as Community;
          return FeedCommunityCard(
            community: community,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CommunityDetailsPage(communityId: community.communityId),
                ),
              );
            },
          );

        case FeedItemType.news:
          final article = item.data as NewsArticle;
          return FeedNewsCard(
            article: article,
            onTap: () {
              // For now just show a snackbar, can add URL launcher later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loading: ${article.title}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );

        case FeedItemType.auction:
          final auction = item.data as Auction;
          return FeedAuctionCard(
            auction: auction,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailsPage(auction: auction),
                ),
              );
            },
          );

        case FeedItemType.project:
          return FeedProjectCard(project: item.data as ProjectModel);

        case FeedItemType.developer:
          return FeedDeveloperCard(developer: item.data as FeaturedDeveloper);

        case FeedItemType.member:
          return FeedMemberCard(member: item.data as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ Error in _buildFeedItem: ${item.type}');
      print('   Error: $e');
      // Return a simple error card instead of crashing
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Error loading ${item.type}',
              style: const TextStyle(color: Colors.red),
            ),
            Text(
              e.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPostItem(CommunityPost post) {
    return PostCard(
      post: post,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(postId: post.postId),
          ),
        );
      },
      onLike: () => _toggleLike(post.postId),
      onComment: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(postId: post.postId),
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(int postId) async {
    final response = await CommunityPostService.toggleLike(postId);
    if (response.success && mounted) {
      setState(() {
        for (var item in _feedItems) {
          if (item.type == FeedItemType.post) {
            final post = item.data as CommunityPost;
            if (post.postId == postId) {
              final wasLiked = post.isLiked;
              post.isLiked = !wasLiked;
              post.likeCount += post.isLiked ? 1 : -1;
              break;
            }
          }
        }
      });
    }
  }

  void _handleNotificationAction(FeedNotification notification) {
    // Handle different notification actions
    print('Notification action: ${notification.type}');

    switch (notification.type) {
      case FeedNotificationType.outbid:
        // Navigate to auction and show bid dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening auction...')));
        break;

      case FeedNotificationType.auctionEnding:
        // Navigate to auction
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening auction...')));
        break;

      case FeedNotificationType.auctionRequest:
        // Navigate to auction request page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening auction request...')),
        );
        break;

      case FeedNotificationType.achievement:
        // Navigate to profile
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening profile...')));
        break;

      case FeedNotificationType.communityInvite:
        // Navigate to community
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening community...')));
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: ${notification.actionText}')),
        );
    }
  }
}
