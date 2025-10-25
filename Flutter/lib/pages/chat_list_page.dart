import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../models/developer_profile.dart';
import '../models/project_model.dart';
import '../services/chat_service.dart';
import '../services/ai_broker_service.dart';
import '../services/developer_service.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';
import 'ai_broker_chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Chat> _chats = [];
  List<AIBrokerChatSummary> _aiChats = [];
  List<FeaturedDeveloper> _featuredDevelopers = [];
  bool _loading = true;
  bool _loadingDevelopers = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadFeaturedDevelopers();
  }

  Future<void> _loadChats() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      final chats = await chatService.getChats();
      final aiChatsResponse = await AIBrokerService.getMyAIChats();

      setState(() {
        _chats = chats;
        _aiChats = aiChatsResponse.data ?? [];
        _loading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFeaturedDevelopers() async {
    final developerService = DeveloperService(ApiClient.baseUrl);

    try {
      final developers = await developerService.getFeaturedDevelopers();
      setState(() {
        _featuredDevelopers = developers;
        _loadingDevelopers = false;
      });
    } catch (e) {
      print('Error loading featured developers: $e');
      setState(() => _loadingDevelopers = false);
    }
  }

  List<Chat> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;

    return _chats.where((chat) {
      final developerName = chat.developerName?.toLowerCase() ?? '';
      final userName = chat.userName?.toLowerCase() ?? '';
      final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return developerName.contains(query) ||
          userName.contains(query) ||
          lastMessage.contains(query);
    }).toList();
  }

  Future<void> _showProjectSelectionDialog(FeaturedDeveloper developer) async {
    // Check if user is logged in
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    try {
      final projectService = ProjectService(ApiClient.baseUrl);
      final projects = await projectService.getProjectsByDeveloper(
        developer.developerId,
      );

      if (!mounted) return;

      if (projects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${developer.fullName} has no active projects yet'),
            backgroundColor: AppColors.secondary,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: developer.profileImageUrl != null
                          ? NetworkImage(developer.profileImageUrl!)
                          : null,
                      child: developer.profileImageUrl == null
                          ? Text(
                              developer.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            developer.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (developer.companyName != null)
                            Text(
                              developer.companyName!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Projects list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildProjectCard(project, developer);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error loading projects: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load projects: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProjectCard(ProjectModel project, FeaturedDeveloper developer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _createChatWithProject(developer, project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Project image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.background,
                  child: project.featuredImageUrl != null
                      ? Image.network(
                          project.featuredImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.home,
                                color: AppColors.secondary,
                              ),
                        )
                      : const Icon(Icons.home, color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: 12),
              // Project info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (project.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location ?? 'Location not specified',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${project.propertiesCount} properties',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createChatWithProject(
    FeaturedDeveloper developer,
    ProjectModel project,
  ) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

      // Create chat with project
      final chat = await chatService.createChat(
        developerId: developer.developerId,
        projectId: project.projectId,
      );

      if (!mounted) return;

      // Send welcome message from developer
      try {
        final welcomeMessage = _generateWelcomeMessage(developer, project);
        await chatService.sendMessage(
          chatId: chat.chatId,
          content: welcomeMessage,
        );
      } catch (e) {
        print('Error sending welcome message: $e');
        // Don't fail the whole process if welcome message fails
      }

      // Close the project selection dialog
      Navigator.pop(context);

      // Navigate to the new chat
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(chat: chat)),
      ).then((_) => _loadChats());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat started with ${developer.fullName} about ${project.name}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      print('Error creating chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateWelcomeMessage(
    FeaturedDeveloper developer,
    ProjectModel project,
  ) {
    final companyName = developer.companyName ?? developer.fullName;
    final projectName = project.name;

    // Generate different welcome messages based on project type
    final messages = [
      "Welcome to $companyName! 👋 I'm excited to discuss the $projectName project with you. How can I help you today?",
      "Hello! Thanks for your interest in $projectName. I'm here to answer any questions about our $companyName project. What would you like to know?",
      "Welcome! I'm thrilled you're interested in $projectName. As part of the $companyName team, I'm here to help with any questions you might have.",
      "Hi there! 👋 Welcome to $companyName. I see you're interested in our $projectName project. How can I assist you today?",
      "Hello! Thank you for reaching out about $projectName. I'm here to help you with any questions about this $companyName development. What can I tell you?",
    ];

    // Use project name hash to consistently pick the same message for the same project
    final hash = projectName.hashCode;
    final index = hash.abs() % messages.length;
    return messages[index];
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Sign In Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                const Text(
                  'To connect with developers and discuss their projects, you need to be signed in to your account.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Benefits list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitItem(
                        Icons.chat_bubble_outline,
                        'Chat with developers',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        Icons.home_work_outlined,
                        'Discuss project details',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        Icons.verified_user_outlined,
                        'Get personalized assistance',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.secondary.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to auth page
                          Navigator.pushNamed(context, '/auth');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.secondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_filteredChats.isEmpty &&
                _aiChats.isEmpty &&
                _featuredDevelopers.isEmpty)
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await _loadChats();
                await _loadFeaturedDevelopers();
              },
              child: CustomScrollView(
                slivers: [
                  // Featured Developers Section
                  if (_featuredDevelopers.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildFeaturedDevelopersSection(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                  // AI Chats Section
                  if (_aiChats.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.smart_toy,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildAIChatItem(_aiChats[index]),
                        childCount: _aiChats.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                  // Regular Chats Section
                  if (_filteredChats.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Conversations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildChatItem(_filteredChats[index]),
                        childCount: _filteredChats.length,
                      ),
                    ),
                  ],
                  // Empty state if no content
                  if (_filteredChats.isEmpty &&
                      _aiChats.isEmpty &&
                      _featuredDevelopers.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildAIChatItem(AIBrokerChatSummary aiChat) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIBrokerChatPage(aichatId: aiChat.aichatId),
          ),
        ).then((_) => _loadChats());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.blue[200]!, width: 2),
          ),
        ),
        child: Row(
          children: [
            // AI Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'My Broker',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(
                          aiChat.lastMessageAt,
                          locale: 'en_short',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aiChat.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(Chat chat) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isUser = appState.user?.accountId == chat.userId;
    final displayName = isUser ? chat.developerName : chat.userName;
    final hasUnread = chat.unreadCount > 0;

    return Dismissible(
      key: Key('chat_${chat.chatId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage(chat: chat)),
          ).then((_) => _loadChats());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primary.withOpacity(0.05)
                : AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.secondary.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  (displayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(
                            chat.lastMessageAt,
                            locale: 'en_short',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.secondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (chat.projectName != null) ...[
                      Text(
                        chat.projectName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.secondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedDevelopersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Featured Developers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_loadingDevelopers)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: _loadingDevelopers
              ? const Center(child: CircularProgressIndicator())
              : _featuredDevelopers.isEmpty
              ? const Center(
                  child: Text(
                    'No developers available',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredDevelopers.length,
                  itemBuilder: (context, index) {
                    final developer = _featuredDevelopers[index];
                    return _buildDeveloperCard(developer);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(FeaturedDeveloper developer) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          // Check authentication before showing project selection
          final appState = Provider.of<AppState>(context, listen: false);
          if (!appState.isLoggedIn) {
            _showLoginRequiredDialog();
            return;
          }
          _showProjectSelectionDialog(developer);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Developer avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: developer.profileImageUrl != null
                    ? NetworkImage(developer.profileImageUrl!)
                    : null,
                child: developer.profileImageUrl == null
                    ? Text(
                        developer.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              // Developer name
              Text(
                developer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    developer.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Active projects
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${developer.activeProjectsCount} projects',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start chatting with developers\nabout their projects',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
