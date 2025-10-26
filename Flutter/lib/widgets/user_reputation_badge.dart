import 'package:flutter/material.dart';

class UserReputationBadge extends StatelessWidget {
  final int reputationPoints;
  final Size size;

  const UserReputationBadge({
    super.key,
    required this.reputationPoints,
    this.size = const Size(70, 24),
  });

  @override
  Widget build(BuildContext context) {
    if (reputationPoints < 10) return const SizedBox.shrink();

    String level;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (reputationPoints >= 1000) {
      level = 'Legend';
      backgroundColor = Colors.purple;
      textColor = Colors.white;
      icon = Icons.stars;
    } else if (reputationPoints >= 500) {
      level = 'Expert';
      backgroundColor = Colors.indigo;
      textColor = Colors.white;
      icon = Icons.workspace_premium;
    } else if (reputationPoints >= 250) {
      level = 'Pro';
      backgroundColor = Colors.blue;
      textColor = Colors.white;
      icon = Icons.verified;
    } else if (reputationPoints >= 100) {
      level = 'Veteran';
      backgroundColor = Colors.teal;
      textColor = Colors.white;
      icon = Icons.check_circle;
    } else if (reputationPoints >= 50) {
      level = 'Active';
      backgroundColor = Colors.green;
      textColor = Colors.white;
      icon = Icons.person;
    } else {
      level = 'New';
      backgroundColor = Colors.grey.shade400;
      textColor = Colors.white;
      icon = Icons.person_outline;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
