import 'package:flutter/material.dart';
import '../models/investor_milestone.dart';
import '../theme/app_colors.dart';

class InvestorMilestoneCard extends StatelessWidget {
  final InvestorMilestone milestone;
  final VoidCallback? onTap;
  final VoidCallback? onViewPortfolio;

  const InvestorMilestoneCard({
    super.key,
    required this.milestone,
    this.onTap,
    this.onViewPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      milestone.initials.isEmpty
                          ? 'IN'
                          : milestone.initials.toUpperCase(),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.investorName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          milestone.title,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${milestone.pointsAwarded} pts',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (milestone.description != null &&
                  milestone.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  milestone.description!,
                  style: textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    icon: Icons.apartment_outlined,
                    label: 'Portfolio',
                    value: '${milestone.portfolioCount} assets',
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.paid_outlined,
                    label: 'Buy-in Value',
                    value: _formatCurrency(milestone.totalBuyInValue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${milestone.reputationPoints} reputation points',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(milestone.earnedAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (onViewPortfolio != null) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onViewPortfolio,
                    child: const Text('View Portfolio Snapshot'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

