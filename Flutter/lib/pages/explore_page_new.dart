import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/feed_notification_card.dart';
import '../widgets/feed_community_card.dart';
import '../widgets/feed_news_card.dart';
import '../widgets/feed_auction_card.dart';
import '../widgets/feed_project_card.dart';
import '../widgets/feed_developer_card.dart';
import '../widgets/feed_member_card.dart';
import '../widgets/post_card.dart';
import 'post_details_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final List<FeedItem> _feedItems = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final Set<String> _loadedIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Preload at item 12-15 (not at end)
    if (_feedItems.length >= 12 && !_isLoading && _hasMore) {
      final scrollPosition = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Trigger at ~60% scroll (around item 12-15 in a 20-item batch)
      if (scrollPosition >= maxScroll * 0.6) {
        _loadMoreFeed();
      }
    }
  }

  Future<void> _loadInitialFeed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _feedItems.clear();
      _loadedIds.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    await _loadFeedBatch();

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    _currentPage++;
    await _loadFeedBatch();

    setState(() => _isLoading = false);
  }

  Future<void> _loadFeedBatch() async {
    try {
      // Get auctions from app state
      final appState = Provider.of<AppState>(context, listen: false);

      // Load mixed feed
      final newItems = await FeedService.getMixedFeed(
        page: _currentPage,
        pageSize: 20,
      );

      // Filter out duplicates
      final uniqueItems = newItems.where((item) {
        if (_loadedIds.contains(item.id)) {
          return false;
        }
        _loadedIds.add(item.id);
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _feedItems.addAll(uniqueItems);
          _hasMore =
              uniqueItems.length >= 15; // Continue if we got enough items
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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadInitialFeed,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              centerTitle: true,
            ),

            // Feed Items
            if (_feedItems.isEmpty && _isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your feed...',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else if (_feedItems.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No content available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _feedItems.length) {
                    return _buildFeedItem(_feedItems[index]);
                  } else if (_hasMore) {
                    // Show loading indicator at bottom
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    // End of feed
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'You\'re all caught up! 🎉',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                }, childCount: _feedItems.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    switch (item.type) {
      case FeedItemType.post:
        return _buildPostItem(item.data as CommunityPost);

      case FeedItemType.notification:
        return FeedNotificationCard(
          notification: item.data as FeedNotification,
          onAction: () =>
              _handleNotificationAction(item.data as FeedNotification),
        );

      case FeedItemType.community:
        return FeedCommunityCard(community: item.data as Community);

      case FeedItemType.news:
        return FeedNewsCard(news: item.data as NewsArticle);

      case FeedItemType.auction:
        return FeedAuctionCard(auction: item.data as Auction);

      case FeedItemType.project:
        return FeedProjectCard(project: item.data as ProjectModel);

      case FeedItemType.developer:
        return FeedDeveloperCard(developer: item.data as FeaturedDeveloper);

      case FeedItemType.member:
        return FeedMemberCard(member: item.data as Map<String, dynamic>);
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
