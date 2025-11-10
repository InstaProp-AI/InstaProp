import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_broker_service.dart';
import '../services/notification_service.dart';
import '../services/auction_service.dart';
import '../models/notification.dart';
import '../widgets/developer_comparison_card.dart';
import '../widgets/property_suggestion_card.dart';
import '../widgets/notification_message_card.dart';
import '../pages/auction_details_page.dart';
import 'progressive_network_image.dart';
import 'dart:async';

/// Messenger-style floating chat window
class FloatingChatWindow extends StatefulWidget {
  final int? aichatId;
  final VoidCallback onClose;

  const FloatingChatWindow({super.key, this.aichatId, required this.onClose});

  @override
  State<FloatingChatWindow> createState() => _FloatingChatWindowState();
}

class _FloatingChatWindowState extends State<FloatingChatWindow>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  List<AIBrokerMessage> _messages = [];
  List<AppNotification> _notificationMessages = [];
  int? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isMinimized = false;
  StreamSubscription<AppNotification>? _notificationSubscription;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Draggable position (from bottom-right)
  double rightOffset = 16;
  double bottomOffset = 16;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _loadNotifications();
    _listenToNotifications();
    _markAllNotificationsAsRead();

    // Initialize chat - check for active chat first
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (widget.aichatId != null) {
        // If a specific chat ID was passed, load it
        await _loadConversation(widget.aichatId!);
      } else if (appState.activeAIChatId != null) {
        // If we have an active chat ID stored, use it
        print('🤖 Floating: Loading existing chat: ${appState.activeAIChatId}');
        await _loadConversation(appState.activeAIChatId!);
      } else {
        // No active chat, try to get the most recent one from API
        print('🤖 Floating: Checking for existing chat from API...');
        final activeResponse = await AIBrokerService.getActiveChat();

        if (activeResponse.success && activeResponse.data != null) {
          print(
            '🤖 Floating: Found active chat: ${activeResponse.data!.aichatId}',
          );
          appState.setActiveAIChatId(activeResponse.data!.aichatId);
          await _loadConversation(activeResponse.data!.aichatId);
        } else {
          // No existing chat, create a new one
          print('🤖 Floating: No existing chat found, creating new one');
          await _startNewConversation();
        }
      }
    } catch (e) {
      print('🤖 Floating: Error initializing chat: $e');
      _showError('Error initializing chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _notificationSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
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

  void _loadNotifications() {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

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

    _notificationSubscription = notificationService.notificationStream.listen((
      notification,
    ) {
      setState(() {
        _notificationMessages.insert(0, notification);
      });
      _scrollToBottom();
    });
  }

  Future<void> _startNewConversation() async {
    try {
      final response = await AIBrokerService.startConversation();

      if (response.success && response.data != null) {
        // Store the new chat ID in AppState
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setActiveAIChatId(response.data!.aichatId);

        setState(() {
          _currentChatId = response.data!.aichatId;
          _messages = response.data!.messages;
        });
        _scrollToBottom();
      } else {
        _showError(response.error ?? 'Failed to start conversation');
      }
    } catch (e) {
      _showError('Error starting conversation: $e');
    }
  }

  Future<void> _loadConversation(int aichatId) async {
    try {
      final response = await AIBrokerService.getConversation(aichatId);

      if (response.success && response.data != null) {
        // Store the chat ID in AppState
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setActiveAIChatId(response.data!.aichatId);

        setState(() {
          _currentChatId = response.data!.aichatId;
          _messages = response.data!.messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Error loading conversation: $e');
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

  void _closeWindow() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _toggleMinimize() {
    setState(() => _isMinimized = !_isMinimized);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      right: rightOffset,
      bottom: bottomOffset,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value * 400, 0),
            child: Opacity(opacity: _fadeAnimation.value, child: child),
          );
        },
        child: Material(
          elevation: 16,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black45,
          child: Container(
            width: 360,
            height: _isMinimized ? 60 : 550,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              children: [
                // Header (Messenger style) - draggable area
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      rightOffset = (rightOffset - details.delta.dx).clamp(
                        16.0,
                        size.width - 370.0,
                      );
                      bottomOffset = (bottomOffset - details.delta.dy).clamp(
                        16.0,
                        size.height - (_isMinimized ? 76.0 : 566.0),
                      );
                    });
                  },
                  child: _buildHeader(),
                ),

                // Chat content (only show when not minimized)
                if (!_isMinimized) ...[
                  // Messages
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildMessagesList(),
                  ),

                  // Input area
                  _buildMessageInput(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Broker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AI Property Assistant',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleMinimize,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  _isMinimized ? Icons.expand_less : Icons.minimize,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _closeWindow,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount:
          _notificationMessages.length +
          _messages.length +
          (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSending &&
            index == _notificationMessages.length + _messages.length) {
          return _buildTypingIndicator();
        }

        if (index < _notificationMessages.length) {
          final notification = _notificationMessages[index];
          return _buildNotificationMessage(notification);
        }

        final messageIndex = index - _notificationMessages.length;
        final message = _messages[messageIndex];
        return _buildMessage(message);
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
        margin: const EdgeInsets.only(bottom: 8, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(AIBrokerMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // Choice buttons
            if (message.messageType == 'OptionsPrompt' &&
                message.options != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.options!
                      .map(
                        (option) => OutlinedButton(
                          onPressed: _isSending
                              ? null
                              : () => _sendChoice(option, message.questionType),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2196F3),
                            side: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Developer comparison cards
            if (message.messageType == 'DeveloperComparison' &&
                message.developers != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DeveloperComparisonCard(
                  developers: message.developers!,
                  onDeveloperTap: (id) {},
                ),
              ),

            // Property suggestion cards
            if (message.messageType == 'PropertySuggestions' &&
                message.properties != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: message.properties!
                      .map(
                        (property) => PropertySuggestionCard(
                          property: property,
                          onViewDetails: () =>
                              _showPropertyDetailsDialog(property),
                          onGoToAuction: () {},
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Typing...',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSending,
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendTextMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _isSending
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                color: _isSending ? Colors.grey[300] : null,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
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
      case 'place_bid':
      case 'view_auction':
        if (notification.auctionId != null) {
          _showInfo('Opening auction...');
          try {
            final response = await AuctionService.getAuction(
              notification.auctionId!,
            );
            if (response.success && response.data != null) {
              if (!mounted) return;
              await notificationService.markAsRead(notification.notificationId);
              // Close the floating window and navigate to auction page
              _closeWindow();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuctionDetailsPage(auction: response.data!),
                ),
              );
            }
          } catch (e) {
            _showError('Error loading auction: $e');
          }
        }
        break;
      case 'dismiss':
        await notificationService.markAsRead(notification.notificationId);
        setState(() {
          _notificationMessages.removeWhere(
            (n) => n.notificationId == notification.notificationId,
          );
        });
        break;
      default:
        _showInfo('Feature coming soon!');
    }
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
            if (property.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ProgressiveNetworkImage(
                  imageUrl: property.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 64),
                  ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${property.currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }
}
