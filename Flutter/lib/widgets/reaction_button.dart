import 'package:flutter/material.dart';

enum ReactionType { like, celebrate, insightful, helpful, love, thankYou }

class ReactionButton extends StatefulWidget {
  final bool isActive;
  final int count;
  final VoidCallback onTap;
  final ReactionType reactionType;

  const ReactionButton({
    super.key,
    required this.isActive,
    required this.count,
    required this.onTap,
    required this.reactionType,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForReaction();
    final color = widget.isActive ? _getColorForReaction() : Colors.grey;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? _getColorForReaction().withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive ? _getColorForReaction() : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                widget.count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForReaction() {
    switch (widget.reactionType) {
      case ReactionType.like:
        return widget.isActive ? Icons.favorite : Icons.favorite_border;
      case ReactionType.celebrate:
        return Icons.celebration;
      case ReactionType.insightful:
        return Icons.lightbulb;
      case ReactionType.helpful:
        return Icons.handshake;
      case ReactionType.love:
        return Icons.favorite_rounded;
      case ReactionType.thankYou:
        return Icons.volunteer_activism;
      default:
        return Icons.thumb_up;
    }
  }

  Color _getColorForReaction() {
    switch (widget.reactionType) {
      case ReactionType.like:
        return Colors.red;
      case ReactionType.celebrate:
        return Colors.orange;
      case ReactionType.insightful:
        return Colors.amber;
      case ReactionType.helpful:
        return Colors.blue;
      case ReactionType.love:
        return Colors.pink;
      case ReactionType.thankYou:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
