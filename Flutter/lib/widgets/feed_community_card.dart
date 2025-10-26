import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';

class FeedCommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;

  const FeedCommunityCard({super.key, required this.community, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.4),
                  ],
                ),
                image: community.coverPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(community.coverPhotoUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) => null,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Community Icon
                  Positioned(
                    bottom: -20,
                    left: 16,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          community.name.isNotEmpty
                              ? community.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Access Type Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getAccessColor(
                          community.accessType,
                        ).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAccessIcon(community.accessType),
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getAccessText(community.accessType),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  if (community.description != null &&
                      community.description!.isNotEmpty)
                    Text(
                      community.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Stats Row
                  Row(
                    children: [
                      _buildStat(
                        Icons.people,
                        '${community.memberCount} members',
                      ),
                      const SizedBox(width: 16),
                      _buildStat(
                        Icons.chat_bubble_outline,
                        '${community.postCount} posts',
                      ),
                      const Spacer(),
                      // Activity indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: community.isActive
                              ? AppColors.success
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        community.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: community.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Preview of active members (mock data - should be fetched)
                  Row(
                    children: [
                      SizedBox(
                        width:
                            56, // Width for 3 overlapped avatars (24px spacing)
                        height: 32, // Height for the avatars
                        child: Stack(
                          children: List.generate(3, (index) {
                            return Positioned(
                              left:
                                  index *
                                  24.0, // Overlap avatars by 24px (16px radius)
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.border,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'U',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${community.memberCount > 3 ? community.memberCount - 3 : 0} more',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: community.isJoined
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.primary,
                        foregroundColor: community.isJoined
                            ? AppColors.success
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            community.isJoined ? Icons.check : Icons.group_add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            community.isJoined ? 'Joined' : 'Join Community',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getAccessText(CommunityAccessType accessType) {
    switch (accessType) {
      case CommunityAccessType.publicAll:
        return 'Public';
      case CommunityAccessType.publicOwners:
        return 'Owners';
      case CommunityAccessType.private:
        return 'Private';
    }
  }

  IconData _getAccessIcon(CommunityAccessType accessType) {
    switch (accessType) {
      case CommunityAccessType.publicAll:
        return Icons.public;
      case CommunityAccessType.publicOwners:
        return Icons.people;
      case CommunityAccessType.private:
        return Icons.lock;
    }
  }

  Color _getAccessColor(CommunityAccessType accessType) {
    switch (accessType) {
      case CommunityAccessType.publicAll:
        return AppColors.success;
      case CommunityAccessType.publicOwners:
        return AppColors.primary;
      case CommunityAccessType.private:
        return Colors.orange;
    }
  }
}
