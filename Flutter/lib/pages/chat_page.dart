import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/property.dart';
import '../services/chat_service.dart';
import '../services/chat_firestore_service.dart';
import '../services/property_service.dart';
import '../services/api_client.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatFirestoreService _firestoreService = ChatFirestoreService();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Property? _selectedProperty;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _markAsRead();
    _ensureFirebaseAuth();
  }

  Future<void> _ensureFirebaseAuth() async {
    // Ensure Firebase Auth is ready before Firestore listeners start
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⏳ Waiting for Firebase auth...');
      // Wait for auth state to be ready
      await Future.delayed(const Duration(milliseconds: 1000));
      final retryUser = FirebaseAuth.instance.currentUser;
      if (retryUser != null) {
        print('✅ Firebase auth ready: ${retryUser.uid}');
        setState(() => _firebaseReady = true);
      } else {
        print('⚠️ Firebase auth still not ready - Firestore may fail');
        setState(() => _firebaseReady = false);
      }
    } else {
      print('✅ Firebase auth already ready: ${user.uid}');
      setState(() => _firebaseReady = true);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      final chatDetails = await chatService.getChatDetails(widget.chat.chatId);
      setState(() {
        _messages = chatDetails.messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    try {
      await chatService.markAsRead(widget.chat.chatId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final chatService = ChatService(ApiClient.baseUrl, token: appState.token);

    setState(() => _sending = true);

    try {
      final message = await chatService.sendMessage(
        chatId: widget.chat.chatId,
        content: _messageController.text.trim(),
        propertyId: _selectedProperty?.propertyId,
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
        _selectedProperty = null;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message')));
    } finally {
      setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPropertyPicker() async {
    try {
      final response = await PropertyService.getMyProperties();
      final properties = response.data ?? [];

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Property to Share',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...properties.map(
                (property) => ListTile(
                  leading: property.imageUrl.isNotEmpty
                      ? Image.network(
                          property.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.home),
                  title: Text(property.name),
                  subtitle: Text(property.location),
                  onTap: () {
                    setState(() => _selectedProperty = property);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error loading properties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isUser = appState.user?.accountId == widget.chat.userId;
    final otherPersonName = isUser
        ? widget.chat.developerName
        : widget.chat.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherPersonName ?? 'Chat',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.chat.projectName != null)
              Text(
                widget.chat.projectName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_firebaseReady
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<ChatMessage>>(
                    stream: _firestoreService.streamChatMessages(
                      widget.chat.chatId,
                    ),
                    initialData: _messages,
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? _messages;

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Say hi!',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe =
                              message.senderId == appState.user?.accountId;
                          return _buildMessageBubble(message, isMe);
                        },
                      );
                    },
                  ),
          ),

          // Property preview if selected
          if (_selectedProperty != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                children: [
                  if (_selectedProperty!.imageUrl.isNotEmpty)
                    Image.network(
                      _selectedProperty!.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedProperty!.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedProperty = null),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: AppColors.primary),
                  onPressed: _showPropertyPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.surface,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.surface,
                          ),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Property preview if present
            if (message.hasProperty) ...[
              GestureDetector(
                onTap: () {
                  // Navigate to property details
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsPage(propertyId: message.propertyId!)));
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.propertyImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.propertyImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.propertyName ?? 'Property',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (message.propertyLocation != null)
                              Text(
                                message.propertyLocation!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ),
            ],

            // Message bubble
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? AppColors.surface : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
