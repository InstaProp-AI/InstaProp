import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../pages/auction_details_page.dart';

class AuctionsTable extends StatelessWidget {
  const AuctionsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.loadingAuctions) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final auctions = appState.auctions;

        if (auctions.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 48, color: AppColors.secondary),
                  const SizedBox(height: 8),
                  Text(
                    'No auctions available',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Property',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Bids',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Table rows
            ...auctions
                .map(
                  (auction) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        bottom: BorderSide(color: AppColors.background!),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AuctionDetailsPage(auction: auction),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auction.property?.name ?? 'Property',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (auction.property?.location != null)
                                    Text(
                                      auction.property!.location,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '\$${auction.currentPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Text('${auction.bidCount}')),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: auction.isActive
                                      ? AppColors.background
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  auction.status,
                                  style: TextStyle(
                                    color: auction.isActive
                                        ? AppColors.primary
                                        : AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                auction.timeRemaining,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }
}
