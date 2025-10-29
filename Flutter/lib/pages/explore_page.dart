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
import '../widgets/feed_live_stream_card.dart';
import '../widgets/feed_valuation_prompt_card.dart';
import '../widgets/feed_payment_reminder_card.dart';
import 'post_details_page.dart';
import 'auction_details_page.dart';
import 'community_details_page.dart';
import 'create_post_page.dart';
import 'live_stream_player_page.dart';
import '../models/live_stream.dart';
import '../models/valuation_prompt.dart';
import '../models/payment_reminder.dart';

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
  bool _isInitialLoading =
      true; // Track initial load separately from pagination
  bool _hasMore = true;
  int _currentPage = 1;
  DateTime? _lastScrollCheck; // Debounce scroll checking

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
    // Debounce scroll checking to avoid excessive checks
    final now = DateTime.now();
    if (_lastScrollCheck != null &&
        now.difference(_lastScrollCheck!).inMilliseconds < 100) {
      return; // Skip this scroll event
    }
    _lastScrollCheck = now;

    // Only check if we can load more
    if (_isLoading || !_hasMore) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    // Load more when within 800px of bottom (larger threshold to reduce frequency)
    final threshold = position.maxScrollExtent - 800;
    if (position.pixels >= threshold) {
      print(
        '📍 Triggering load more - position ${position.pixels} / ${position.maxScrollExtent}',
      );
      _loadMoreFeed();
    }
  }

  Future<void> _loadInitialFeed() async {
    if (_isInitialLoading && _feedItems.isNotEmpty) {
      print('⏭️ Skipping initial load - already loading or has items');
      return;
    }

    print('✅ Starting initial feed load');
    setState(() {
      _isInitialLoading = true; // Set initial loading state
      _feedItems.clear();
      _loadedIds.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    await _loadFeedBatch();

    if (mounted) {
      setState(() {
        _isInitialLoading = false; // Clear initial loading state
      });
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoading || !_hasMore) {
      print(
        '⏭️ Skipping load more - _isLoading=$_isLoading, _hasMore=$_hasMore',
      );
      return;
    }

    print('🔄 Loading more feed (page $_currentPage)');

    setState(() {
      _isLoading = true; // Update UI immediately to prevent duplicate triggers
    });

    try {
      _currentPage++;
      await _loadFeedBatch();
      // setState is called inside _loadFeedBatch, so we don't need it here
    } catch (e) {
      print('Error in _loadMoreFeed: $e');
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
      print('🔍 Checking ${newItems.length} items for duplicates...');
      print(
        '🔍 _loadedIds contains ${_loadedIds.length} IDs: ${_loadedIds.take(5).toList()}',
      );

      final uniqueItems = newItems.where((item) {
        if (_loadedIds.contains(item.id)) {
          print('❌ Duplicate detected: ${item.id}');
          return false;
        }
        _loadedIds.add(item.id);
        print('✅ New item: ${item.id}');
        return true;
      }).toList();

      print('✅ Adding ${uniqueItems.length} unique items to feed');

      // Always add items, even if empty (to clear loading state)
      if (mounted) {
        setState(() {
          if (uniqueItems.isNotEmpty) {
            _feedItems.addAll(uniqueItems);
          }
          _isLoading = false; // Clear loading state
          _hasMore = true; // Never stop scrolling!
        });

        print('🎯 Feed items now: ${_feedItems.length}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading feed: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = true; // Keep trying even on error
        });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostPage(),
            ),
          );
          if (result == true) {
            // Refresh feed after creating post
            _feedItems.clear();
            _loadedIds.clear();
            _currentPage = 1;
            _loadInitialFeed();
          }
        },
        backgroundColor: const Color(0xFF6200EE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // Only show full-screen loading spinner on initial load
    // During pagination, keep content visible and show small indicator at bottom
    if (_isInitialLoading && _feedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedItems.isEmpty && !_isInitialLoading) {
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

    return RefreshIndicator(
      onRefresh: () async {
        _feedItems.clear();
        _loadedIds.clear();
        _currentPage = 1;
        await _loadInitialFeed();
      },
      color: const Color(0xFF6200EE),
      child: ListView.builder(
        key: const ValueKey(
          'infinite_feed_list',
        ), // Stable key for efficient rebuilds
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
        itemCount: _feedItems.isEmpty
            ? 0
            : (_feedItems.length + 1), // +1 for loading indicator
        itemBuilder: (context, index) {
          // Show loading indicator only when actually loading
          if (index >= _feedItems.length && _hasMore) {
            if (!_isLoading) {
              return const SizedBox.shrink(); // Don't show anything when not loading
            }

            return const Padding(
              key: ValueKey('loading_indicator'),
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          // Never show "end" message - infinite scrolling!

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
      ),
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

        case FeedItemType.livestream:
          final stream = item.data as LiveStream;
          return FeedLiveStreamCard(
            stream: stream,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamPlayerPage(stream: stream),
                ),
              );
            },
          );

        case FeedItemType.valuationPrompt:
          final prompt = item.data as ValuationPrompt;
          return FeedValuationPromptCard(
            prompt: prompt,
            onTap: () {
              // Navigate to valuation page
              // TODO: Implement navigation to valuation page
              if (prompt.propertyId != null) {
                // Navigate to property-specific valuation
                Navigator.pushNamed(
                  context,
                  '/valuation/${prompt.propertyId}',
                );
              } else {
                // Navigate to generic valuation or sign up
                Navigator.pushNamed(context, '/valuation');
              }
            },
          );

        case FeedItemType.paymentReminder:
          final reminder = item.data as PaymentReminder;
          return FeedPaymentReminderCard(
            reminder: reminder,
            onTap: () {
              // Navigate to calendar/events page
              Navigator.pushNamed(context, '/calendar');
            },
            onSetReminder: () {
              // TODO: Implement set reminder functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder set successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
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
    final metadata = notification.metadata;

    // Navigate based on metadata IDs
    if (metadata?['auctionId'] != null) {
      // Navigate to auction details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(
            auction: Auction(
              auctionId: metadata!['auctionId'] as int,
              propertyId: 0,
              startPrice: 0,
              currentPrice: 0,
              startAt: DateTime.now(),
              duration: 0,
              bidCount: 0,
              status: 'active',
              createdAt: DateTime.now(),
            ),
          ),
        ),
      );
    } else if (metadata?['propertyId'] != null) {
      // Navigate to property details
      Navigator.pushNamed(context, '/property/${metadata!['propertyId']}');
    } else if (metadata?['eventId'] != null) {
      // Navigate to calendar
      Navigator.pushNamed(context, '/calendar');
    } else {
      // Show generic message for other types
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notification.title)));
    }
  }
}
