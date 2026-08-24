import '../../theme/app_colors.dart';
import '../../theme/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../models/news_article.dart';
import '../widgets/property_image_carousel.dart';
import '../widgets/capsule_bottom_nav_bar.dart';
import 'auction_details_page.dart';
import 'properties_management_page.dart';
import 'project_details_page.dart';
import 'developer_profile_page.dart';
import 'market_page.dart';
// CommunityFeedPage removed
import 'explore_page.dart';
import 'sales_chats_page.dart';

enum _HomeTab { market, explore, profile }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ExplorePageController _exploreController = ExplorePageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _effectiveSelectedIndex(AppState appState) {
    final tabs = _visibleTabs(appState);
    if (tabs.isEmpty) return 0;

    if (_selectedIndex >= tabs.length) {
      final exploreIndex = tabs.indexOf(_HomeTab.explore);
      return exploreIndex >= 0 ? exploreIndex : 0;
    }

    return _selectedIndex;
  }

  int _defaultTabIndex(AppState appState) {
    final tabs = _visibleTabs(appState);
    if (tabs.isEmpty) return 0;
    final exploreIndex = tabs.indexOf(_HomeTab.explore);
    return exploreIndex >= 0 ? exploreIndex : 0;
  }

  @override
  void initState() {
    super.initState();

    try {
      _animationController = AnimationController(
        duration: AppAnimations.normal, // 300ms
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: AppAnimations.defaultCurve,
        ),
      );

      // Add a small delay before starting animation to prevent assertion errors
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });

      WidgetsBinding.instance.addObserver(this);

      // Default to Explore tab once AppState is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() => _selectedIndex = _defaultTabIndex(appState));
      });

      // Check if user is sales and redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            try {
              final appState = Provider.of<AppState>(context, listen: false);
              if (appState.isLoggedIn && appState.user != null) {
                // Redirect sales users to sales chats page
                if (appState.user?.isSales == true) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SalesChatsPage(),
                    ),
                  );
                  return;
                }
                appState.notificationService.getNotifications();
              }
            } catch (e) {
              print('❌ Error loading notifications: $e');
            }
          }
        });
      });
    } catch (e) {
      print('❌ Error in HomePage initState: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.resumed && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      print('❌ Error in didChangeAppLifecycleState: $e');
    }
  }

  List<_HomeTab> _visibleTabs(AppState appState) {
    final tabs = <_HomeTab>[];
    if (appState.isFeatureEnabled('MarketTab')) {
      tabs.add(_HomeTab.market);
    }
    if (appState.isFeatureEnabled('FeedExplore')) {
      tabs.add(_HomeTab.explore);
    }
    tabs.add(_HomeTab.profile);
    return tabs;
  }

  List<CapsuleNavItem> _navItems(AppState appState) {
    return _visibleTabs(appState).map((tab) {
      switch (tab) {
        case _HomeTab.market:
          return const CapsuleNavItem(
            icon: Icons.store_outlined,
            selectedIcon: Icons.store_rounded,
            label: 'Market',
          );
        case _HomeTab.explore:
          return const CapsuleNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
            label: 'Explore',
          );
        case _HomeTab.profile:
          return const CapsuleNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final selectedIndex = _effectiveSelectedIndex(appState);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSelectedPage(appState, selectedIndex),
          ),
          bottomNavigationBar: _buildBottomNavigation(appState, selectedIndex),
        );
      },
    );
  }

  Widget _buildSelectedPage(AppState appState, int selectedIndex) {
    final tabs = _visibleTabs(appState);
    if (tabs.isEmpty || selectedIndex >= tabs.length) {
      return ExplorePage(controller: _exploreController);
    }

    switch (tabs[selectedIndex]) {
      case _HomeTab.market:
        return const MarketPage();
      case _HomeTab.explore:
        return ExplorePage(controller: _exploreController);
      case _HomeTab.profile:
        return _buildProfilePage(context, appState);
    }
  }

  Widget _buildBottomNavigation(AppState appState, int selectedIndex) {
    final items = _navItems(appState);
    final exploreIndex = _exploreNavIndex(appState);

    return CapsuleBottomNavBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        if (index == selectedIndex) {
          if (exploreIndex >= 0 && index == exploreIndex) {
            _exploreController.scrollToTopAndReload();
          }
          return;
        }

        setState(() {
          _selectedIndex = index;
        });

        if (exploreIndex >= 0 && index == exploreIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _exploreController.scrollToTopAndReload();
          });
        }
      },
      items: items,
    );
  }

  int _exploreNavIndex(AppState appState) {
    return _visibleTabs(appState).indexOf(_HomeTab.explore);
  }

  Future<void> _refreshData(AppState appState) async {
    await appState.loadAuctions();
  }

  Widget _buildProfilePage(BuildContext context, AppState appState) {
    return const PropertiesManagementPage();
  }

  Future<List<NewsArticle>> _getLatestNews(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newsService = NewsService(ApiClient.baseUrl, token: appState.token);
    return await newsService.getLatestNews(count: 3);
  }

  // MINIMAL REDESIGNED WIDGETS

  Widget _buildMinimalHeroSection(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              PropertyImageCarousel(
                images: auction.property?.propertyImages ?? [],
                fallbackImageUrl: auction.property?.imageUrl,
                height: 400,
                showIndicators: true,
                showNavigationButtons: false,
                showImageCounter: false,
              ),
              // Subtle overlay (no gradient, just dark overlay at bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status badge
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Bid',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${auction.currentPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${auction.bidCount}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const Text(
                                  'Bids',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
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

  Widget _buildMinimalSectionHeader(
    BuildContext context,
    String title,
    VoidCallback? onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.7,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalAuctionCard(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 120,
                height: 120,
                color: Colors.grey[100],
                child: auction.property?.imageUrl != null
                    ? Image.network(
                        auction.property!.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.home, size: 40, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.name ?? 'Property',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          auction.property?.location ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${auction.bidCount} bids',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (auction.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildMinimalProjectsGrid(
    BuildContext context,
    List<ProjectModel> projects,
  ) {
    final displayProjects = projects.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: displayProjects.length,
      itemBuilder: (context, index) {
        final project = displayProjects[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsPage(projectId: project.projectId),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${project.propertiesCount} properties',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalDeveloperCard(
    BuildContext context,
    FeaturedDeveloper developer,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeveloperProfilePage(developerId: developer.developerId),
        ),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
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
                      (developer.companyName ?? developer.fullName).isNotEmpty
                          ? (developer.companyName ?? developer.fullName)[0]
                          : 'D',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              developer.companyName ?? developer.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalEmptyState(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPreviewSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // News title with tap to navigate to all news
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/all-news'),
            child: const Text(
              'Latest News',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<NewsArticle>>(
            future: _getLatestNews(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildMinimalEmptyState(
                  context,
                  'No news available',
                  Icons.article_outlined,
                );
              }
              return _buildNewsCarousel(context, snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel(BuildContext context, List<NewsArticle> news) {
    return _AutoScrollingNewsCarousel(news: news);
  }

  // Community preview section removed
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
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % (widget.news.length + 1);
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
    return Column(
      children: [
        // News carousel with reduced height
        SizedBox(
          height: 150, // Reduced from 200 to 150
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.news.length + 1, // +1 for "Show All" card
            itemBuilder: (context, index) {
              if (index == widget.news.length) {
                // "Show All" card
                return _buildShowAllNewsCard(context);
              }
              return _buildNewsCard(context, widget.news[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.news.length + 1, // +1 for "Show All" card
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.blue[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsArticle news) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushNamed('/news/${news.newsArticleId}'),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              news.images.isNotEmpty
                  ? Image.network(
                      news.firstImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
              // Subtle overlay (no gradient, just dark overlay at bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category badge
                        if (news.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              news.categoryDisplayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          news.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowAllNewsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/all-news'),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Show All News',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View all articles',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
