import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';
import 'progressive_network_image.dart';

class CommunityHeaderWidget extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final bool showJoinedBadge;
  final bool showAccessBadge;

  const CommunityHeaderWidget({
    super.key,
    required this.community,
    this.onTap,
    this.showJoinedBadge = true,
    this.showAccessBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            // Cover thumbnail
            _buildCoverThumbnail(),
            const SizedBox(width: 12),
            // Community info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (showAccessBadge) _buildAccessBadge(),
                      if (showJoinedBadge && community.isJoined)
                        _buildJoinedIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverThumbnail() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: community.coverPhotoUrl != null &&
                community.coverPhotoUrl!.isNotEmpty
            ? ProgressiveNetworkImage(
                imageUrl: community.coverPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: _buildGradientFallback(),
              )
            : _buildGradientFallback(),
      ),
    );
  }

  Widget _buildGradientFallback() {
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAccessBadge() {
    late String text;
    late Color color;

    switch (community.accessType) {
      case CommunityAccessType.private:
        text = 'Private';
        color = Colors.orange;
        break;
      case CommunityAccessType.publicOwners:
        text = 'Owners';
        color = Colors.blue;
        break;
      case CommunityAccessType.publicAll:
        text = 'Public';
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildJoinedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: AppColors.success),
          const SizedBox(width: 2),
          Text(
            'Joined',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getCommunityColors(String name) {
    final hash = name.hashCode.abs();
    final hue = (hash % 360).toDouble();

    return [
      HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.7, 0.5).toColor(),
    ];
  }
}
