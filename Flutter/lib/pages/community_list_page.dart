import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';
import '../widgets/community_card.dart';
import 'community_details_page.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  List<Community> _communities = [];
  List<Community> _recommendedCommunities = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);

    final allResponse = await CommunityService.getCommunities();
    final recommendedResponse =
        await CommunityService.getRecommendedCommunities();

    if (allResponse.success && allResponse.data != null) {
      setState(() => _communities = allResponse.data!);
    }

    if (recommendedResponse.success && recommendedResponse.data != null) {
      setState(() => _recommendedCommunities = recommendedResponse.data!);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _joinCommunity(int communityId) async {
    final response = await CommunityService.joinCommunity(communityId);
    if (response.success) {
      _loadCommunities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to join')),
        );
      }
    }
  }

  List<Community> get _filteredCommunities {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _communities;
    return _communities
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              (c.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search communities...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Recommended communities banner
                if (_recommendedCommunities.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommended for You',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You own properties in projects with active communities',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Community list
                Expanded(
                  child: _filteredCommunities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No communities found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCommunities.length,
                          itemBuilder: (context, index) {
                            final community = _filteredCommunities[index];
                            return CommunityCard(
                              community: community,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommunityDetailsPage(
                                      communityId: community.communityId,
                                    ),
                                  ),
                                ).then((_) => _loadCommunities());
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

