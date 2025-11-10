import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';

class SelectCommunityDialog extends StatelessWidget {
  final List<Community> communities;

  const SelectCommunityDialog({
    super.key,
    required this.communities,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Community',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Community list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: community.coverPhotoUrl != null
                          ? NetworkImage(community.coverPhotoUrl!)
                          : null,
                      child: community.coverPhotoUrl == null
                          ? Text(
                              community.name.isNotEmpty
                                  ? community.name[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      community.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      community.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(community);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

