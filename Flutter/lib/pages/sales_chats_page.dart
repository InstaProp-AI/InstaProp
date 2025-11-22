import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class SalesChatsPage extends StatefulWidget {
  const SalesChatsPage({super.key});

  @override
  State<SalesChatsPage> createState() => _SalesChatsPageState();
}

class _SalesChatsPageState extends State<SalesChatsPage> {
  List<Chat> _chats = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      final chats = await chatService.getChats();
      setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    }
  }

  List<Chat> get _availableChats {
    return _chats.where((chat) => chat.isAvailable).toList();
  }

  List<Chat> get _myChats {
    final appState = Provider.of<AppState>(context, listen: false);
    return _chats.where((chat) => 
      chat.salesMemberId == appState.user?.accountId
    ).toList();
  }

  List<Chat> get _filteredChats {
    final allChats = [..._myChats, ..._availableChats];
    if (_searchQuery.isEmpty) return allChats;

    return allChats.where((chat) {
      final userName = chat.userName?.toLowerCase() ?? '';
      final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return userName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  Future<void> _takeChat(Chat chat) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      await chatService.takeChat(chat.chatId);
      await _loadChats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat taken successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error taking chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Chat list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chats available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        child: ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final isAvailable = chat.isAvailable;
                            final isMyChat = chat.salesMemberId ==
                                Provider.of<AppState>(context, listen: false)
                                    .user?.accountId;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isAvailable
                                      ? Colors.orange
                                      : AppColors.primary,
                                  child: Icon(
                                    isAvailable
                                        ? Icons.access_time
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  chat.userName ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (chat.lastMessage != null)
                                      Text(
                                        chat.lastMessage!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          timeago.format(chat.lastMessageAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (chat.unreadCount > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${chat.unreadCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: isAvailable
                                    ? ElevatedButton(
                                        onPressed: () => _takeChat(chat),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Take Chat'),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChatPage(chat: chat),
                                            ),
                                          ).then((_) => _loadChats());
                                        },
                                      ),
                                onTap: isMyChat
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatPage(chat: chat),
                                          ),
                                        ).then((_) => _loadChats());
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

