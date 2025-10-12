import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../widgets/auction_timer.dart';
import 'calendar_page.dart';
import 'auction_details_page.dart';
import 'add_property_page.dart';
import 'profile_page.dart';
import 'featured_auctions_page.dart';
import 'auctions_page.dart';
import 'properties_management_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2; // Start on Home page (middle position)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshData(AppState appState) {
    return appState.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return IndexedStack(
            index: _selectedIndex,
            children: [
              const AuctionsPage(), // Index 0: Properties (goes to Auctions)
              const PropertiesManagementPage(), // Index 1: Auctions (goes to Properties)
              _buildHomeContent(context, appState), // Index 2: Home
              _buildCalendarPage(context, appState), // Index 3: Calendar
              _buildProfilePage(context, appState), // Index 4: Profile
            ],
          );
        },
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: null, // FABs are handled within individual pages
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.gavel_outlined, Icons.gavel, 'Auctions'),
              _buildNavItem(
                1,
                Icons.analytics_outlined,
                Icons.analytics,
                'Valuate',
              ),
              _buildNavItem(2, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(
                3,
                Icons.calendar_today_outlined,
                Icons.calendar_today,
                'Calendar',
              ),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData iconOutline,
    IconData iconFilled,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutline,
              color: isSelected ? AppColors.primary : AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.primary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, AppState appState) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(appState),
      color: AppColors.primary,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface.withOpacity(0.08),
                        ),
                      ),
                    ),

                    // Main Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Icon and Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.surface.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.home_work_rounded,
                                  color: AppColors.surface,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: [
                                              AppColors.surface,
                                              AppColors.surface.withOpacity(
                                                0.8,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                      child: Text(
                                        'Property Flipper',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: AppColors.surface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                            ),
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
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Stats Row
                          Row(
                            children: [
                              _buildStatItem(
                                context,
                                'Avg',
                                'Price',
                                '\$${_calculateAveragePropertyPrice(appState).toStringAsFixed(0)}K',
                              ),
                              const SizedBox(width: 20),
                              _buildStatItem(
                                context,
                                'Ending',
                                'Today',
                                '${_getAuctionsEndingToday(appState)}',
                              ),
                              const SizedBox(width: 20),
                              _buildStatItem(
                                context,
                                'Highest',
                                'Bid',
                                '\$${_getHighestBid(appState).toStringAsFixed(0)}K',
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Quick Actions Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  Icons.add_home_rounded,
                                  'Add Property',
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddPropertyPage(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  Icons.gavel_rounded,
                                  'Browse Auctions',
                                  () => setState(() => _selectedIndex = 0),
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
              const SizedBox(height: 24),

              // Login/Signup Prompt for Unauthenticated Users
              if (!appState.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.primary,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unlock Full Potential',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login or sign up to save your progress, manage properties, and participate in auctions.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/auth'),
                            icon: const Icon(Icons.login),
                            label: const Text('Login / Sign Up'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Statistics Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          context,
                          'Active Auctions',
                          appState.activeAuctions.length.toString(),
                          Icons.gavel,
                          AppColors.primary,
                        ),
                        _buildStatCard(
                          context,
                          'Total Properties',
                          appState.properties.length.toString(),
                          Icons.home,
                          AppColors.primary,
                        ),
                        _buildStatCard(
                          context,
                          'Total Bids',
                          appState.auctions
                              .fold<int>(0, (sum, a) => sum + a.bidCount)
                              .toString(),
                          Icons.attach_money,
                          AppColors.secondary,
                        ),
                        _buildStatCard(
                          context,
                          'Users',
                          '3+', // Placeholder for demo
                          Icons.people,
                          AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Featured Auctions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Auctions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FeaturedAuctionsPage(),
                        ),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (appState.loadingAuctions)
                const Center(child: CircularProgressIndicator())
              else if (appState.featuredAuctions.isEmpty)
                _buildEmptyState(
                  context,
                  'No Featured Auctions',
                  'Check back later for exciting new properties!',
                  Icons.star_border,
                )
              else
                SizedBox(
                  height: 320, // Increased height to prevent overflow
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: appState.featuredAuctions.length,
                    itemBuilder: (context, index) {
                      final auction = appState.featuredAuctions[index];
                      return _buildAuctionCard(context, auction);
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // All Auctions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Auctions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AuctionsPage(),
                        ),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (appState.loadingAuctions)
                const Center(child: CircularProgressIndicator())
              else if (appState.auctions.isEmpty)
                _buildEmptyState(
                  context,
                  'No Auctions',
                  'New auctions will be listed soon!',
                  Icons.gavel_outlined,
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appState.auctions.length > 6
                      ? 6
                      : appState.auctions.length,
                  itemBuilder: (context, index) {
                    final auction = appState.auctions[index];
                    return _buildAuctionListItem(context, auction);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.surface.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.surface.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.surface.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.surface, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  auction.property?.imageUrl ??
                      'https://via.placeholder.com/280x150',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: AppColors.background,
                    child: Icon(Icons.broken_image, color: AppColors.secondary),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              auction.property?.name ?? 'Unknown Property',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${auction.bidCount}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auction.property?.location ?? 'Unknown Location',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                                  'Start',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                                Text(
                                  '\$${auction.startPrice.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                        fontSize: 12,
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
                                  'Current',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                                Text(
                                  '\$${auction.currentPrice.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 12,
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
                                  'Time Left',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                                AuctionTimer(
                                  auction: auction,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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

  Widget _buildAuctionListItem(BuildContext context, Auction auction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  auction.property?.imageUrl ??
                      'https://via.placeholder.com/80x80',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    width: 80,
                    color: AppColors.background,
                    child: Icon(Icons.broken_image, color: AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction.property?.name ?? 'Unknown Property',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: auction.isActive
                                ? AppColors.background
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auction.isActive ? 'Active' : 'Ended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: auction.isActive
                                  ? AppColors.primary
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.property?.location ?? 'Unknown Location',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Current: \$${auction.currentPrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${auction.bidCount} bids',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder pages for other tabs

  Widget _buildCalendarPage(BuildContext context, AppState appState) {
    return const CalendarPage();
  }

  Widget _buildProfilePage(BuildContext context, AppState appState) {
    return const ProfilePage();
  }

  // Helper methods for calculating unique statistics
  double _calculateAveragePropertyPrice(AppState appState) {
    if (appState.properties.isEmpty) return 0.0;

    // Calculate based on auction prices instead
    final totalPrice = appState.auctions.fold<double>(
      0.0,
      (sum, auction) => sum + auction.startPrice,
    );

    return appState.auctions.isNotEmpty
        ? (totalPrice / appState.auctions.length) /
              1000 // Convert to thousands
        : 0.0;
  }

  int _getAuctionsEndingToday(AppState appState) {
    final today = DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return appState.auctions.where((auction) {
      return auction.endAt.isAfter(today) && auction.endAt.isBefore(todayEnd);
    }).length;
  }

  double _getHighestBid(AppState appState) {
    if (appState.auctions.isEmpty) return 0.0;

    final highestCurrentPrice = appState.auctions
        .map((auction) => auction.currentPrice)
        .reduce((a, b) => a > b ? a : b);

    return highestCurrentPrice / 1000; // Convert to thousands
  }
}
