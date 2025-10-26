import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../theme/app_colors.dart';

class PollWidget extends StatefulWidget {
  final Poll poll;
  final Function(int)? onVote;

  const PollWidget({super.key, required this.poll, this.onVote});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.poll.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.poll.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isVotedOption =
                widget.poll.hasVoted &&
                widget.poll.userVoteOptionIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: widget.poll.hasVoted || widget.onVote == null
                    ? null
                    : () => widget.onVote!(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVotedOption
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVotedOption
                          ? AppColors.primary
                          : AppColors.border,
                      width: isVotedOption ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: widget.poll.hasVoted
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isVotedOption
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.poll.hasVoted) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${option.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: LinearProgressIndicator(
                            value: option.percentage / 100,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ] else if (!widget.poll.hasVoted && widget.onVote != null)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.poll.hasVoted)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
              const SizedBox(width: 4),
              Text(
                widget.poll.hasVoted
                    ? 'You voted'
                    : '${widget.poll.totalVotes} votes',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              if (widget.poll.endsAt != null) ...[
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ends ${_formatTime(widget.poll.endsAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h';
    } else {
      return 'soon';
    }
  }
}

