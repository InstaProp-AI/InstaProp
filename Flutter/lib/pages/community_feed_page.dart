import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../services/community_post_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';
import 'community_list_page.dart';
import 'post_details_page.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortOption = 'hot'; // hot, new, top

  // Simplified feeds - removed Trending tab (moved to Explore)
  List<CommunityPost> _allFeedPosts = [];
  List<CommunityPost> _myFeedPosts = [];
  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  int _currentPageAll = 1;
  int _currentPageMy = 1;
  bool _hasMoreAll = true;
  bool _hasMoreMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeeds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds({bool refresh = false}) async {
    if (refresh) {
      _currentPageAll = 1;
      _currentPageMy = 1;
      _hasMoreAll = true;
      _hasMoreMy = true;
    }

    // Load All Feed
    if (_hasMoreAll && _tabController.index == 0) {
      setState(() => _isLoadingAll = true);
      final response = await CommunityPostService.getFeed(
        sort: _sortOption,
        page: _currentPageAll,
        pageSize: 20,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (refresh) {
            _allFeedPosts = response.data!;
          } else {
            _allFeedPosts.addAll(response.data!);
          }
          _currentPageAll++;
          _hasMoreAll = response.data!.length >= 20;
        });
      }
      setState(() => _isLoadingAll = false);
    }

    // Load My Feed
    if (_hasMoreMy && _tabController.index == 1) {
      setState(() => _isLoadingMy = true);
      final response = await CommunityPostService.getFeed(
        sort: _sortOption,
        page: _currentPageMy,
        pageSize: 20,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (refresh) {
            _myFeedPosts = response.data!;
          } else {
            _myFeedPosts.addAll(response.data!);
          }
          _currentPageMy++;
          _hasMoreMy = response.data!.length >= 20;
        });
      }
      setState(() => _isLoadingMy = false);
    }
  }

  Future<void> _toggleLike(int postId, int index) async {
    final response = await CommunityPostService.toggleLike(postId);
    if (response.success) {
      setState(() {
        // Update both feeds if the post exists
        for (var post in _allFeedPosts) {
          if (post.postId == postId) {
            final wasLiked = post.isLiked;
            post.isLiked = !wasLiked;
            post.likeCount += post.isLiked ? 1 : -1;
            break;
          }
        }
        for (var post in _myFeedPosts) {
          if (post.postId == postId) {
            final wasLiked = post.isLiked;
            post.isLiked = !wasLiked;
            post.likeCount += post.isLiked ? 1 : -1;
            break;
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Failed to like post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityListPage(),
                ),
              );
            },
            tooltip: 'Communities',
          ),
          _buildSortMenu(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined, size: 20), text: 'All Feed'),
            Tab(icon: Icon(Icons.person, size: 20), text: 'My Feed'),
          ],
          onTap: (index) {
            // Load feed when tab changes
            _loadFeeds();
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeed(_allFeedPosts, _isLoadingAll, _hasMoreAll),
          _buildFeed(_myFeedPosts, _isLoadingMy, _hasMoreMy),
        ],
      ),
    );
  }

  Widget _buildFeed(List<CommunityPost> posts, bool isLoading, bool hasMore) {
    if (posts.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Join communities to see posts',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFeeds(refresh: true),
      child: ListView.builder(
        itemCount: posts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            // Load more
            _loadFeeds();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = posts[index];
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
            onLike: () => _toggleLike(post.postId, index),
            onComment: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(postId: post.postId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (_sortOption != value) {
          setState(() => _sortOption = value);
          _loadFeeds(refresh: true);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'hot',
          child: Row(
            children: [
              Icon(Icons.local_fire_department, size: 20),
              SizedBox(width: 8),
              Text('Hot'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              Icon(Icons.new_releases, size: 20),
              SizedBox(width: 8),
              Text('Newest'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'top',
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20),
              SizedBox(width: 8),
              Text('Top'),
            ],
          ),
        ),
      ],
    );
  }
}
