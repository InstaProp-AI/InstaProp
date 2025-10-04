import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_state.dart';
import '../models/auction.dart';
import '../models/property.dart';
import 'auction_details_page.dart';
import 'add_property_page.dart';
import 'profile_page.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(context, appState),
              _buildAuctionsPage(context, appState),
              _buildValuatePage(context, appState),
              _buildCalendarPage(context, appState),
              _buildProfilePage(context, appState),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPropertyPage(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.gavel_outlined, Icons.gavel, 'Auctions'),
              _buildNavItem(
                2,
                Icons.analytics_outlined,
                Icons.analytics,
                'Valuate',
              ),
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
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey('$index-$isSelected'),
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, AppState appState) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildModernAppBar(context, appState),
          _buildStatsSection(context, appState),
          _buildFeaturedAuctions(context, appState),
          _buildRecentProperties(context, appState),
          _buildQuickActions(context, appState),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, AppState appState) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            'Property Flipper',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (appState.isRefreshing)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!appState.isLoggedIn)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sign in to access all features and save your data',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/auth'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AppState appState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Active Auctions',
                '${appState.activeAuctions.length}',
                Icons.gavel,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Properties',
                '${appState.properties.length}',
                Icons.home,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Total Bids',
                '${appState.auctions.fold(0, (sum, auction) => sum + auction.bidCount)}',
                Icons.trending_up,
                const Color(0xFFFF9800),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedAuctions(BuildContext context, AppState appState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Auctions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => _onNavTap(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appState.loadingAuctions)
              const Center(child: CircularProgressIndicator())
            else if (appState.featuredAuctions.isEmpty)
              _buildEmptyState(
                context,
                'No Featured Auctions',
                'Check back later for new property auctions',
                Icons.gavel_outlined,
              )
            else
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: appState.featuredAuctions.length,
                  itemBuilder: (context, index) {
                    final auction = appState.featuredAuctions[index];
                    return _buildAuctionCard(context, auction);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(BuildContext context, Auction auction) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AuctionDetailsPage(auction: auction),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: auction.property?.imageUrl.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(auction.property!.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: auction.property?.imageUrl.isEmpty != false
                      ? const Icon(Icons.home, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.property?.name ?? 'Property',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.property?.location ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Bid',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            Text(
                              '\$${auction.currentPrice.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bids',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            Text(
                              '${auction.bidCount}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4CAF50),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: auction.isActive
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auction.isActive ? 'Active' : 'Ended',
                        style: TextStyle(
                          color: auction.isActive
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProperties(BuildContext context, AppState appState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Properties',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (appState.loadingProperties)
              const Center(child: CircularProgressIndicator())
            else if (appState.properties.isEmpty)
              _buildEmptyState(
                context,
                'No Properties',
                'No properties available at the moment',
                Icons.home_outlined,
              )
            else
              ...appState.properties
                  .take(3)
                  .map((property) => _buildPropertyTile(context, property)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTile(BuildContext context, Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: const Icon(Icons.home, color: Color(0xFF2E7D32)),
          ),
          title: Text(
            property.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(property.location),
              const SizedBox(height: 4),
              Text(
                '\$${property.startingPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: property.isApproved
                  ? Colors.green[100]
                  : Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              property.isApproved ? 'Approved' : 'Pending',
              style: TextStyle(
                color: property.isApproved
                    ? Colors.green[700]
                    : Colors.orange[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState appState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Add Property',
                    Icons.add_home,
                    const Color(0xFF4CAF50),
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddPropertyPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'View Auctions',
                    Icons.gavel,
                    const Color(0xFF2196F3),
                    () => _onNavTap(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
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
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Placeholder pages for other tabs
  Widget _buildAuctionsPage(BuildContext context, AppState appState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auctions'),
        actions: [
          IconButton(
            onPressed: () => _refreshData(appState),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: appState.loadingAuctions
          ? const Center(child: CircularProgressIndicator())
          : appState.auctions.isEmpty
          ? _buildEmptyState(
              context,
              'No Auctions',
              'No auctions available at the moment',
              Icons.gavel_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.auctions.length,
              itemBuilder: (context, index) {
                final auction = appState.auctions[index];
                return _buildAuctionCard(context, auction);
              },
            ),
    );
  }

  Widget _buildValuatePage(BuildContext context, AppState appState) {
    return const ValuatePage();
  }

  Widget _buildCalendarPage(BuildContext context, AppState appState) {
    return const CalendarPage();
  }

  Widget _buildProfilePage(BuildContext context, AppState appState) {
    return const ProfilePage();
  }

  void _refreshData(AppState appState) {
    appState.loadInitialData();
  }
}

// Property Valuation Page with Demo Functionality
class ValuatePage extends StatefulWidget {
  const ValuatePage({super.key});

  @override
  State<ValuatePage> createState() => _ValuatePageState();
}

class _ValuatePageState extends State<ValuatePage> {
  final _addressController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _yearBuiltController = TextEditingController();

  bool _isLoading = false;
  bool _hasValuation = false;
  double _estimatedValue = 0;
  String _valuationRange = '';
  List<Map<String, dynamic>> _comparableProperties = [];

  @override
  void dispose() {
    _addressController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFeetController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  void _performValuation() {
    if (_addressController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate AI valuation process
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
        _hasValuation = true;
        _estimatedValue = 450000.0 + (Random().nextInt(200000)).toDouble();
        _valuationRange =
            '${(_estimatedValue * 0.9).toStringAsFixed(0)} - ${(_estimatedValue * 1.1).toStringAsFixed(0)}';

        // Generate comparable properties
        _comparableProperties = [
          {
            'address': '123 Oak Street',
            'price': 425000,
            'bedrooms': 3,
            'bathrooms': 2,
            'sqft': 1800,
            'soldDate': '2 months ago',
          },
          {
            'address': '456 Pine Avenue',
            'price': 480000,
            'bedrooms': 4,
            'bathrooms': 3,
            'sqft': 2200,
            'soldDate': '1 month ago',
          },
          {
            'address': '789 Maple Drive',
            'price': 465000,
            'bedrooms': 3,
            'bathrooms': 2.5,
            'sqft': 1950,
            'soldDate': '3 months ago',
          },
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Property Valuation')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.analytics, size: 48, color: Colors.blue[700]),
                      const SizedBox(height: 12),
                      Text(
                        'AI Property Valuation',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get instant property valuations using our advanced AI technology',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Valuation Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Property Address',
                            hintText: 'Enter the full address',
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _bedroomsController,
                                decoration: const InputDecoration(
                                  labelText: 'Bedrooms',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _bathroomsController,
                                decoration: const InputDecoration(
                                  labelText: 'Bathrooms',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _squareFeetController,
                                decoration: const InputDecoration(
                                  labelText: 'Square Feet',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _yearBuiltController,
                                decoration: const InputDecoration(
                                  labelText: 'Year Built',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _performValuation,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.analytics),
                            label: Text(
                              _isLoading ? 'Analyzing...' : 'Get Valuation',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Valuation Results
                if (_hasValuation) ...[
                  const SizedBox(height: 24),

                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Valuation Complete',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Estimated Value',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_estimatedValue.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Range: \$${_valuationRange}',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comparable Properties
                  Text(
                    'Comparable Properties',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._comparableProperties
                      .map(
                        (property) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.home, color: Colors.blue[700]),
                            ),
                            title: Text(property['address']),
                            subtitle: Text(
                              '${property['bedrooms']} bed • ${property['bathrooms']} bath • ${property['sqft']} sqft',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${property['price'].toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  property['soldDate'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],

                // Login Prompt for Unauthenticated Users
                if (!appState.isLoggedIn) ...[
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock, color: Colors.orange[700], size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Save Your Valuations',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to save your property valuations and access advanced features',
                          style: TextStyle(color: Colors.orange[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/auth'),
                          icon: const Icon(Icons.login),
                          label: const Text('Login to Save'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Calendar Page with Demo Functionality
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _generateDemoEvents();
  }

  void _generateDemoEvents() {
    final now = DateTime.now();
    _events = [
      {
        'title': 'Property Viewing - Downtown Condo',
        'date': now.add(const Duration(days: 1)),
        'time': '10:00 AM',
        'type': 'viewing',
      },
      {
        'title': 'Auction Ends - Victorian Home',
        'date': now.add(const Duration(days: 2)),
        'time': '3:00 PM',
        'type': 'auction',
      },
      {
        'title': 'Property Inspection - Modern Townhouse',
        'date': now.add(const Duration(days: 3)),
        'time': '2:00 PM',
        'type': 'inspection',
      },
      {
        'title': 'Bid Deadline - Luxury Penthouse',
        'date': now.add(const Duration(days: 5)),
        'time': '5:00 PM',
        'type': 'bid',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Calendar')),
          body: Column(
            children: [
              // Calendar Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month - 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month + 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Calendar Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCalendarGrid(),
                ),
              ),

              // Events List
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _buildEventCard(context, event);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Login Prompt for Unauthenticated Users
              if (!appState.isLoggedIn)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border(top: BorderSide(color: Colors.orange[200]!)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Login to sync your calendar and manage events',
                          style: TextStyle(color: Colors.orange[600]),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/auth'),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final day = index - firstDayOfWeek + 1;
        final isCurrentMonth = day > 0 && day <= daysInMonth;
        final isToday =
            isCurrentMonth &&
            day == DateTime.now().day &&
            _selectedDate.month == DateTime.now().month &&
            _selectedDate.year == DateTime.now().year;

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isCurrentMonth
                ? (isToday ? const Color(0xFF2E7D32) : Colors.white)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday ? const Color(0xFF2E7D32) : Colors.grey[300]!,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              isCurrentMonth ? day.toString() : '',
              style: TextStyle(
                color: isCurrentMonth
                    ? (isToday ? Colors.white : Colors.black87)
                    : Colors.grey[400],
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getEventColor(event['type']),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Text(
            event['title'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${event['date'].day}/${event['date'].month} at ${event['time']}',
          ),
          trailing: Icon(
            _getEventIcon(event['type']),
            color: _getEventColor(event['type']),
          ),
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'viewing':
        return Colors.blue;
      case 'auction':
        return Colors.green;
      case 'inspection':
        return Colors.orange;
      case 'bid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'viewing':
        return Icons.visibility;
      case 'auction':
        return Icons.gavel;
      case 'inspection':
        return Icons.search;
      case 'bid':
        return Icons.trending_up;
      default:
        return Icons.event;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
