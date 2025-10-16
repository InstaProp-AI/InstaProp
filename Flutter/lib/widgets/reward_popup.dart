import 'package:flutter/material.dart';

class RewardPopup extends StatelessWidget {
  final int pointsAwarded;
  final int totalPoints;
  const RewardPopup({
    super.key,
    required this.pointsAwarded,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final nextTarget = totalPoints < 100
        ? 100
        : totalPoints < 500
        ? 500
        : totalPoints < 1000
        ? 1000
        : 5000;
    final start = totalPoints < 100
        ? 0
        : totalPoints < 500
        ? 100
        : totalPoints < 1000
        ? 500
        : 1000;
    final progress = ((totalPoints - start) / (nextTarget - start)).clamp(
      0.0,
      1.0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              '+$pointsAwarded Points!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total: $totalPoints pts'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Next badge at $nextTarget pts',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great!'),
            ),
          ],
        ),
      ),
    );
  }
}
