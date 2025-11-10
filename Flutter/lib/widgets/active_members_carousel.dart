import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'progressive_network_image.dart';

class ActiveMembersCarousel extends StatelessWidget {
  final List<dynamic> members;
  final int totalCount;

  const ActiveMembersCarousel({
    super.key,
    required this.members,
    required this.totalCount,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      [Colors.blue.shade300, Colors.blue.shade500],
      [Colors.purple.shade300, Colors.purple.shade500],
      [Colors.green.shade300, Colors.green.shade500],
      [Colors.orange.shade300, Colors.orange.shade500],
      [Colors.pink.shade300, Colors.pink.shade500],
      [Colors.teal.shade300, Colors.teal.shade500],
      [Colors.indigo.shade300, Colors.indigo.shade500],
      [Colors.red.shade300, Colors.red.shade500],
    ];

    final index = name.hashCode % colors.length;
    return colors[index.abs()][0];
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Active Members ($totalCount)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final firstName = member['firstName'] as String? ?? '';
                final lastName = member['lastName'] as String? ?? '';
                final fullName = '$firstName $lastName'.trim();
                final firstLetter = firstName.isNotEmpty
                    ? firstName[0].toUpperCase()
                    : '?';
                final imageUrl = member['imageUrl'] as String?;

                return GestureDetector(
                  onTap: () {
                    // Show member details
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(fullName),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (member['role'] != null)
                              Text('Role: ${member['role']}'),
                            if (member['joinedAt'] != null)
                              Text(
                                'Joined: ${_formatDate(member['joinedAt'])}',
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getAvatarColor(fullName),
                                _getAvatarColor(fullName).withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? ProgressiveNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(60),
                                  placeholder: Center(
                                    child: Text(
                                      firstLetter,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    firstLetter,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fullName.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateStr = date.toString();
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

