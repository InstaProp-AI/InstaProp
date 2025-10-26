import 'package:flutter/material.dart';

class EngagementStats extends StatelessWidget {
  final int likes;
  final int comments;
  final int views;
  final bool isTrending;

  const EngagementStats({
    super.key,
    required this.likes,
    required this.comments,
    required this.views,
    this.isTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStat(Icons.favorite, likes, Colors.red),
        const SizedBox(width: 16),
        _buildStat(Icons.comment, comments, Colors.blue),
        const SizedBox(width: 16),
        _buildStat(Icons.remove_red_eye, views, Colors.grey),
      ],
    );
  }

  Widget _buildStat(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
