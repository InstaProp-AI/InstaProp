import 'package:flutter/material.dart';
import '../models/payment_reminder.dart';
import '../theme/app_colors.dart';

class FeedPaymentReminderCard extends StatelessWidget {
  final PaymentReminder reminder;
  final VoidCallback? onTap;
  final VoidCallback? onSetReminder;

  const FeedPaymentReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onSetReminder,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Determine urgency color
    Color urgencyColor;
    if (reminder.daysUntilDue <= 1) {
      urgencyColor = Colors.red;
    } else if (reminder.daysUntilDue <= 3) {
      urgencyColor = Colors.orange;
    } else {
      urgencyColor = AppColors.primary;
    }

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: urgencyColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.daysUntilDue == 0
                            ? 'Payment Due Today'
                            : reminder.daysUntilDue == 1
                                ? 'Payment Due Tomorrow'
                                : 'Payment Due in ${reminder.daysUntilDue} Days',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: urgencyColor,
                        ),
                      ),
                      if (reminder.amount != null)
                        Text(
                          'EGP ${_formatAmount(reminder.amount!)}',
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
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reminder.propertyName != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reminder.propertyName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(reminder.eventDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: urgencyColor),
                        ),
                        child: Text(
                          'View Schedule',
                          style: TextStyle(color: urgencyColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reminder.isReminderSet)
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.notifications_active, size: 18),
                        label: const Text('Reminder Set'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(color: Colors.green),
                          disabledForegroundColor: Colors.green,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: onSetReminder,
                        icon: const Icon(Icons.notifications_none, size: 18),
                        label: const Text('Set Reminder'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(color: urgencyColor),
                          foregroundColor: urgencyColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today, ${date.day}/${date.month}/${date.year}';
    } else if (difference == 1) {
      return 'Tomorrow, ${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

