import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../providers/app_state.dart';
import '../services/ai_broker_service.dart';
import '../services/notification_service.dart';
import '../services/auction_service.dart';
import '../services/bid_service.dart';
import '../widgets/developer_comparison_card.dart';
import '../widgets/property_suggestion_card.dart';
import '../widgets/notification_message_card.dart';
import '../models/notification.dart';
import 'auction_details_page.dart';
import 'dart:async';

class AIBrokerChatPage extends StatefulWidget {
  final String? aichatId;

  const AIBrokerChatPage({super.key, this.aichatId});

  @override
  State<AIBrokerChatPage> createState() => _AIBrokerChatPageState();
}

class _AIBrokerChatPageState extends State<AIBrokerChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  List<AIBrokerMessage> _messages = [];
  List<AppNotification> _notificationMessages = [];
  String? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription<AppNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();

    // Load past notifications and listen to new ones
    _loadNotifications();
    _listenToNotifications();

    // Mark all notifications as read when the chat is opened
    _markAllNotificationsAsRead();

    // Initialize chat - check for active chat first
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('🤖 _initializeChat: Starting initialization');
    setState(() => _isLoading = true);

    try {
      // First, check if there's already an active chat in AppState
      final appState = Provider.of<AppState>(context, listen: false);
      print(
        '🤖 _initializeChat: AppState activeAIChatId = ${appState.activeAIChatId}, widget.aichatId = ${widget.aichatId}',
      );

      if (widget.aichatId != null) {
        // If a specific chat ID was passed, load it
        print(
          '🤖 _initializeChat: Loading specific chat ID: ${widget.aichatId}',
        );
        await _loadConversation(widget.aichatId!);
      } else if (appState.activeAIChatId != null) {
        // If we have an active chat ID stored, use it
        print(
          '🤖 _initializeChat: Loading existing chat from AppState: ${appState.activeAIChatId}',
        );
        await _loadConversation(appState.activeAIChatId!);
      } else {
        // No active chat, try to get the most recent one from API
        print('🤖 _initializeChat: Checking for existing chat from API...');
        final activeResponse = await AIBrokerService.getActiveChat();
        print(
          '🤖 _initializeChat: Active chat response: success=${activeResponse.success}, data=${activeResponse.data}',
        );

        if (activeResponse.success && activeResponse.data != null) {
          print(
            '🤖 _initializeChat: Found active chat: ${activeResponse.data!.aichatId}',
          );
          appState.setActiveAIChatId(activeResponse.data!.aichatId);
          await _loadConversation(activeResponse.data!.aichatId);
        } else {
          // No existing chat, create a new one
          print('🤖 _initializeChat: No existing chat found, creating new one');
          await _startNewConversation();
        }
      }
      print('🤖 _initializeChat: Initialization completed successfully');
    } catch (e, stackTrace) {
      print('🤖 _initializeChat: ❌ Error: $e');
      print('🤖 _initializeChat: Stack trace: $stackTrace');
      _showError('Error initializing chat: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('🤖 _initializeChat: Set loading to false');
      }
    }
  }

  void _markAllNotificationsAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      notificationService.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _loadNotifications() {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    // Load past notifications (last 20)
    setState(() {
      _notificationMessages = notificationService.notifications
          .take(20)
          .toList();
    });
  }

  void _listenToNotifications() {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    // Listen to new notifications
    _notificationSubscription = notificationService.notificationStream.listen((
      notification,
    ) {
      print('🤖 Chatbot received new notification: ${notification.title}');
      setState(() {
        _notificationMessages.insert(0, notification);
      });
      _scrollToBottom();

      // Show push notification when app is in foreground
      _showPushNotification(notification);
    });
  }

  void _showPushNotification(AppNotification notification) {
    // Show a snackbar notification that opens chatbot when tapped
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My Broker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      notification.title,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _startNewConversation() async {
    try {
      print('🤖 _startNewConversation: Starting AI Broker conversation...');
      final response = await AIBrokerService.startConversation();

      print(
        '🤖 _startNewConversation: Response received: success=${response.success}, error=${response.error}, statusCode=${response.statusCode}',
      );

      if (response.success && response.data != null) {
        print('🤖 _startNewConversation: Chat ID: ${response.data!.aichatId}');
        print(
          '🤖 _startNewConversation: Messages count: ${response.data!.messages.length}',
        );
        print(
          '🤖 _startNewConversation: Messages: ${response.data!.messages.map((m) => '${m.role}: ${m.content.substring(0, m.content.length > 30 ? 30 : m.content.length)}...').toList()}',
        );

        // Store the new chat ID in AppState
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setActiveAIChatId(response.data!.aichatId);
        print('🤖 _startNewConversation: Stored chat ID in AppState');

        if (mounted) {
          setState(() {
            _currentChatId = response.data!.aichatId;
            _messages = response.data!.messages;
          });
          print(
            '🤖 _startNewConversation: setState completed - _currentChatId=$_currentChatId, _messages.length=${_messages.length}',
          );
          _scrollToBottom();
        } else {
          print(
            '🤖 _startNewConversation: Widget not mounted, skipping setState',
          );
        }
      } else {
        print('🤖 _startNewConversation: ❌ Failed - ${response.error}');
        _showError(response.error ?? 'Failed to start conversation');
      }
    } catch (e, stackTrace) {
      print('🤖 _startNewConversation: ❌ Exception: $e');
      print('🤖 _startNewConversation: Stack trace: $stackTrace');
      _showError('Error starting conversation: $e');
    }
  }

  Future<void> _clearHistoryAndStartNew() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will start a new conversation. Your previous messages will not be deleted from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear & Start New'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      // Clear the active chat ID
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearActiveAIChat();

      // Start a new conversation
      await _startNewConversation();

      setState(() => _isLoading = false);

      _showSuccess('Started new conversation!');
    }
  }

  Future<void> _loadConversation(String aichatId) async {
    setState(() => _isLoading = true);

    try {
      final response = await AIBrokerService.getConversation(aichatId);

      print(
        '🤖 _loadConversation response: success=${response.success}, data=${response.data}',
      );

      if (response.success && response.data != null) {
        print(
          '🤖 Setting messages: ${response.data!.messages.length} messages',
        );
        print(
          '🤖 Messages: ${response.data!.messages.map((m) => '${m.role}: ${m.content.substring(0, m.content.length > 50 ? 50 : m.content.length)}...').toList()}',
        );

        setState(() {
          _currentChatId = response.data!.aichatId;
          _messages = response.data!.messages;
        });

        print(
          '🤖 After setState: _messages.length = ${_messages.length}, _currentChatId = $_currentChatId',
        );
        _scrollToBottom();
      } else {
        print('🤖 Response failed: ${response.error}');
        _showError(response.error ?? 'Failed to load conversation');
      }
    } catch (e, stackTrace) {
      print('🤖 Exception in _loadConversation: $e');
      print('🤖 Stack trace: $stackTrace');
      _showError('Error loading conversation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendChoice(String choice, String? questionType) async {
    await _sendMessage(choice, questionType);
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await _sendMessage(text, null);
  }

  Future<void> _sendMessage(String message, String? questionType) async {
    if (_currentChatId == null) return;

    setState(() => _isSending = true);

    try {
      // Add user message to UI immediately
      setState(() {
        _messages.add(
          AIBrokerMessage(
            messageId: 0,
            role: 'User',
            content: message,
            messageType: 'Text',
            createdAt: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();

      final response = await AIBrokerService.sendMessage(
        aichatId: _currentChatId!,
        message: message,
        questionType: questionType,
      );

      if (response.success && response.data != null) {
        setState(() {
          _messages.addAll(response.data!.messages);
        });
        _scrollToBottom();

        // Foreground alert for new assistant messages
        final newAssistantMessages = response.data!.messages
            .where((m) => m.role != 'User')
            .toList();
        if (newAssistantMessages.isNotEmpty && mounted) {
          final preview = newAssistantMessages.last.content;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        _showError(response.error ?? 'Failed to send message');
      }
    } catch (e) {
      _showError('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToAuction(int? auctionId) {
    if (auctionId == null) {
      _showError('Auction not available');
      return;
    }

    // Show loading and fetch auction details, then navigate
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Loading auction details...')));

    // For now, just show a message. In production, fetch the auction and navigate
    // You would call AuctionService.getAuction(auctionId) then navigate with the Auction object
  }

  void _navigateToDeveloperProfile(int developerId) {
    // Navigate to developer profile by ID
    Navigator.pushNamed(
      context,
      '/developer-profile',
      arguments: {'developerId': developerId},
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🤖 AIBrokerChatPage.build() called - _isLoading=$_isLoading, _messages.length=${_messages.length}, _currentChatId=$_currentChatId',
    );
    return Consumer<AppState>(
      builder: (context, appState, _) {
        print(
          '🤖 AIBrokerChatPage Consumer builder - activeAIChatId=${appState.activeAIChatId}',
        );
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Broker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI Property Assistant',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            iconTheme: const IconThemeData(color: AppColors.primary),
            elevation: 2,
            actions: [
              // Clear history button
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: AppColors.primary),
                onPressed: _clearHistoryAndStartNew,
              ),
              // Show restore button if floating button is hidden
              if (appState.isFloatingButtonHidden)
                IconButton(
                  icon: const Icon(Icons.restore, color: AppColors.primary),
                  onPressed: () {
                    appState.showFloatingButton();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Floating AI Broker restored!',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Builder(
                  builder: (context) {
                    print(
                      '🤖 Building body: _messages.length=${_messages.length}, _notificationMessages.length=${_notificationMessages.length}, _isLoading=$_isLoading',
                    );
                    final totalItems =
                        _notificationMessages.length +
                        _messages.length +
                        (_isSending ? 1 : 0);
                    print('🤖 Total items to display: $totalItems');

                    return Column(
                      children: [
                        // Messages List (notifications + AI messages)
                        Expanded(
                          child: totalItems == 0
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 64,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: totalItems,
                                  itemBuilder: (context, index) {
                                    print(
                                      '🤖 Building item $index of $totalItems',
                                    );

                                    // Show typing indicator at the end
                                    if (_isSending &&
                                        index ==
                                            _notificationMessages.length +
                                                _messages.length) {
                                      return _buildTypingIndicator();
                                    }

                                    // Show notifications first
                                    if (index < _notificationMessages.length) {
                                      final notification =
                                          _notificationMessages[index];
                                      return _buildNotificationMessage(
                                        notification,
                                      );
                                    }

                                    // Then show AI broker messages
                                    final messageIndex =
                                        index - _notificationMessages.length;
                                    if (messageIndex >= 0 &&
                                        messageIndex < _messages.length) {
                                      final message = _messages[messageIndex];
                                      print(
                                        '🤖 Building message $messageIndex: role=${message.role}, content=${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...',
                                      );
                                      return _buildMessage(message);
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),
                        ),
                        // Text Input Area
                        _buildMessageInput(),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMessage(AIBrokerMessage message) {
    if (message.role == 'User') {
      return _buildUserMessage(message);
    } else {
      return _buildAssistantMessage(message);
    }
  }

  Widget _buildUserMessage(AIBrokerMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(AIBrokerMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 15),
              ),
            ),

            // Choice buttons if options are provided
            if (message.messageType == 'OptionsPrompt' &&
                message.options != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.options!
                      .map(
                        (option) => ElevatedButton(
                          onPressed: _isSending
                              ? null
                              : () => _sendChoice(option, message.questionType),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[700],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.blue[200]!),
                            ),
                          ),
                          child: Text(option),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Developer comparison cards
            if (message.messageType == 'DeveloperComparison' &&
                message.developers != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: DeveloperComparisonCard(
                  developers: message.developers!,
                  onDeveloperTap: _navigateToDeveloperProfile,
                ),
              ),

            // Property suggestion cards
            if (message.messageType == 'PropertySuggestions' &&
                message.properties != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: message.properties!
                      .map(
                        (property) => PropertySuggestionCard(
                          property: property,
                          onViewDetails: () {
                            if (property.auctionId != null) {
                              _showPropertyDetailsDialog(property);
                            }
                          },
                          onGoToAuction: () =>
                              _navigateToAuction(property.auctionId),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
            const SizedBox(width: 12),
            const Text('My Broker is thinking...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSending,
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _sendTextMessage,
              icon: Icon(
                Icons.send_rounded,
                color: _isSending ? Colors.grey : Colors.blue,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _isSending
                    ? Colors.grey[200]
                    : Colors.blue[50],
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyDetailsDialog(PropertySuggestion property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Property Image
            if (property.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  property.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 64),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPropertyFeature(
                        Icons.bed,
                        '${property.bedrooms} Bed',
                      ),
                      const SizedBox(width: 16),
                      _buildPropertyFeature(
                        Icons.bathtub,
                        '${property.bathrooms} Bath',
                      ),
                      const SizedBox(width: 16),
                      _buildPropertyFeature(
                        Icons.square_foot,
                        '${property.squareFeet} sqft',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${property.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAuction(property.auctionId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Go to Auction',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildPropertyFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }

  Widget _buildNotificationMessage(AppNotification notification) {
    return NotificationMessageCard(
      notification: notification,
      isRead: notification.isRead,
      onActionTap: (action) => _handleNotificationAction(action, notification),
    );
  }

  Future<void> _handleNotificationAction(
    String action,
    AppNotification notification,
  ) async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    switch (action) {
      case 'quick_bid':
        await _handleQuickBid(notification);
        break;
      case 'place_bid':
        await _handlePlaceBid(notification);
        break;
      case 'view_auction':
        await _handleViewAuction(notification);
        break;
      case 'view_event':
        await _handleViewEvent(notification);
        break;
      case 'find_similar':
        _showInfo('Feature coming soon!');
        break;
      case 'learn_more':
        _showInfo(notification.message);
        break;
      case 'dismiss':
        await _handleDismiss(notification, notificationService);
        break;
      default:
        print('Unknown action: $action');
    }
  }

  Future<void> _handleQuickBid(AppNotification notification) async {
    if (notification.auctionId == null) {
      _showError('Auction information not available');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      // Fetch auction to get current highest bid
      final auctionResponse = await AuctionService.getAuction(
        notification.auctionId!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (!auctionResponse.success || auctionResponse.data == null) {
        _showError('Could not load auction details');
        return;
      }

      final auction = auctionResponse.data!;
      final newBidAmount = auction.currentPrice + 1000;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Bid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current bid: \$${auction.currentPrice.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Text(
                'Your bid: \$${newBidAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to place this bid?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Place Bid'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Place the bid
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );

      final bidResponse = await BidService.placeBid(
        auctionId: auction.auctionId,
        bidAmount: newBidAmount,
        context: context,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (bidResponse.success) {
        _showSuccess('Bid placed successfully!');
        // Mark notification as read
        await Provider.of<NotificationService>(
          context,
          listen: false,
        ).markAsRead(notification.notificationId);
      } else {
        _showError(bidResponse.error ?? 'Failed to place bid');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still showing
        _showError('Error: $e');
      }
    }
  }

  Future<void> _handlePlaceBid(AppNotification notification) async {
    // Same as quick bid but can be customized differently
    await _handleQuickBid(notification);
  }

  Future<void> _handleViewAuction(AppNotification notification) async {
    if (notification.auctionId == null) {
      _showError('Auction information not available');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      final response = await AuctionService.getAuction(notification.auctionId!);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.success && response.data != null) {
        // Mark as read
        await Provider.of<NotificationService>(
          context,
          listen: false,
        ).markAsRead(notification.notificationId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuctionDetailsPage(auction: response.data!),
          ),
        );
      } else {
        _showError(response.error ?? 'Auction not found');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error loading auction: $e');
      }
    }
  }

  Future<void> _handleViewEvent(AppNotification notification) async {
    if (notification.eventId == null) {
      _showError('Event information not available');
      return;
    }

    // Mark as read
    await Provider.of<NotificationService>(
      context,
      listen: false,
    ).markAsRead(notification.notificationId);

    _showInfo('Event details feature coming soon!');
  }

  Future<void> _handleDismiss(
    AppNotification notification,
    NotificationService notificationService,
  ) async {
    await notificationService.markAsRead(notification.notificationId);
    setState(() {
      _notificationMessages.removeWhere(
        (n) => n.notificationId == notification.notificationId,
      );
    });
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
