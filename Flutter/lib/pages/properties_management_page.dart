import '../../theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import '../models/bid.dart';
import '../models/auction.dart';
import '../services/bid_service.dart';
import 'add_property_page.dart';
import 'valuate_page.dart';
import 'my_properties_page.dart';
import 'auction_details_page.dart';
import 'auctions_page.dart';
import 'create_auction_request_dialog.dart';
import '../widgets/loading_button.dart';

class PropertiesManagementPage extends StatefulWidget {
  const PropertiesManagementPage({super.key});

  @override
  State<PropertiesManagementPage> createState() =>
      _PropertiesManagementPageState();
}

class _PropertiesManagementPageState extends State<PropertiesManagementPage> {
  List<Bid> _myBids = [];
  bool _loadingBids = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AppState>().isLoggedIn) {
        context.read<AppState>().loadProperties();
        _loadMyBids();
      }
    });
  }

  Future<void> _loadMyBids() async {
    print('🔄 Loading my bids...');
    setState(() {
      _loadingBids = true;
    });

    try {
      final response = await BidService.getUserBids();
      print(
        '📊 My Bids Response - Success: ${response.success}, Data: ${response.data?.length}, Error: ${response.error}',
      );

      if (response.success && response.data != null) {
        print('✅ Loaded ${response.data!.length} bids');
        for (var bid in response.data!) {
          print(
            '  Bid #${bid.bidId}: \$${bid.bidAmount} on Auction #${bid.auctionId}',
          );
          print('    Has auction data: ${bid.auction != null}');
          if (bid.auction != null) {
            print(
              '    Auction property: ${bid.auction!.property?.name ?? "No property"}',
            );
          }
        }
        setState(() {
          _myBids = response.data!;
          _loadingBids = false;
        });
      } else {
        print('❌ Failed to load bids: ${response.error}');
        setState(() {
          _myBids = [];
          _loadingBids = false;
        });
      }
    } catch (e) {
      print('❌ Error loading my bids: $e');
      setState(() {
        _myBids = [];
        _loadingBids = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoggedIn) {
            return _buildLoggedInContent(context, appState);
          } else {
            return _buildNotLoggedInContent(context, appState);
          }
        },
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${appState.user?.firstName}! 👋',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage properties & valuations',
                  style: TextStyle(
                    color: AppColors.surface.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // My Bids Section
          _buildMyBidsSection(appState),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.add_home_work,
                  title: 'Add Property',
                  subtitle: 'List your property',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPropertyPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.assessment,
                  title: 'Get Valuation',
                  subtitle: 'Detailed analysis',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ValuatePage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // My Properties Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Properties',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPropertiesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.view_list),
                label: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Properties List
          if (appState.loadingProperties)
            const Center(child: CircularProgressIndicator())
          else if (appState.userProperties.isEmpty)
            _buildEmptyPropertiesState(context)
          else
            _buildPropertiesList(context, appState),

          const SizedBox(height: 32),

          // My Auctions Section
          _buildMyAuctionsSection(context, appState),
        ],
      ),
    );
  }

  Widget _buildMyBidsSection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'My Bids',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (_loadingBids) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        if (!_loadingBids && _myBids.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary!, AppColors.primary!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Bids Yet',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start bidding on properties you love!',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to auctions page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuctionsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text(
                      'Browse Auctions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!_loadingBids)
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _myBids.length,
              itemBuilder: (context, index) {
                final bid = _myBids[index];
                final auction =
                    bid.auction ??
                    appState.auctions.firstWhere(
                      (a) => a.auctionId == bid.auctionId,
                      orElse: () => Auction(
                        auctionId: bid.auctionId,
                        propertyId: 0,
                        startPrice: 0,
                        currentPrice: bid.bidAmount,
                        startAt: DateTime.now(),
                        duration: 0,
                        bidCount: 0,
                        status: 'Unknown',
                        createdAt: DateTime.now(),
                      ),
                    );
                return _buildBidCard(bid, auction);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBidCard(Bid bid, Auction auction) {
    final isWinning = auction.currentPrice == bid.bidAmount;
    final property = auction.property;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isWinning ? Colors.green : AppColors.secondary!,
            width: isWinning ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuctionDetailsPage(auction: auction),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      property?.imageUrl != null &&
                          property!.imageUrl.isNotEmpty
                      ? Image.network(
                          property.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.background,
                              child: const Icon(
                                Icons.home,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),

              // Bid Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property?.name ?? 'Property #${auction.propertyId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Bid',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '\$${bid.bidAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Current',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '\$${auction.currentPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isWinning
                                    ? AppColors.primary
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWinning
                            ? AppColors.background
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isWinning
                              ? Colors.green[200]!
                              : AppColors.secondary!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWinning ? Icons.emoji_events : Icons.pending,
                            size: 14,
                            color: isWinning
                                ? AppColors.primary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isWinning ? 'Winning!' : 'Outbid',
                            style: TextStyle(
                              color: isWinning
                                  ? AppColors.primary
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
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

  Widget _buildNotLoggedInContent(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Property Management',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get property valuations and manage your listings',
                  style: TextStyle(
                    color: AppColors.surface.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Valuation Section
          Text(
            'Quick Property Valuation',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Get an instant estimate of your property value',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),

          _buildActionCard(
            context,
            icon: Icons.assessment,
            title: 'Quick Estimate',
            subtitle: 'Basic property valuation',
            color: Colors.blue,
            onTap: () {
              _showQuickValuationDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // Login Prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Want More Features?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign up to add your own properties, get detailed valuations, and manage your listings.',
                  style: TextStyle(color: AppColors.primary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to auth page
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Sign Up Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPropertiesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary!),
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'No Properties Yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first property to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPropertyPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(BuildContext context, AppState appState) {
    return Column(
      children: appState.userProperties.take(3).map((property) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                property.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: AppColors.background,
                    child: const Icon(Icons.home, color: Colors.grey),
                  );
                },
              ),
            ),
            title: Text(
              property.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(property.location),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: property.isApproved
                    ? AppColors.background
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                property.isApproved ? 'Approved' : 'Pending',
                style: TextStyle(
                  color: property.isApproved
                      ? AppColors.primary
                      : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPropertiesPage(),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyAuctionsSection(BuildContext context, AppState appState) {
    final userAuctions = appState.userAuctions;
    final liveAuctions = userAuctions.where((a) => a.isActive).toList();
    final endedAuctions = userAuctions.where((a) => a.isEnded).toList();
    final requestedAuctions = userAuctions
        .where((a) => a.status == 'Requested')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Auctions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreateAuctionRequestDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Auction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Auctions
        if (liveAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Live Auctions',
            liveAuctions,
            Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Requested Auctions
        if (requestedAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Requested Auctions',
            requestedAuctions,
            Colors.orange,
          ),
          const SizedBox(height: 16),
        ],

        // Ended Auctions
        if (endedAuctions.isNotEmpty) ...[
          _buildAuctionSubsection(
            context,
            'Ended Auctions',
            endedAuctions,
            Colors.grey,
          ),
          const SizedBox(height: 16),
        ],

        // Empty State
        if (userAuctions.isEmpty) _buildEmptyAuctionsState(context),
      ],
    );
  }

  Widget _buildAuctionSubsection(
    BuildContext context,
    String title,
    List auctions,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${auctions.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...auctions
            .take(3)
            .map((auction) => _buildAuctionCard(context, auction, color)),
        if (auctions.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                // Navigate to full auctions page with filter
                // This could be implemented later
              },
              child: Text('View all ${auctions.length} ${title.toLowerCase()}'),
            ),
          ),
      ],
    );
  }

  Widget _buildAuctionCard(BuildContext context, auction, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailsPage(auction: auction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Property Image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: auction.property?.imageUrl.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          auction.property!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.home,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(Icons.home, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),

              // Auction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.property?.name ?? 'Unknown Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auction.property?.location ?? 'Unknown Location',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${auction.currentPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auction.status,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Icon
              Icon(
                auction.isActive
                    ? Icons.play_circle
                    : auction.isEnded
                    ? Icons.check_circle
                    : Icons.schedule,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAuctionsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary!),
      ),
      child: Column(
        children: [
          Icon(Icons.gavel_outlined, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'No Auctions Yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first auction request to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateAuctionRequestDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Auction Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickValuationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuickValuationDialog();
      },
    );
  }
}

class QuickValuationDialog extends StatefulWidget {
  @override
  State<QuickValuationDialog> createState() => _QuickValuationDialogState();
}

class _QuickValuationDialogState extends State<QuickValuationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _estimateResult;

  @override
  void initState() {
    super.initState();
    _yearBuiltController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFeetController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  Future<void> _getEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _estimateResult = null;
    });

    try {
      // Call the public estimation API
      final response = await http.post(
        Uri.parse('http://localhost:5284/api/Property/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': _locationController.text,
          'bedrooms': int.parse(_bedroomsController.text),
          'bathrooms': int.parse(_bathroomsController.text),
          'squareFeet': int.parse(_squareFeetController.text),
          'yearBuilt': int.parse(_yearBuiltController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _estimateResult = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get estimate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Property Estimate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.surface),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_estimateResult == null) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return 'Location is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bedrooms',
                              prefixIcon: Icon(Icons.bed),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Bathrooms',
                              prefixIcon: Icon(Icons.bathtub),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _squareFeetController,
                            decoration: const InputDecoration(
                              labelText: 'Square Feet',
                              prefixIcon: Icon(Icons.square_foot),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _yearBuiltController,
                            decoration: const InputDecoration(
                              labelText: 'Year Built',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        onPressed: _isLoading ? null : _getEstimate,
                        isLoading: _isLoading,
                        child: const Text('Get Estimate'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show estimate result
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assessment, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Estimated Value',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_estimateResult!['estimatedValue'].toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _estimateResult!['confidence'],
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _estimateResult!['message'],
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _estimateResult = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  child: const Text('Get Another Estimate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
