import '../../theme/app_colors.dart';
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
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
                  color: AppColors.background,
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
                              ?.copyWith(color: AppColors.primary),
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
                                color: AppColors.primary,
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
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${auction.bidCount} bids',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.primary),
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
                                ? AppColors.background
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auction.isActive ? 'Active' : 'Ended',
                            style: TextStyle(
                              color: auction.isActive
                                  ? AppColors.primary
                                  : AppColors.primary,
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
          Icon(icon, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
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
