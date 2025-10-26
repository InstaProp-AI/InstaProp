import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';
import 'community_cover_widget.dart';
import 'join_button_widget.dart';
import 'permission_denied_dialog.dart';

class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final VoidCallback? onJoinChanged;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.onJoinChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: community.isLocked
          ? () {
              // Show permission denied dialog instead
              showDialog(
                context: context,
                builder: (context) => PermissionDeniedDialog(community: community),
              );
            }
          : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  CommunityCoverWidget(community: community, height: 180),
                  // Lock overlay if locked
                  if (community.isLocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock, size: 48, color: Colors.white),
                      ),
                    ),
                  // Access badge in top-right
                  Positioned(top: 12, right: 12, child: _buildAccessBadge()),
                ],
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community name and joined badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (community.isJoined && !community.isLocked)
                        _buildJoinedBadge(),
                    ],
                  ),
                  // Description
                  if (community.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      community.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Stats row
                  if (!community.isLocked)
                    Row(
                      children: [
                        _buildStat(
                          Icons.people,
                          community.memberCount.toString(),
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          Icons.article,
                          community.postCount.toString(),
                        ),
                      ],
                    ),
                  // Locked message
                  if (community.isLocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Requires property ownership in this project',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Join button (if not joined and not locked)
                  if (community.canJoin &&
                      !community.isJoined &&
                      !community.isLocked) ...[
                    const SizedBox(height: 12),
                    JoinButtonWidget(
                      community: community,
                      onJoinChanged: onJoinChanged,
                      compact: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildJoinedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: AppColors.success),
          SizedBox(width: 2),
          Text(
            'Joined',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
