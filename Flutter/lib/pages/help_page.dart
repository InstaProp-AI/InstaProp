import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/faq.dart';
import '../models/help_chat.dart';
import '../models/chat.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../services/help_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';
import 'faq_page.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _messageController = TextEditingController();
  final Set<int> _expandedFaqs = <int>{};

  bool _loadingFaqs = true;
  bool _loadingChat = false;
  bool _sending = false;

  List<Faq> _faqs = [];
  HelpChatDetails? _supportChat;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
    _loadSupportChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loadingFaqs = true);
    try {
      final helpService = HelpService(ApiClient.baseUrl);
      final faqs = await helpService.getFaqPreview(limit: 10);
      if (!mounted) return;
      setState(() {
        _faqs = faqs;
        _loadingFaqs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFaqs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load FAQs: $e')),
      );
    }
  }

  Future<void> _loadSupportChat() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isLoggedIn) {
      setState(() => _supportChat = null);
      return;
    }

    setState(() => _loadingChat = true);

    try {
      final helpService = HelpService(ApiClient.baseUrl, token: appState.token);
      final details = await helpService.getSupportChat();
      if (!mounted) return;
      setState(() {
        _supportChat = details;
        _loadingChat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load support chat: $e')),
      );
    }
  }

  void _toggleFaq(int faqId) {
    setState(() {
      if (_expandedFaqs.contains(faqId)) {
        _expandedFaqs.remove(faqId);
      } else {
        _expandedFaqs.add(faqId);
      }
    });
  }

  Future<void> _sendSupportMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message first.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _sending = true);

    try {
      final helpService = HelpService(ApiClient.baseUrl, token: appState.token);
      final response = await helpService.sendSupportMessage(message);
      final chatService = ChatService(ApiClient.baseUrl, token: appState.token);
      final chatDetails = await chatService.getChatDetails(response.chatId);

      final chat = Chat(
        chatId: chatDetails.chatId,
        userId: chatDetails.userId,
        userName: chatDetails.userName,
        developerId: chatDetails.developerId,
        developerName:
            chatDetails.developerName ?? response.supportTitle,
        projectId: chatDetails.projectId,
        projectName: chatDetails.projectName,
        createdAt: chatDetails.createdAt,
        lastMessageAt: chatDetails.lastMessageAt,
        isActive: chatDetails.isActive,
        lastMessage: response.message.content,
        unreadCount: 0,
        isSupportChat: true,
      );

      if (!mounted) return;
      _messageController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(chat: chat)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _loadSupportChat();
      }
    }
  }

  Future<void> _openSupportChat() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _loadingChat = true);

    try {
      final chatService = ChatService(ApiClient.baseUrl, token: appState.token);
      final helpService = HelpService(ApiClient.baseUrl, token: appState.token);
      final details = await helpService.getSupportChat();

      if (details == null || !details.hasChat) {
        if (!mounted) return;
        setState(() => _loadingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start by sending us a message first.')),
        );
        return;
      }

      final chatDetails = await chatService.getChatDetails(details.chatId!);
      final chat = Chat(
        chatId: chatDetails.chatId,
        userId: chatDetails.userId,
        userName: chatDetails.userName,
        developerId: chatDetails.developerId,
        developerName: chatDetails.developerName ?? details.supportTitle,
        projectId: chatDetails.projectId,
        projectName: chatDetails.projectName,
        createdAt: chatDetails.createdAt,
        lastMessageAt: chatDetails.lastMessageAt,
        isActive: chatDetails.isActive,
        lastMessage: chatDetails.messages.isNotEmpty
            ? chatDetails.messages.last.content
            : null,
        unreadCount: chatDetails.messages
            .where((m) => !m.isRead && m.senderId != appState.user?.accountId)
            .length,
        isSupportChat: true,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(chat: chat)),
      ).then((_) => _loadSupportChat());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open support chat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingChat = false);
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please sign in to contact customer support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFaqs();
          await _loadSupportChat();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Frequently Asked Questions'),
              const SizedBox(height: 12),
              _buildFaqSection(),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqPage()),
                    );
                  },
                  child: const Text('See all FAQs'),
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Chat with us now'),
              const SizedBox(height: 12),
              _buildChatCard(appState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFaqSection() {
    if (_loadingFaqs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_faqs.isEmpty) {
      return const Text('No FAQs available yet.');
    }

    return Column(
      children: _faqs.map(_buildFaqItem).toList(),
    );
  }

  Widget _buildFaqItem(Faq faq) {
    final isExpanded = _expandedFaqs.contains(faq.faqId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleFaq(faq.faqId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.secondary,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(AppState appState) {
    final supportTitle = _supportChat?.supportTitle ?? 'Customer Support';
    final lastMessage = _supportChat?.messages.isNotEmpty == true
        ? _supportChat!.messages.last
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.headset_mic, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supportTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          '${lastMessage.senderName}: ${lastMessage.content}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      if (lastMessage != null)
                        Text(
                          timeago.format(lastMessage.createdAt, locale: 'en_short'),
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
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'How can we help you?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              enabled: !_sending,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendSupportMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Sending...' : 'Send message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingChat
                        ? null
                        : (_supportChat?.hasChat == true
                            ? _openSupportChat
                            : null),
                    icon: _loadingChat
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: Text(_supportChat?.hasChat == true
                        ? 'Open chat'
                        : 'Start a chat'),
                  ),
                ),
              ],
            ),
            if (!appState.isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Sign in to send us a message.',
                  style: TextStyle(
                    color: AppColors.secondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

