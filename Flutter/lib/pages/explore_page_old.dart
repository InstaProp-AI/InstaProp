import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community.dart';
import '../models/community_post.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../models/news_article.dart';
import '../services/community_service.dart';
import '../services/community_post_service.dart';
import '../services/project_service.dart';
import '../services/developer_service.dart';
import '../services/news_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/community_card.dart';
import '../widgets/post_card.dart';
import '../widgets/property_image_carousel.dart';
import 'post_details_page.dart';
import 'auction_details_page.dart';
import 'featured_auctions_page.dart';
import 'project_details_page.dart';
import 'developers_list_page.dart';
import 'developer_profile_page.dart';
import 'projects_list_page.dart';
import 'dart:async';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Data
  List<Community> _trendingCommunities = [];
  List<Community> _suggestedCommunities = [];
  List<CommunityPost> _trendingPosts = [];
  List<NewsArticle> _latestNews = [];
  List<Auction> _liveAuctions = [];
  List<ProjectModel> _featuredProjects = [];
  List<FeaturedDeveloper> _topDevelopers = [];
  List<dynamic> _popularMembers = [];

  // Loading states
  bool _isLoading = false;
  bool _hasMorePosts = true;
  int _currentPostPage = 1;

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMorePosts &&
        !_isLoading) {
      _loadMorePosts();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadTrendingCommunities(),
      _loadSuggestedCommunities(),
      _loadTrendingPosts(),
      _loadLatestNews(),
      _loadLiveAuctions(),
      _loadFeaturedProjects(),
      _loadTopDevelopers(),
      _loadPopularMembers(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadTrendingCommunities() async {
    final response = await CommunityService.getTrendingCommunities();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _trendingCommunities = response.data as List<Community>;
      });
    }
  }

  Future<void> _loadSuggestedCommunities() async {
    final response = await CommunityService.getSuggestedCommunities();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _suggestedCommunities = response.data as List<Community>;
      });
    }
  }

  Future<void> _loadTrendingPosts() async {
    setState(() => _isLoading = true);
    final response = await CommunityPostService.getFeed(
      sort: 'hot',
      page: 1,
      pageSize: 10,
    );
    if (response.success && response.data != null && mounted) {
      setState(() {
        _trendingPosts = response.data!;
        _currentPostPage = 1;
        _hasMorePosts = response.data!.length >= 10;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    setState(() => _isLoading = true);
    final response = await CommunityPostService.getFeed(
      sort: 'hot',
      page: _currentPostPage + 1,
      pageSize: 10,
    );
    if (response.success && response.data != null && mounted) {
      setState(() {
        _trendingPosts.addAll(response.data!);
        _currentPostPage++;
        _hasMorePosts = response.data!.length >= 10;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadLatestNews() async {
    try {
      final news = await NewsService(ApiClient.baseUrl).getLatestNews(count: 5);
      if (mounted) {
        setState(() {
          _latestNews = news;
        });
      }
    } catch (e) {
      print('Error loading news: $e');
    }
  }

  Future<void> _loadLiveAuctions() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.auctions.isNotEmpty) {
      setState(() {
        _liveAuctions = appState.auctions;
      });
    }
  }

  Future<void> _loadFeaturedProjects() async {
    try {
      final projects = await ProjectService(
        ApiClient.baseUrl,
      ).getTrendingProjects();
      if (mounted) {
        setState(() {
          _featuredProjects = projects;
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _loadTopDevelopers() async {
    try {
      final developers = await DeveloperService(
        ApiClient.baseUrl,
      ).getFeaturedDevelopers();
      if (mounted) {
        setState(() {
          _topDevelopers = developers;
        });
      }
    } catch (e) {
      print('Error loading developers: $e');
    }
  }

  Future<void> _loadPopularMembers() async {
    final response = await CommunityService.getPopularMembers();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _popularMembers = response.data as List<dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Minimal AppBar
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: const FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Explore',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),

            // Hero Section - Featured Auction
            if (_liveAuctions.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FeaturedAuctionsPage(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                    _buildHeroSection(_liveAuctions.first),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // Trending Communities
            if (_trendingCommunities.isNotEmpty)
              _buildHorizontalSection(
                title: 'Trending Communities',
                icon: Icons.trending_up,
                onSeeAll: null,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _trendingCommunities.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: 12),
                        child: CommunityCard(
                          community: _trendingCommunities[index],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Latest News
            if (_latestNews.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.newspaper, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Latest News',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: _AutoScrollingNewsCarousel(news: _latestNews),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // Trending Posts
            if (_trendingPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_fire_department, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Trending Posts',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Posts List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < _trendingPosts.length) {
                  final post = _trendingPosts[index];
                  return PostCard(
                    post: post,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PostDetailsPage(postId: post.postId),
                        ),
                      );
                    },
                    onLike: () => _toggleLike(post.postId),
                    onComment: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PostDetailsPage(postId: post.postId),
                        ),
                      );
                    },
                  );
                } else if (_hasMorePosts) {
                  _loadMorePosts();
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }, childCount: _trendingPosts.length + (_hasMorePosts ? 1 : 0)),
            ),

            // Live Auctions
            if (_liveAuctions.isNotEmpty && _liveAuctions.length > 1)
              _buildHorizontalSection(
                title: 'Live Auctions',
                icon: Icons.gavel,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeaturedAuctionsPage(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _liveAuctions.take(5).length,
                    itemBuilder: (context, index) {
                      final auction = _liveAuctions[index];
                      return _buildAuctionCard(auction);
                    },
                  ),
                ),
              ),

            // Featured Projects
            if (_featuredProjects.isNotEmpty)
              _buildHorizontalSection(
                title: 'Featured Projects',
                icon: Icons.apartment,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectsListPage(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _featuredProjects.take(5).length,
                    itemBuilder: (context, index) {
                      final project = _featuredProjects[index];
                      return _buildProjectCard(project);
                    },
                  ),
                ),
              ),

            // Top Developers
            if (_topDevelopers.isNotEmpty)
              _buildHorizontalSection(
                title: 'Top Developers',
                icon: Icons.star,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DevelopersListPage(),
                    ),
                  );
                },
                child: SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _topDevelopers.take(5).length,
                    itemBuilder: (context, index) {
                      final developer = _topDevelopers[index];
                      return _buildDeveloperCard(developer);
                    },
                  ),
                ),
              ),

            // Suggested Communities
            if (_suggestedCommunities.isNotEmpty)
              _buildHorizontalSection(
                title: 'Suggested for You',
                icon: Icons.lightbulb,
                onSeeAll: null,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _suggestedCommunities.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: 12),
                        child: CommunityCard(
                          community: _suggestedCommunities[index],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Popular Members
            if (_popularMembers.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.people, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Popular Members',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _popularMembers.take(5).length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final member = _popularMembers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                member['firstName']?[0]?.toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              '${member['firstName']} ${member['lastName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${member['postCount'] ?? 0} posts • ${member['reputationPoints'] ?? 0} rep',
                            ),
                            trailing: const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (onSeeAll != null)
                  TextButton(onPressed: onSeeAll, child: const Text('See All')),
              ],
            ),
          ),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PropertyImageCarousel(
                images: auction.property?.propertyImages ?? [],
                fallbackImageUrl: auction.property?.imageUrl,
                height: 400,
                showIndicators: true,
                showNavigationButtons: false,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (auction.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        auction.property?.name ?? 'Featured Property',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              auction.property?.location ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionCard(Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 100,
                color: Colors.grey[200],
                child: auction.property?.imageUrl != null
                    ? Image.network(
                        auction.property!.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.home, size: 32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.name ?? 'Property',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProjectDetailsPage(projectId: project.projectId),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Icon(Icons.apartment, size: 40),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.propertiesCount} properties',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(FeaturedDeveloper developer) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DeveloperProfilePage(developerId: developer.developerId),
        ),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[200],
              backgroundImage: developer.profileImageUrl != null
                  ? NetworkImage(developer.profileImageUrl!)
                  : null,
              child: developer.profileImageUrl == null
                  ? Text(
                      (developer.companyName ?? developer.firstName)[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              developer.companyName ?? developer.firstName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  developer.rating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(int postId) async {
    final response = await CommunityPostService.toggleLike(postId);
    if (response.success && mounted) {
      setState(() {
        for (var post in _trendingPosts) {
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
}

class _AutoScrollingNewsCarousel extends StatefulWidget {
  final List<NewsArticle> news;

  const _AutoScrollingNewsCarousel({required this.news});

  @override
  State<_AutoScrollingNewsCarousel> createState() =>
      _AutoScrollingNewsCarouselState();
}

class _AutoScrollingNewsCarouselState
    extends State<_AutoScrollingNewsCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.news.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    if (widget.news.isNotEmpty) {
      _timer.cancel();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.news.length;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: widget.news.length,
      itemBuilder: (context, index) {
        final news = widget.news[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildNewsCard(news),
        );
      },
    );
  }

  Widget _buildNewsCard(NewsArticle news) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushNamed('/news/${news.newsArticleId}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: news.images.isNotEmpty
              ? Image.network(news.firstImageUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.article_outlined, size: 48),
                  ),
                ),
        ),
      ),
    );
  }
}
