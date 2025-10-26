import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../theme/app_colors.dart';
import 'user_badge_widget.dart';
import 'trending_badge.dart';
import 'engagement_stats.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final bool showCommunity;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.showCommunity = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community header (if enabled)
              if (showCommunity) ...[
                _buildCommunityBanner(),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
              // Header with trending indicator
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            UserBadgeWidget(type: _getUserType(), size: 14),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDateTime(post.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Show trending badge if engagement is high
                            if (post.likeCount + post.commentCount >= 10)
                              TrendingBadge(
                                score: (post.likeCount + post.commentCount)
                                    .toDouble(),
                                size: const Size(50, 20),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                post.content,
                style: const TextStyle(fontSize: 15),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              // Image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: AppColors.border,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ],
              // Categories
              if (post.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: post.categories.take(3).map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$category',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Engagement Stats
              const SizedBox(height: 12),
              EngagementStats(
                likes: post.likeCount,
                comments: post.commentCount,
                views: 0, // Update when view tracking is implemented
              ),

              // Footer actions
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    count: post.likeCount,
                    onTap: onLike,
                    isActive: post.isLiked,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    count: post.commentCount,
                    onTap: onComment,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    count: 0,
                    onTap: null,
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(post.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityBanner() {
    return Row(
      children: [
        // Cover thumbnail
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                post.communityCoverPhotoUrl != null &&
                    post.communityCoverPhotoUrl!.isNotEmpty
                ? Image.network(
                    post.communityCoverPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientFallback(),
                  )
                : _buildGradientFallback(),
          ),
        ),
        const SizedBox(width: 8),
        // Community name and access badge
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  post.communityName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                ' • ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              _buildAccessBadge(),
              if (post.isUserJoinedCommunity) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientFallback() {
    final colors = _getCommunityColors(post.communityName);
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
          post.communityName.isNotEmpty
              ? post.communityName[0].toUpperCase()
              : 'C',
          style: const TextStyle(
            fontSize: 14,
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

    switch (post.communityAccessType) {
      case 'Private':
        text = 'Private';
        color = Colors.orange;
        break;
      case 'PublicOwners':
        text = 'Owners';
        color = Colors.blue;
        break;
      case 'PublicAll':
        text = 'Public';
        color = Colors.green;
        break;
      default:
        text = 'Private';
        color = Colors.orange;
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

  List<Color> _getCommunityColors(String name) {
    final hash = name.hashCode.abs();
    final hue = (hash % 360).toDouble();

    return [
      HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.7, 0.5).toColor(),
    ];
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  UserType _getUserType() {
    switch (post.authorType.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'developer':
        return UserType.developer;
      default:
        return UserType.owner;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
