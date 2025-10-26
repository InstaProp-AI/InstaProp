import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';

class JoinButtonWidget extends StatefulWidget {
  final Community community;
  final VoidCallback? onJoinChanged;
  final bool compact;

  const JoinButtonWidget({
    super.key,
    required this.community,
    this.onJoinChanged,
    this.compact = false,
  });

  @override
  State<JoinButtonWidget> createState() => _JoinButtonWidgetState();
}

class _JoinButtonWidgetState extends State<JoinButtonWidget> {
  bool _isLoading = false;

  Future<void> _handleJoinToggle() async {
    if (widget.community.isLocked) return;

    setState(() => _isLoading = true);

    try {
      if (widget.community.isJoined) {
        // Leave community
        final response = await CommunityService.leaveCommunity(
          widget.community.communityId,
        );
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Left community'),
                backgroundColor: AppColors.textSecondary,
              ),
            );
          }
        }
      } else {
        // Join community
        final response = await CommunityService.joinCommunity(
          widget.community.communityId,
        );
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Joined community successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.error ?? 'Failed to join'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (widget.onJoinChanged != null) {
        widget.onJoinChanged!();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.community.isLocked) {
      return _buildLockedButton();
    }

    if (widget.community.isJoined) {
      return _buildJoinedButton();
    }

    return _buildJoinButton();
  }

  Widget _buildJoinButton() {
    if (_isLoading) {
      return SizedBox(
        width: widget.compact ? 100 : 140,
        height: 36,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _handleJoinToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 20,
          vertical: widget.compact ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add, size: 16),
          const SizedBox(width: 4),
          Text(
            widget.compact ? 'Join' : 'Join Community',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleJoinToggle,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 16,
          vertical: widget.compact ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
        ),
        side: BorderSide(color: AppColors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLoading ? null : Icons.check,
            size: 16,
            color: AppColors.success,
            semanticLabel: null,
          ),
          if (!_isLoading) const SizedBox(width: 4),
          Text(
            widget.compact ? 'Joined' : 'Joined ✓',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: widget.compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedButton() {
    return OutlinedButton.icon(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 16,
          vertical: widget.compact ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      icon: const Icon(Icons.lock, size: 16, color: Colors.grey),
      label: Text(
        'Locked',
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          fontSize: widget.compact ? 12 : 14,
        ),
      ),
    );
  }
}
