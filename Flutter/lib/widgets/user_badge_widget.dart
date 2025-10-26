import 'package:flutter/material.dart';

enum UserType { owner, developer, admin }

class UserBadgeWidget extends StatelessWidget {
  final UserType type;
  final double size;

  const UserBadgeWidget({super.key, required this.type, this.size = 16});

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color color;

    switch (type) {
      case UserType.admin:
        icon = Icons.workspace_premium;
        color = Colors.amber;
        break;
      case UserType.developer:
        icon = Icons.business;
        color = Colors.blue;
        break;
      case UserType.owner:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

