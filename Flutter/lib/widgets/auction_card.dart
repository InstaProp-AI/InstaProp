import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/auction.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback? onTap;

  const AuctionCard({super.key, required this.auction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.secondary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      auction.property?.name ?? 'Property',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: auction.isActive
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auction.status,
                      style: TextStyle(
                        color: auction.isActive
                            ? AppColors.surface
                            : AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Property description
              if (auction.property?.description != null)
                Text(
                  auction.property!.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Price and bid info
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '\$${auction.currentPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bids',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${auction.bidCount}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Time remaining
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    auction.timeRemaining,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
