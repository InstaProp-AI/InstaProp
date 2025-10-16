import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/developer_profile.dart';
import '../services/developer_service.dart';
import '../services/chat_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';
import 'rate_developer_dialog.dart';

class DeveloperProfilePage extends StatefulWidget {
  final int developerId;

  const DeveloperProfilePage({super.key, required this.developerId});

  @override
  State<DeveloperProfilePage> createState() => _DeveloperProfilePageState();
}

class _DeveloperProfilePageState extends State<DeveloperProfilePage> {
  DeveloperProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final developerService = DeveloperService(
      ApiClient.baseUrl,
      token: appState.token,
    );

    try {
      final profile = await developerService.getDeveloperProfile(
        widget.developerId,
      );
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      print('Error loading developer profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _startChat() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final chat = await chatService.createChat(
        developerId: widget.developerId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(chat: chat)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start chat')));
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RateDeveloperDialog(
        developerId: widget.developerId,
        developerName: _profile?.fullName ?? '',
        onRated: () {
          _loadProfile(); // Refresh to show new rating
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? _buildErrorState()
          : _buildContent(),
      floatingActionButton: _profile != null
          ? FloatingActionButton.extended(
              onPressed: _startChat,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.chat, color: AppColors.surface),
              label: const Text(
                'Start Chat',
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // App bar with gradient
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: AppColors.surface),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profile!.profileImageUrl != null
                          ? NetworkImage(_profile!.profileImageUrl!)
                          : null,
                      child: _profile!.profileImageUrl == null
                          ? Text(
                              _profile!.firstName[0],
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Name and company
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _profile!.fullName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_profile!.companyName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _profile!.companyName!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          _profile!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${_profile!.totalRatings} reviews)',
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          '${_profile!.activeProjectsCount}',
                          'Projects',
                          Icons.folder,
                        ),
                        _buildStatCard(
                          '${_profile!.totalPropertiesCount}',
                          'Properties',
                          Icons.home,
                        ),
                        _buildStatCard(
                          '${_profile!.soldPropertiesCount}',
                          'Sold',
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Bio
              if (_profile!.bio != null) ...[
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile!.bio!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Portfolio
              if (_profile!.portfolioDescription != null) ...[
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile!.portfolioDescription!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Reviews
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _showRatingDialog,
                          child: const Text('Rate Developer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_profile!.ratings.isEmpty)
                      const Text(
                        'No reviews yet',
                        style: TextStyle(color: AppColors.secondary),
                      )
                    else
                      ..._profile!.ratings.map(
                        (rating) => _buildReviewCard(rating),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildReviewCard(DeveloperRatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, child: Text(rating.userName[0])),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rating.ratingType,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rating.comment != null) ...[
            const SizedBox(height: 8),
            Text(rating.comment!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text('Failed to load profile'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
      ),
    );
  }
}
