import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/ai_broker_service.dart';
import '../widgets/developer_comparison_card.dart';
import '../widgets/property_suggestion_card.dart';

class AIBrokerChatPage extends StatefulWidget {
  final int? aichatId;

  const AIBrokerChatPage({super.key, this.aichatId});

  @override
  State<AIBrokerChatPage> createState() => _AIBrokerChatPageState();
}

class _AIBrokerChatPageState extends State<AIBrokerChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  List<AIBrokerMessage> _messages = [];
  int? _currentChatId;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.aichatId != null) {
      _loadConversation(widget.aichatId!);
    } else {
      _startNewConversation();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startNewConversation() async {
    setState(() => _isLoading = true);

    try {
      print('🤖 Starting AI Broker conversation...');
      final response = await AIBrokerService.startConversation();

      print('🤖 Response received: ${response.success}');
      print('🤖 Error: ${response.error}');
      print('🤖 Status code: ${response.statusCode}');

      if (response.success && response.data != null) {
        print('🤖 Chat ID: ${response.data!.aichatId}');
        print('🤖 Messages count: ${response.data!.messages.length}');

        setState(() {
          _currentChatId = response.data!.aichatId;
          _messages = response.data!.messages;
        });
        _scrollToBottom();
      } else {
        _showError(response.error ?? 'Failed to start conversation');
      }
    } catch (e, stackTrace) {
      print('🤖 Exception: $e');
      print('🤖 Stack trace: $stackTrace');
      _showError('Error starting conversation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConversation(int aichatId) async {
    setState(() => _isLoading = true);

    try {
      final response = await AIBrokerService.getConversation(aichatId);

      if (response.success && response.data != null) {
        setState(() {
          _currentChatId = response.data!.aichatId;
          _messages = response.data!.messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
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
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return _buildMessage(message);
                    },
                  ),
                ),
                // Text Input Area
                _buildMessageInput(),
              ],
            ),
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
}
