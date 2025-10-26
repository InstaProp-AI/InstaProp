import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';

class CommunityCoverWidget extends StatelessWidget {
  final Community community;
  final double height;
  final BoxFit fit;

  const CommunityCoverWidget({
    super.key,
    required this.community,
    this.height = 200,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      child:
          community.coverPhotoUrl != null && community.coverPhotoUrl!.isNotEmpty
          ? Image.network(
              community.coverPhotoUrl!,
              fit: fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildGradientFallback();
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildGradientFallback();
              },
            )
          : _buildGradientFallback(),
    );
  }

  Widget _buildGradientFallback() {
    // Generate color from community name
    final colors = _getCommunityColors(community.name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          community.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  List<Color> _getCommunityColors(String name) {
    // Generate consistent colors based on community name
    final hash = name.hashCode.abs();
    final hue = (hash % 360).toDouble();

    return [
      HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.7, 0.5).toColor(),
    ];
  }
}
