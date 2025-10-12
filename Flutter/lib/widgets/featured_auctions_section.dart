import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../pages/auction_details_page.dart';
import 'auction_card.dart';

class FeaturedAuctionsSection extends StatelessWidget {
  const FeaturedAuctionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final featuredAuctions = appState.featuredAuctions;

        if (featuredAuctions.isEmpty) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Auctions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredAuctions.length,
                itemBuilder: (context, index) {
                  final auction = featuredAuctions[index];
                  return Container(
                    width: 300,
                    margin: EdgeInsets.only(
                      right: index < featuredAuctions.length - 1 ? 16 : 0,
                    ),
                    child: AuctionCard(
                      auction: auction,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AuctionDetailsPage(auction: auction),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
