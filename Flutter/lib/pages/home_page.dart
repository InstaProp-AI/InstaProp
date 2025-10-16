import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/property.dart';
import '../models/project_model.dart';
import '../models/developer_profile.dart';
import '../services/project_service.dart';
import '../services/developer_service.dart';
import '../services/api_client.dart';
import '../widgets/property_image_carousel.dart';
import 'profile_page.dart';
import 'featured_auctions_page.dart';
import 'auctions_page.dart';
import 'auction_details_page.dart';
import 'properties_management_page.dart';
import 'projects_list_page.dart';
import 'project_details_page.dart';
import 'developer_profile_page.dart';
import 'chat_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 2; // Start on Home tab
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);

    // Load notifications when home page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.isLoggedIn && appState.user != null) {
        appState.notificationService.getNotifications();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSelectedPage(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSelectedPage() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        switch (_selectedIndex) {
          case 0:
            return const AuctionsPage();
          case 1:
            return _buildValuationPage(context, appState);
          case 2:
            return _buildHomeContent(appState);
          case 3:
            return const ChatListPage();
          case 4:
            return _buildProfilePage(context, appState);
          default:
            return _buildHomeContent(appState);
        }
      },
    );
  }

  Widget _buildHomeContent(AppState appState) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(appState),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Sticky Header with Logo and App Name
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            shadowColor: AppColors.primary.withOpacity(0.1),
            surfaceTintColor: AppColors.surface,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculate collapse ratio
                // When fully expanded: constraints.maxHeight = 270 + status bar
                // When collapsed: constraints.maxHeight = app bar height (~56)
                final statusBarHeight = MediaQuery.of(context).padding.top;
                final appBarHeight = kToolbarHeight;
                final expandedHeight = 270.0;

                // Calculate how much the app bar is collapsed (0 = expanded, 1 = collapsed)
                final collapseRatio =
                    ((expandedHeight +
                                statusBarHeight -
                                constraints.maxHeight) /
                            (expandedHeight - appBarHeight))
                        .clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Main gradient header (visible when expanded)
                    FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.primaryGradient,
                            stops: [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.surface.withOpacity(
                                            0.25,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.home_work,
                                        color: AppColors.surface,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Property Flipper',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  color: AppColors.surface,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 26,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Premium Real Estate Auctions',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: AppColors.surface
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Platform Statistics
                                          Consumer<AppState>(
                                            builder: (context, appState, _) =>
                                                _buildHeaderStats(appState),
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
                      ),
                    ),

                    // Compact header (visible when collapsed)
                    if (collapseRatio > 0.5)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: collapseRatio,
                          child: Container(
                            height: kToolbarHeight + statusBarHeight,
                            color: AppColors.surface,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.home_work,
                                        color: AppColors.surface,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Property Flipper',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Notification system removed - now integrated in chatbot
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section - Featured Auction
                if (appState.auctions.isNotEmpty)
                  _buildHeroSection(context, appState.auctions.first),

                const SizedBox(height: 24),

                // Photo Grid Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeaderMinimal(
                        context,
                        'Explore Properties',
                        Icons.grid_view,
                      ),
                      const SizedBox(height: 12),
                      if (appState.auctions.isNotEmpty)
                        _buildPropertyPhotoGrid(context, appState.auctions),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Live Auctions Carousel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionHeaderWithAction(
                        context,
                        'Live Now',
                        'View All',
                        Icons.bolt,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FeaturedAuctionsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (appState.loadingAuctions)
                      const Center(child: CircularProgressIndicator())
                    else if (appState.auctions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEmptyState(
                          context,
                          'No live auctions',
                          Icons.gavel_outlined,
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: appState.auctions.length > 5
                              ? 5
                              : appState.auctions.length,
                          itemBuilder: (context, index) {
                            final auction = appState.auctions[index];
                            return _buildCompactAuctionCard(context, auction);
                          },
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Featured Projects - Different Layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeaderWithAction(
                        context,
                        'Featured Projects',
                        'Explore',
                        Icons.apartment,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProjectsListPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProjectModel>>(
                        future: ProjectService(
                          ApiClient.baseUrl,
                        ).getTrendingProjects(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState(
                              context,
                              'No projects available',
                              Icons.folder_outlined,
                            );
                          }
                          return _buildProjectsGrid(context, snapshot.data!);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top Developers - Horizontal List
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionHeaderMinimal(
                        context,
                        'Top Developers',
                        Icons.verified,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<FeaturedDeveloper>>(
                      future: DeveloperService(
                        ApiClient.baseUrl,
                      ).getFeaturedDevelopers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildEmptyState(
                              context,
                              'No featured developers',
                              Icons.people_outlined,
                            ),
                          );
                        }
                        return SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final developer = snapshot.data![index];
                              return _buildMinimalDeveloperCard(
                                context,
                                developer,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Trending Auctions - List View
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeaderWithAction(
                        context,
                        'Trending Now',
                        'See All',
                        Icons.trending_up,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AuctionsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (appState.loadingAuctions)
                        const Center(child: CircularProgressIndicator())
                      else if (appState.auctions.isEmpty)
                        _buildEmptyState(
                          context,
                          'No auctions available',
                          Icons.gavel_outlined,
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appState.auctions.length > 3
                              ? 3
                              : appState.auctions.length,
                          itemBuilder: (context, index) {
                            final auction = appState.auctions[index];
                            return _buildTrendingAuctionItem(context, auction);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(AppState appState) {
    final stats = [
      {
        'value':
            '${appState.dashboardStats?.activeAuctions ?? appState.auctions.length}',
        'label': 'Live',
        'icon': Icons.gavel,
        'color': AppColors.primary,
      },
      {
        'value': '${appState.dashboardStats?.totalBids ?? 0}',
        'label': 'Bids',
        'icon': Icons.trending_up,
        'color': AppColors.primary,
      },
      {
        'value':
            '\$${_formatVolume(appState.dashboardStats?.totalVolume ?? 0)}',
        'label': 'Volume',
        'icon': Icons.attach_money,
        'color': AppColors.primary,
      },
      {
        'value': '+${appState.dashboardStats?.totalUsers ?? 0}',
        'label': 'Users',
        'icon': Icons.people,
        'color': AppColors.primary,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.map((stat) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (stat['color'] as Color),
                (stat['color'] as Color).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (stat['color'] as Color).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(stat['icon'] as IconData, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    stat['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onViewAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                color: AppColors.background,
              ),
              child: Stack(
                children: [
                  auction.property?.imageUrl.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: Image.network(
                            auction.property!.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.home,
                              color: AppColors.secondary,
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(Icons.home, color: AppColors.secondary, size: 40),
                  // Status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: auction.isUpcoming
                            ? AppColors.primary
                            : (auction.isActive
                                  ? AppColors.primary
                                  : AppColors.secondary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auction.isUpcoming
                            ? 'UPCOMING'
                            : (auction.isActive ? 'LIVE' : 'ENDED'),
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.location ?? 'Unknown Location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Property Type Chip
                      _buildPropertyTypeTag(auction.property?.type),
                      const SizedBox(width: 8),
                      // Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auction.property?.category ?? 'Category',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price and details
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${auction.currentPrice.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Bids',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${auction.bidCount}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Time',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: auction.isActive
                                    ? AppColors.background
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                auction.timeRemaining,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: auction.isActive
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                      fontSize: 9,
                                      letterSpacing: -0.2,
                                    ),
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

  Widget _buildAuctionItem(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: auction.property?.imageUrl.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        auction.property!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.home,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(Icons.home, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.location ?? 'Unknown Location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Property Type Chip
                      _buildPropertyTypeTag(auction.property?.type),
                      const SizedBox(width: 6),
                      // Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          auction.property?.category ?? 'Category',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${auction.bidCount} bids',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        auction.timeRemaining,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: auction.isActive
                              ? AppColors.primary
                              : AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${auction.currentPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: auction.isUpcoming
                        ? AppColors.primary
                        : (auction.isActive
                              ? AppColors.primary
                              : AppColors.background),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auction.isUpcoming
                        ? 'UPCOMING'
                        : (auction.isActive ? 'LIVE' : 'ENDED'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: auction.isUpcoming
                          ? AppColors.surface
                          : (auction.isActive
                                ? AppColors.surface
                                : AppColors.secondary),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Icon(icon, size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.secondary, width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_rounded),
            label: 'Auctions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData(AppState appState) async {
    await appState.loadAuctions();
  }

  Widget _buildValuationPage(BuildContext context, AppState appState) {
    return const PropertiesManagementPage();
  }

  Widget _buildProfilePage(BuildContext context, AppState appState) {
    return const ProfilePage();
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailsPage(projectId: project.projectId),
        ),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.featuredImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.network(
                  project.featuredImageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 140, color: AppColors.background),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.propertiesCount} properties',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.developerName,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(project.developerRating.toStringAsFixed(1)),
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

  Widget _buildDeveloperCard(
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: developer.profileImageUrl != null
                  ? NetworkImage(developer.profileImageUrl!)
                  : null,
              child: developer.profileImageUrl == null
                  ? Text(
                      developer.firstName[0],
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              developer.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  developer.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${developer.activeProjectsCount} projects',
              style: const TextStyle(fontSize: 11, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeTag(PropertyType? type) {
    final isPrimary = type == PropertyType.primary;
    final backgroundColor = isPrimary ? Colors.blue[100]! : Colors.purple[100]!;
    final borderColor = isPrimary ? Colors.blue[400]! : Colors.purple[400]!;
    final textColor = isPrimary ? Colors.blue[900]! : Colors.purple[900]!;
    final text = isPrimary ? 'Primary' : 'Resale';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.new_releases : Icons.recycling,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // NEW REDESIGNED WIDGETS

  Widget _buildHeroSection(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        height: 350,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PropertyImageCarousel(
                images: auction.property?.propertyImages ?? [],
                fallbackImageUrl: auction.property?.imageUrl,
                height: 350,
                showIndicators: false,
                showNavigationButtons: false,
                showImageCounter: false,
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: auction.isActive ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auction.isActive ? 'LIVE NOW' : 'ENDING SOON',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auction.property?.name ?? 'Featured Property',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          auction.property?.location ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Bid',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${auction.currentPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${auction.bidCount}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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

  Widget _buildQuickStatsGrid(AppState appState) {
    final stats = [
      {
        'value':
            '${appState.dashboardStats?.activeAuctions ?? appState.auctions.length}',
        'label': 'Live',
        'icon': Icons.gavel,
        'color': Colors.green,
      },
      {
        'value': '${appState.dashboardStats?.totalBids ?? 0}',
        'label': 'Bids',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'value':
            '\$${_formatVolume(appState.dashboardStats?.totalVolume ?? 0)}',
        'label': 'Volume',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      },
      {
        'value': '+${appState.dashboardStats?.totalUsers ?? 0}',
        'label': 'Users',
        'icon': Icons.people,
        'color': Colors.orange,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: stats.map((stat) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (stat['color'] as Color).withOpacity(0.1),
                (stat['color'] as Color).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (stat['color'] as Color).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stat['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyPhotoGrid(BuildContext context, List<Auction> auctions) {
    final displayAuctions = auctions.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: displayAuctions.length,
      itemBuilder: (context, index) {
        final auction = displayAuctions[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailsPage(auction: auction),
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                  child: auction.property?.imageUrl != null
                      ? Image.network(
                          auction.property!.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Icon(Icons.home, size: 40, color: Colors.grey[500]),
                ),
              ),
              // Price overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactAuctionCard(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary!),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: auction.property?.imageUrl != null
                        ? Image.network(
                            auction.property!.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.home, size: 40, color: Colors.grey[500]),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: auction.isActive ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auction.isActive ? 'LIVE' : 'ENDING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.property?.name ?? 'Property',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${auction.currentPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${auction.bidCount} bids',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildSectionHeaderMinimal(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithAction(
    BuildContext context,
    String title,
    String actionText,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary!,
                    AppColors.primary!.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Text(
                actionText,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsGrid(BuildContext context, List<ProjectModel> projects) {
    final displayProjects = projects.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary!),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary!.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment,
                      size: 40,
                      color: AppColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.location ?? 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${project.propertiesCount ?? 0} Properties',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: developer.profileImageUrl != null
                  ? NetworkImage(developer.profileImageUrl!)
                  : null,
              child: developer.profileImageUrl == null
                  ? Text(
                      developer.firstName[0],
                      style: const TextStyle(fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              developer.firstName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 10, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  '${developer.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingAuctionItem(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailsPage(auction: auction),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary!),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: auction.property?.imageUrl != null
                    ? Image.network(
                        auction.property!.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.home, size: 30, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          auction.property?.name ?? 'Property',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPropertyTypeTag(auction.property?.type),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          auction.property?.location ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Bid',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '\$${auction.currentPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${auction.bidCount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
}
