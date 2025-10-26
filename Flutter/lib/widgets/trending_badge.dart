import 'package:flutter/material.dart';

class TrendingBadge extends StatelessWidget {
  final double score;
  final Size size;

  const TrendingBadge({
    super.key,
    required this.score,
    this.size = const Size(60, 24),
  });

  @override
  Widget build(BuildContext context) {
    if (score < 5) return const SizedBox.shrink();

    String label;
    Color backgroundColor;
    Color textColor;

    if (score >= 50) {
      label = '🔥 HOT';
      backgroundColor = Colors.red.shade500;
      textColor = Colors.white;
    } else if (score >= 20) {
      label = '⚡ Trending';
      backgroundColor = Colors.orange.shade500;
      textColor = Colors.white;
    } else if (score >= 10) {
      label = '✨ Rising';
      backgroundColor = Colors.amber.shade400;
      textColor = Colors.white;
    } else {
      label = '📈 New';
      backgroundColor = Colors.green.shade400;
      textColor = Colors.white;
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size.height / 2),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
