import 'package:flutter/material.dart';
import '../models/auction.dart';
import '../theme/app_colors.dart';
import 'image_carousel.dart';
import 'countdown_timer.dart';
import 'country_flag.dart';

/// Premium Instagram-style auction card with hero images and rich interactions
class FeedAuctionCard extends StatefulWidget {
  final Auction auction;
  final VoidCallback? onTap; // For bidding/auction details navigation
  final VoidCallback? onPropertyTap; // For property details navigation
  final VoidCallback? onShare;

  const FeedAuctionCard({
    super.key,
    required this.auction,
    this.onTap,
    this.onPropertyTap,
    this.onShare,
  });

  @override
  State<FeedAuctionCard> createState() => _FeedAuctionCardState();
}

class _FeedAuctionCardState extends State<FeedAuctionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auction.property == null) {
      return const SizedBox.shrink();
    }

    final property = widget.auction.property!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Get all property images
    final images = <String>[];
    if (property.imageUrl.isNotEmpty) {
      images.add(property.imageUrl);
    }
    if (property.propertyImages.isNotEmpty) {
      for (final img in property.propertyImages) {
        if (img.imageUrl.isNotEmpty && !images.contains(img.imageUrl)) {
          images.add(img.imageUrl);
        }
      }
    }
    if (images.isEmpty) {
      images.add(
        'https://via.placeholder.com/800x600/CCCCCC/FFFFFF?text=No+Image',
      );
    }

    // Get top 3 bidders
    final topBidders = widget.auction.bids
      ..sort((a, b) => b.bidAmount.compareTo(a.bidAmount));
    final top3 = topBidders.take(3).toList();

    // Determine auction status color
    Color statusColor = AppColors.success;
    if (DateTime.now().isAfter(widget.auction.endAt)) {
      statusColor = AppColors.error;
    } else if (DateTime.now()
        .add(const Duration(hours: 1))
        .isAfter(widget.auction.endAt)) {
      statusColor = AppColors.warning;
    }

    final bool isLive = widget.auction.isActive;
    final bool isEnded = widget.auction.status == "Ended" || widget.auction.isEnded;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image with Overlay - Tappable for property details
          GestureDetector(
            onTap: widget.onPropertyTap,
            child: Stack(
              children: [
                ImageCarousel(
                  images: images,
                  height: 400,
                  fit: BoxFit.cover,
                  onTap: widget.onPropertyTap,
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(isEnded ? 0.8 : 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Status Badge - LIVE (with pulse animation)
              if (isLive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(
                            0.85 + _pulseController.value * 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: _pulseController.value * 8,
                              spreadRadius: _pulseController.value * 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.gavel,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Floating Status Badge - ENDED
              if (isEnded)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ENDED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Countdown Timer (bottom right) - only show for live auctions
              if (isLive)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: CountdownTimer(
                    endTime: widget.auction.endAt,
                    accentColor: statusColor,
                  ),
                )
              // Show "Ended" text for ended auctions
              else if (isEnded)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Auction Ended',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Current Bid (overlay at bottom)
              Positioned(
                bottom: 16,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        // Country Flag
                        CountryFlag(
                          countryCode: CountryFlag.extractCountryCodeFromLocation(
                            property.location,
                          ),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            property.location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

          // Info Section - Tappable for property details
          GestureDetector(
            onTap: widget.onPropertyTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Current Bid Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Bid',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatCurrency(widget.auction.currentPrice),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gavel_outlined,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.auction.bidCount} bids',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeRemaining(widget.auction.endAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Property Quick Info
                Row(
                  children: [
                    Icon(
                      Icons.bed,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${property.bedrooms} Bed',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.bathroom_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${property.bathrooms} Bath',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.square_foot,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${property.squareFeet} sqft',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Top Bidders Preview
                if (top3.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.leaderboard_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Top Bidders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...top3.asMap().entries.map((entry) {
                    final index = entry.key;
                    final bid = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getRankColors(index),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              bid.bidder?.firstName[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${bid.bidder?.firstName ?? 'User'} ${bid.bidder?.lastName ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(bid.bidAmount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                ],
              ),
            ),
          ),

          // Primary Action Button - Separate tap handler for bidding/auction navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onTap, // Always allow tap, even for ended auctions
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive
                      ? AppColors.primary
                      : Colors.grey.shade600, // Gray for ended auctions
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isLive ? 2 : 0, // No elevation for ended auctions
                  disabledBackgroundColor: Colors.grey.shade600,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLive ? Icons.gavel : Icons.block,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLive ? 'Live auction? Lord, please bid now' : 'Auction Ended',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'EGP ${amount.toStringAsFixed(0)}';
  }

  String _getTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    final remaining = endTime.difference(now);

    if (remaining.isNegative) return 'Ended';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return '${remaining.inMinutes}m left';
    }
  }

  List<Color> _getRankColors(int index) {
    switch (index) {
      case 0:
        return [const Color(0xFFFFD700), const Color(0xFFFFC107)]; // Gold
      case 1:
        return [Colors.grey.shade400, Colors.grey.shade600]; // Silver
      default:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
    }
  }
}
