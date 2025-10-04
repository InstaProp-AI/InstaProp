import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/auction.dart';
import 'auction_details_page.dart';

class FeaturedAuctionsPage extends StatelessWidget {
  const FeaturedAuctionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Auctions'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.loadingAuctions) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.featuredAuctions.isEmpty) {
            return _buildEmptyState(
              context,
              'No Featured Auctions',
              'Check back later for new featured property auctions',
              Icons.star_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () => appState.loadAuctions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.featuredAuctions.length,
              itemBuilder: (context, index) {
                final auction = appState.featuredAuctions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFeaturedAuctionCard(context, auction),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedAuctionCard(BuildContext context, Auction auction) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuctionDetailsPage(auction: auction),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Property Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                width: 140,
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
                    ? const Icon(Icons.home, size: 40, color: Colors.grey)
                    : null,
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Name
                        Text(
                          auction.property?.name ?? 'Property',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Location
                        Text(
                          auction.property?.location ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Current Price
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bid Count
                        Row(
                          children: [
                            Icon(
                              Icons.gavel,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${auction.bidCount} bids',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),

                        // Status Badge
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
                  ],
                ),
              ),
            ),
          ],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
}
