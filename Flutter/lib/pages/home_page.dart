import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
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
import 'developers_list_page.dart';
import 'chat_list_page.dart';
import 'market_hub_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0; // Start on Home tab
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );

      // Add a small delay before starting animation to prevent assertion errors
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });

      WidgetsBinding.instance.addObserver(this);

      // Load notifications when home page opens with delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            try {
              final appState = Provider.of<AppState>(context, listen: false);
              if (appState.isLoggedIn && appState.user != null) {
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
            return _buildHomeContent(appState);
          case 1:
            return const MarketHubPage();
          case 2:
            return _buildValuationPage(context, appState);
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
          // Minimal Clean Header
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Premium Real Estate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text(
                'Discover',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Featured Auction
                if (appState.auctions.isNotEmpty)
                  _buildMinimalHeroSection(context, appState.auctions.first),

                const SizedBox(height: 32),

                // Points Display Section
                _buildPointsDisplaySection(context, appState),

                const SizedBox(height: 32),

                // Live Auctions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMinimalSectionHeader(context, 'Live Auctions', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FeaturedAuctionsPage(),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      if (appState.loadingAuctions)
                        const Center(child: CircularProgressIndicator())
                      else if (appState.auctions.isEmpty)
                        _buildMinimalEmptyState(
                          context,
                          'No live auctions',
                          Icons.gavel_outlined,
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appState.auctions.length > 4
                              ? 4
                              : appState.auctions.length,
                          itemBuilder: (context, index) {
                            final auction = appState.auctions[index];
                            return _buildMinimalAuctionCard(context, auction);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Featured Projects
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMinimalSectionHeader(context, 'Projects', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProjectsListPage(),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
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
                            return _buildMinimalEmptyState(
                              context,
                              'No projects available',
                              Icons.folder_outlined,
                            );
                          }
                          return _buildMinimalProjectsGrid(
                            context,
                            snapshot.data!,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Top Developers
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMinimalSectionHeader(
                        context,
                        'Developers',
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DevelopersListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMinimalEmptyState(
                              context,
                              'No developers',
                              Icons.people_outlined,
                            ),
                          );
                        }
                        return SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
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
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Portfolio',
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
              // Image
              PropertyImageCarousel(
                images: auction.property?.propertyImages ?? [],
                fallbackImageUrl: auction.property?.imageUrl,
                height: 400,
                showIndicators: true,
                showNavigationButtons: false,
                showImageCounter: false,
              ),
              // Gradient overlay
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
              // Content
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
                      (developer.companyName ?? developer.firstName)[0],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              developer.companyName ?? developer.firstName,
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

  Widget _buildPointsDisplaySection(BuildContext context, AppState appState) {
    if (appState.user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.stars, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            // Points Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${appState.user!.currentPoints}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'pts',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Current Points (Spendable)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appState.user!.totalEarnedPoints} total earned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Rewards Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/rewards');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
