import 'package:flutter/material.dart';
import '../models/deal_highlight.dart';
import '../theme/app_colors.dart';
import 'progressive_network_image.dart';

class DealHighlightCard extends StatelessWidget {
  final DealHighlight highlight;
  final VoidCallback? onTap;

  const DealHighlightCard({super.key, required this.highlight, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.propertyName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (highlight.location != null &&
                      highlight.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            highlight.location!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoPill(
                        label: 'Current Bid',
                        value: _formatCurrency(highlight.currentPrice),
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        label: 'ROI',
                        value:
                            '${highlight.roiPercentage >= 0 ? '+' : ''}${highlight.roiPercentage.toStringAsFixed(1)}%',
                        isPositive: highlight.roiPercentage >= 0,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.gavel, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${highlight.bidCount} bids',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.av_timer,
                        size: 16,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeUntil(highlight.endAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (highlight.isEndingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ending Soon',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeroImage() {
    if (highlight.imageUrl != null && highlight.imageUrl!.isNotEmpty) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProgressiveNetworkImage(
              imageUrl: highlight.imageUrl!,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _RoiBadge(roi: highlight.roiPercentage),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 64,
          color: AppColors.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  String _timeUntil(DateTime endAt) {
    final now = DateTime.now();
    if (endAt.isBefore(now)) {
      final elapsed = now.difference(endAt);
      if (elapsed.inDays >= 1) {
        return 'Closed ${elapsed.inDays}d ago';
      }
      if (elapsed.inHours >= 1) {
        return 'Closed ${elapsed.inHours}h ago';
      }
      return 'Closed just now';
    }

    final remaining = endAt.difference(now);
    if (remaining.inDays >= 1) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
    }
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
    }
    return '${remaining.inMinutes.clamp(0, 59)}m left';
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return 'EGP ${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (value >= 1000000) {
      return 'EGP ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'EGP ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'EGP ${value.toStringAsFixed(0)}';
  }
}

class _RoiBadge extends StatelessWidget {
  final double roi;

  const _RoiBadge({required this.roi});

  @override
  Widget build(BuildContext context) {
    final isPositive = roi >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '+' : ''}${roi.toStringAsFixed(1)}% ROI',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _InfoPill({
    required this.label,
    required this.value,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: isPositive ? Colors.green.shade400 : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPositive ? Colors.green.shade600 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
