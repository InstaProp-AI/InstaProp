import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reaction_type.dart';

class ReactionPicker extends StatelessWidget {
  final Function(ReactionType) onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReactionButton(
              context,
              ReactionType.like,
              Icons.favorite,
              Colors.red,
            ),
            const SizedBox(width: 4),
            _buildReactionButton(
              context,
              ReactionType.celebrate,
              Icons.celebration,
              Colors.orange,
            ),
            const SizedBox(width: 4),
            _buildReactionButton(
              context,
              ReactionType.insightful,
              Icons.lightbulb,
              Colors.amber,
            ),
            const SizedBox(width: 4),
            _buildReactionButton(
              context,
              ReactionType.helpful,
              Icons.handshake,
              Colors.blue,
            ),
            const SizedBox(width: 4),
            _buildReactionButton(
              context,
              ReactionType.love,
              Icons.favorite_rounded,
              Colors.pink,
            ),
            const SizedBox(width: 4),
            _buildReactionButton(
              context,
              ReactionType.thankYou,
              Icons.volunteer_activism,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(
    BuildContext context,
    ReactionType type,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onReactionSelected(type);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }
}

