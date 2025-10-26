import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/community_post_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/active_members_carousel.dart';
import '../widgets/community_stats_card.dart';
import '../widgets/community_welcome_banner.dart';
import '../widgets/community_empty_state.dart';
import 'post_details_page.dart';

class CommunityDetailsPage extends StatefulWidget {
  final int communityId;

  const CommunityDetailsPage({super.key, required this.communityId});

  @override
  State<CommunityDetailsPage> createState() => _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends State<CommunityDetailsPage> {
  Community? _community;
  List<CommunityPost> _posts = [];
  List<dynamic> _members = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  bool _isLoadingPosts = false;
  bool _isLoadingMembers = false;
  bool _isLoadingStats = false;
  String _sortOption = 'hot';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _showWelcomeBanner = false;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
    _loadPosts();
    _loadMembers();
    _loadStats();
  }

  Future<void> _loadCommunity() async {
    setState(() => _isLoading = true);
    final response = await CommunityService.getCommunity(widget.communityId);
    if (response.success && response.data != null) {
      setState(() => _community = response.data);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final response = await CommunityService.getCommunityMembers(
      widget.communityId,
    );
    if (response.success && response.data != null) {
      setState(() => _members = response.data as List<dynamic>);
    }
    setState(() => _isLoadingMembers = false);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final response = await CommunityService.getCommunityStats(
      widget.communityId,
    );
    if (response.success && response.data != null) {
      setState(() => _stats = response.data);
    }
    setState(() => _isLoadingStats = false);
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoadingPosts) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() => _isLoadingPosts = true);
    final response = await CommunityPostService.getCommunityPosts(
      widget.communityId,
      sort: _sortOption,
      page: _currentPage,
      pageSize: 20,
    );

    if (response.success && response.data != null) {
      setState(() {
        if (refresh) {
          _posts = response.data!;
        } else {
          _posts.addAll(response.data!);
        }
        _currentPage++;
        _hasMore = response.data!.length >= 20;
      });
    }
    setState(() => _isLoadingPosts = false);
  }

  Future<void> _toggleLike(int postId) async {
    final response = await CommunityPostService.toggleLike(postId);
    if (response.success) {
      setState(() {
        for (var post in _posts) {
          if (post.postId == postId) {
            final wasLiked = post.isLiked;
            post.isLiked = !wasLiked;
            post.likeCount += post.isLiked ? 1 : -1;
            break;
          }
        }
      });
    }
  }

  Future<void> _joinCommunity() async {
    if (_community == null) return;

    final response = await CommunityService.joinCommunity(
      _community!.communityId,
    );
    if (response.success) {
      await _loadCommunity(); // Reload to update isJoined status
      await _loadMembers(); // Reload members
      await _loadStats(); // Reload stats

      // Show welcome banner
      if (mounted) {
        setState(() => _showWelcomeBanner = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined community successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to join community'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_community?.name ?? 'Community'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (_sortOption != value) {
                setState(() => _sortOption = value);
                _loadPosts(refresh: true);
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky join banner
          if (_community != null &&
              !_community!.isJoined &&
              !_community!.isLocked &&
              _community!.canJoin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join to post and comment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Be part of the conversation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _joinCommunity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Welcome Banner
          if (_showWelcomeBanner && _community != null)
            CommunityWelcomeBanner(
              communityName: _community!.name,
              memberCount: _stats?['memberCount'] ?? _community!.memberCount,
              onDismiss: () {
                setState(() => _showWelcomeBanner = false);
              },
            ),
          // Active Members Carousel
          if (_members.isNotEmpty && _community?.isJoined == true)
            ActiveMembersCarousel(
              members: _members,
              totalCount: _stats?['memberCount'] ?? _members.length,
            ),
          // Community Stats
          if (_stats != null && _community?.isJoined == true)
            CommunityStatsCard(stats: _stats!),
          // Posts list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPosts(refresh: true),
              child: _posts.isEmpty && !_isLoadingPosts
                  ? Center(
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
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _posts.isEmpty
                  ? CommunityEmptyState(
                      isJoined: _community?.isJoined ?? false,
                      onPost: () {
                        // TODO: Navigate to create post page
                      },
                    )
                  : ListView.builder(
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          if (_hasMore) {
                            _loadPosts();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final post = _posts[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: PostCard(
                                  post: post,
                                  showCommunity: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailsPage(
                                          postId: post.postId,
                                        ),
                                      ),
                                    ).then((_) => _loadPosts(refresh: true));
                                  },
                                  onLike: () => _toggleLike(post.postId),
                                  onComment: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailsPage(
                                          postId: post.postId,
                                        ),
                                      ),
                                    ).then((_) => _loadPosts(refresh: true));
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
