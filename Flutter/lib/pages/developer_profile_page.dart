import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/developer_profile.dart';
import '../services/developer_service.dart';
import '../services/chat_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_button.dart';
import 'chat_page.dart';
import 'project_details_page.dart';
import 'property_details_page.dart';
import 'rate_developer_dialog.dart';
import 'auth_page.dart';

class DeveloperProfilePage extends StatefulWidget {
  final String developerId;

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
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading developer profile: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _loading = false);
        
        String errorMessage = 'Failed to load developer profile';
        if (e.toString().contains('404') || e.toString().contains('not found')) {
          errorMessage = 'This developer profile is no longer available. The developer may have been removed or their account may have been deactivated.';
        } else if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
          errorMessage = 'You do not have permission to view this developer profile.';
        } else {
          errorMessage = 'Failed to load developer profile: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Check if user is authenticated
    if (appState.token == null || appState.token!.isEmpty) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      print('Creating chat with developer: ${widget.developerId}');
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
      Navigator.pop(context); // Close loading dialog

      // Extract error message
      String errorMessage = 'Failed to start chat';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      print('Chat creation error: $errorMessage');

      // Show error dialog with details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
          actions: [
            ModernButton(
              text: 'OK',
              type: ModernButtonType.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  /// Show login required dialog with login button
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.login, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Login Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to be logged in to start a chat with the developer.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Please log in to continue.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ModernButton(
            text: 'Login',
            type: ModernButtonType.primary,
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
            icon: Icons.login,
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RateDeveloperDialog(
        developerId: widget.developerId,
        developerName: _profile?.companyName ?? _profile?.fullName ?? '',
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
      floatingActionButton: _profile != null &&
              context.watch<AppState>().isFeatureEnabled('Chat')
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
              decoration: const BoxDecoration(color: AppColors.primary),
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
                              (_profile!.companyName ?? _profile!.firstName)[0],
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
                      _profile!.companyName ?? _profile!.fullName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

              if (_profile!.projects.isNotEmpty) ...[
                _buildProjectsCarousel(),
                const SizedBox(height: 8),
              ],

              if (_profile!.properties.isNotEmpty) ...[
                _buildPropertiesCarousel(),
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
          ModernButton(
            text: 'Retry',
            type: ModernButtonType.primary,
            onPressed: _loadProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsCarousel() {
    final projects = _profile!.projects;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Projects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final project = projects[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProjectDetailsPage(projectId: project.projectId),
                      ),
                    );
                  },
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child:
                              project.coverImageUrl != null &&
                                  project.coverImageUrl!.isNotEmpty
                              ? Image.network(
                                  project.coverImageUrl!,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildProjectPlaceholder(),
                                )
                              : _buildProjectPlaceholder(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (project.location != null &&
                                  project.location!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        project.location!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              Text(
                                '${project.propertiesCount} properties',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: projects.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectPlaceholder() {
    return Container(
      height: 110,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.apartment, size: 32, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPropertiesCarousel() {
    final properties = _profile!.properties;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Featured Properties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final property = properties[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsPage(
                          propertyId: property.propertyId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: property.imageUrl.isNotEmpty
                              ? Image.network(
                                  property.imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildPropertyPlaceholder(),
                                )
                              : _buildPropertyPlaceholder(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                property.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                property.type,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.king_bed,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${property.bedrooms}'),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.bathtub,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${property.bathrooms}'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${property.squareFeet} sqft',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: properties.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.08),
      child: const Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 32,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
