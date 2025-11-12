import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../models/feed_notification.dart';
import '../models/community_post.dart';
import '../models/community.dart';
import '../models/news_article.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../models/deal_highlight.dart';
import '../models/project_story.dart';
import '../models/investor_milestone.dart';
import '../services/feed_service.dart';
import '../services/community_post_service.dart';
import '../widgets/feed_notification_card.dart';
import '../widgets/feed_community_card.dart';
import '../widgets/feed_news_card.dart';
import '../widgets/feed_auction_card.dart';
import '../widgets/feed_project_card.dart';
import '../widgets/feed_developer_card.dart';
import '../widgets/feed_member_card.dart';
import '../widgets/deal_highlight_card.dart';
import '../widgets/project_story_card.dart';
import '../widgets/investor_milestone_card.dart';
import '../widgets/post_card.dart';
import '../widgets/feed_live_stream_card.dart';
import '../widgets/feed_valuation_prompt_card.dart';
import '../widgets/feed_payment_reminder_card.dart';
import '../widgets/feed_post_composer.dart';
import '../theme/app_colors.dart';
import '../core/router/app_router.dart';
import 'post_details_page.dart';
import 'auction_details_page.dart';
import 'community_details_page.dart';
import 'community_list_page.dart';
import 'chat_list_page.dart';
import 'project_details_page.dart';
import 'news_detail_page.dart';
import 'live_stream_player_page.dart';
import '../models/live_stream.dart';
import '../models/valuation_prompt.dart';
import '../models/payment_reminder.dart';

class ExplorePageController {
  Future<void> Function()? _refreshCallback;

  Future<void> scrollToTopAndReload() async {
    final callback = _refreshCallback;
    if (callback != null) {
      await callback();
    }
  }

  void _attach(Future<void> Function() callback) {
    _refreshCallback = callback;
  }

  void _detach() {
    _refreshCallback = null;
  }
}

class ExplorePage extends StatefulWidget {
  final ExplorePageController? controller;

  const ExplorePage({super.key, this.controller});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final List<FeedItem> _feedItems = [];
  final ScrollController _scrollController = ScrollController();
  final Set<String> _loadedIds = {};
  static const int _pageSize = 20;

  late final PageController _featuredPageController;
  late final PageController _storyPageController;
  int _featuredPageIndex = 0;
  int _storyPageIndex = 0;

  bool _isLoading = false;
  bool _isInitialLoading =
      true; // Track initial load separately from pagination
  bool _hasMore = true;
  int _currentPage = 1;
  DateTime? _lastScrollCheck; // Debounce scroll checking

  @override
  void initState() {
    super.initState();
    _featuredPageController = PageController(viewportFraction: 0.88);
    _storyPageController = PageController(viewportFraction: 0.82);
    widget.controller?._attach(_handleExternalRefresh);
    // Delay initial load to avoid init conflicts
    Future.delayed(Duration.zero, () {
      if (mounted && _feedItems.isEmpty) {
        _loadInitialFeed();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_handleExternalRefresh);
    }
  }

  List<FeedItem> _takeItemsOfType(
    FeedItemType type,
    Set<String> consumedIds, {
    int limit = 3,
  }) {
    final selected = <FeedItem>[];
    for (final item in _feedItems) {
      if (item.type == type && !consumedIds.contains(item.id)) {
        selected.add(item);
        consumedIds.add(item.id);
        if (selected.length >= limit) break;
      }
    }
    return selected;
  }

  Future<void> _handleExternalRefresh() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    await _loadInitialFeed();
  }

  List<Widget> _buildFeaturedDealsSlivers(List<FeedItem> items) {
    final highlights = items
        .map((item) => item.data)
        .whereType<DealHighlight>()
        .toList(growable: false);
    if (highlights.isEmpty) {
      return const [];
    }

    return [
      SliverToBoxAdapter(
        child: _buildSectionHeader(
          'Featured Deals',
          subtitle: 'Hot auctions with serious momentum',
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _featuredPageController,
                  itemCount: highlights.length,
                  onPageChanged: (index) {
                    setState(() => _featuredPageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final highlight = highlights[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == highlights.length - 1 ? 16 : 8,
                        bottom: 12,
                      ),
                      child: DealHighlightCard(
                        highlight: highlight,
                        onTap: () => _openHighlight(highlight),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _buildDotsIndicator(
                currentIndex: _featuredPageIndex,
                total: highlights.length,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildProjectStoriesSlivers(List<FeedItem> items) {
    final stories = items
        .map((item) => item.data)
        .whereType<ProjectStory>()
        .toList(growable: false);
    if (stories.isEmpty) {
      return const [];
    }

    return [
      SliverToBoxAdapter(
        child: _buildSectionHeader(
          'Project Stories',
          subtitle: 'See how developments are progressing this week',
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _storyPageController,
                  itemCount: stories.length,
                  onPageChanged: (index) =>
                      setState(() => _storyPageIndex = index),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 12,
                        right: index == stories.length - 1 ? 16 : 12,
                        bottom: 12,
                      ),
                      child: ProjectStoryCard(
                        story: story,
                        onViewProject: () => _openProjectStory(story),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              _buildDotsIndicator(
                currentIndex: _storyPageIndex,
                total: stories.length,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildInvestorSpotlightSlivers(List<FeedItem> items) {
    final milestones = items
        .map((item) => item.data)
        .whereType<InvestorMilestone>()
        .toList(growable: false);
    if (milestones.isEmpty) {
      return const [];
    }

    return [
      SliverToBoxAdapter(
        child: _buildSectionHeader(
          'Investor Spotlight',
          subtitle: 'Celebrating portfolio wins across the community',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final milestone = milestones[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == milestones.length - 1 ? 20 : 12,
                ),
                child: InvestorMilestoneCard(
                  milestone: milestone,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Celebrating ${milestone.investorName}\'s achievement!',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: milestones.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDiscoverySlivers(List<FeedItem> items) {
    if (items.isEmpty) {
      return const [
        SliverToBoxAdapter(child: SizedBox(height: 24)),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: _buildSectionHeader(
          'Endless Discovery',
          subtitle: 'Keep scrolling for more opportunities',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 32 : 16,
                ),
                child: RepaintBoundary(
                  key: ValueKey(item.id),
                  child: _buildFeedItem(item),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    Widget? trailing,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotsIndicator({
    required int currentIndex,
    required int total,
  }) {
    if (total <= 1) return const SizedBox(height: 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 20 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  void _openHighlight(DealHighlight highlight) {
    final placeholderAuction = Auction(
      auctionId: highlight.auctionId,
      propertyId: highlight.propertyId,
      property: null,
      startPrice: highlight.startPrice,
      currentPrice: highlight.currentPrice,
      startAt: highlight.endAt.subtract(const Duration(hours: 2)),
      duration: 2,
      bidCount: highlight.bidCount,
      status: highlight.isEndingSoon ? 'Active' : 'Approved',
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailsPage(auction: placeholderAuction),
      ),
    );
  }

  void _openProjectStory(ProjectStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(
          projectId: story.projectId,
        ),
      ),
    );
  }

  void _openNewsArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(news: article),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller?._detach();
    _featuredPageController.dispose();
    _storyPageController.dispose();
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
      _currentPage = 0;
      _hasMore = true;
    });

    final newItems = await _fetchUniqueFeedItems(page: 1);

    if (!mounted) return;

    setState(() {
      _isInitialLoading = false; // Clear initial loading state
      if (newItems.isNotEmpty) {
        _feedItems.addAll(newItems);
        _loadedIds.addAll(newItems.map((item) => item.id));
        _currentPage = 1;
        _hasMore = true;
      } else {
        _hasMore = false;
      }
    });
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
      final nextPage = _currentPage + 1;
      final newItems = await _fetchUniqueFeedItems(page: nextPage);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (newItems.isNotEmpty) {
          _feedItems.addAll(newItems);
          _loadedIds.addAll(newItems.map((item) => item.id));
          _currentPage = nextPage;
          _hasMore = true;
        } else {
          _hasMore = false;
        }
      });
    } catch (e) {
      print('Error in _loadMoreFeed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<FeedItem>> _fetchUniqueFeedItems({required int page}) async {
    try {
      print('🔄 Loading feed batch page $page');

      // Load mixed feed from backend (now handles randomization server-side!)
      final newItems = await FeedService.getMixedFeed(
        page: page,
        pageSize: _pageSize,
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
        return true;
      }).toList();

      // Guard against duplicate IDs within same batch
      final seenIds = <String>{};
      final dedupedItems = uniqueItems.where((item) {
        if (seenIds.contains(item.id)) {
          print('❌ Duplicate detected: ${item.id}');
          return false;
        }
        seenIds.add(item.id);
        print('✅ New item: ${item.id}');
        return true;
      }).toList();

      print('✅ ${dedupedItems.length} unique items ready to add');
      return dedupedItems;
    } catch (e, stackTrace) {
      print('❌ Error loading feed: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return [];
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
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_2_outlined),
            tooltip: 'Community',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityListPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    final consumedIds = <String>{};

    final featuredDeals =
        _takeItemsOfType(FeedItemType.dealHighlight, consumedIds, limit: 5);
    final projectStories =
        _takeItemsOfType(FeedItemType.projectStory, consumedIds, limit: 6);
    final investorSpotlight =
        _takeItemsOfType(FeedItemType.investorMilestone, consumedIds, limit: 4);
    final discoveryItems = _feedItems
        .where((item) => !consumedIds.contains(item.id))
        .toList(growable: false);

    final slivers = <Widget>[];

    slivers.add(
      SliverToBoxAdapter(
        child: FeedPostComposer(
          onPostCreated: () {
            _feedItems.clear();
            _loadedIds.clear();
            _currentPage = 1;
            _loadInitialFeed();
          },
        ),
      ),
    );

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

    slivers.addAll(_buildQuickActionSlivers(context));

    if (featuredDeals.isNotEmpty) {
      slivers.addAll(_buildFeaturedDealsSlivers(featuredDeals));
    }

    if (projectStories.isNotEmpty) {
      slivers.addAll(_buildProjectStoriesSlivers(projectStories));
    }

    if (investorSpotlight.isNotEmpty) {
      slivers.addAll(_buildInvestorSpotlightSlivers(investorSpotlight));
    }

    slivers.addAll(_buildDiscoverySlivers(discoveryItems));

    if (_isLoading && _hasMore) {
      slivers.add(_buildLoadingSliver());
    }

    return RefreshIndicator(
      onRefresh: () async {
        _feedItems.clear();
        _loadedIds.clear();
        _currentPage = 1;
        await _loadInitialFeed();
      },
      color: const Color(0xFF6200EE),
      child: CustomScrollView(
        key: const ValueKey('explore_scroll_view'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  List<Widget> _buildQuickActionSlivers(BuildContext context) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(
                context,
                label: 'Explore Auctions',
                icon: Icons.gavel_outlined,
                routeName: AppRouter.auctions,
              ),
              _buildQuickActionChip(
                context,
                label: 'Add Property',
                icon: Icons.add_home_work_outlined,
                routeName: AppRouter.addProperty,
              ),
              _buildQuickActionChip(
                context,
                label: 'Market Insights',
                icon: Icons.show_chart_outlined,
                routeName: AppRouter.market,
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
    ];
  }

  Widget _buildQuickActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String routeName,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: () => AppRouter.navigateTo(context, routeName),
      backgroundColor: AppColors.background,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.secondary),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    try {
      late Widget card;
      switch (item.type) {
        case FeedItemType.post:
          card = _buildPostItem(item.data as CommunityPost);
          break;

        case FeedItemType.notification:
          final notif = item.data as FeedNotification;
          card = FeedNotificationCard(
            notification: notif,
            onAction: () => _handleNotificationAction(notif),
          );
          break;

        case FeedItemType.community:
          final community = item.data as Community;
          card = FeedCommunityCard(
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
          break;

        case FeedItemType.news:
          final article = item.data as NewsArticle;
          card = FeedNewsCard(
            article: article,
            onTap: () => _openNewsArticle(article),
          );
          break;

        case FeedItemType.auction:
          final auction = item.data as Auction;
          card = FeedAuctionCard(
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
          break;

        case FeedItemType.project:
          card = FeedProjectCard(project: item.data as ProjectModel);
          break;

        case FeedItemType.developer:
          card = FeedDeveloperCard(developer: item.data as FeaturedDeveloper);
          break;

        case FeedItemType.member:
          card = FeedMemberCard(member: item.data as Map<String, dynamic>);
          break;

        case FeedItemType.dealHighlight:
          final highlight = item.data as DealHighlight;
          card = DealHighlightCard(
            highlight: highlight,
            onTap: () => _openHighlight(highlight),
          );
          break;

        case FeedItemType.projectStory:
          final story = item.data as ProjectStory;
          card = ProjectStoryCard(
            story: story,
            onViewProject: () => _openProjectStory(story),
          );
          break;

        case FeedItemType.investorMilestone:
          final milestone = item.data as InvestorMilestone;
          card = InvestorMilestoneCard(
            milestone: milestone,
            onTap: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Celebrating ${milestone.investorName}\'s achievement!',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
          break;

        case FeedItemType.livestream:
          final stream = item.data as LiveStream;
          card = FeedLiveStreamCard(
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
          break;

        case FeedItemType.valuationPrompt:
          final prompt = item.data as ValuationPrompt;
          card = FeedValuationPromptCard(
            prompt: prompt,
            onTap: () {
              if (prompt.propertyId != null) {
                Navigator.pushNamed(
                  context,
                  '/valuation/${prompt.propertyId}',
                );
              } else {
                Navigator.pushNamed(context, '/valuation');
              }
            },
          );
          break;

        case FeedItemType.paymentReminder:
          final reminder = item.data as PaymentReminder;
          card = FeedPaymentReminderCard(
            reminder: reminder,
            onTap: () {
              Navigator.pushNamed(context, '/calendar');
            },
            onSetReminder: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder set successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
          break;
      }
      return card;
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
