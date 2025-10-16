import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../pages/ai_broker_chat_page.dart';
import '../services/ai_broker_service.dart';

/// A floating circular button that appears on all pages, similar to Facebook Messenger
/// Shows the AI Broker icon with unread message count badge
class FloatingAIBrokerButton extends StatefulWidget {
  const FloatingAIBrokerButton({super.key});

  @override
  State<FloatingAIBrokerButton> createState() => _FloatingAIBrokerButtonState();
}

class _FloatingAIBrokerButtonState extends State<FloatingAIBrokerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track position as offset from bottom-right
  double rightOffset = 16;
  double bottomOffset = 100;

  @override
  void initState() {
    super.initState();

    print('🔵 FloatingAIBrokerButton: Widget initialized');

    // Animation for pulsing effect when there are unread messages
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openAIBroker() async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // Mark all notifications as read when opening the broker
      await appState.notificationService.markAllAsRead();

      // Check if there's an active conversation
      final activeResponse = await AIBrokerService.getActiveChat();

      if (activeResponse.success && activeResponse.data != null && mounted) {
        // Open existing active conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AIBrokerChatPage(aichatId: activeResponse.data!.aichatId),
          ),
        );
      } else if (mounted) {
        // No active conversation, create new one
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIBrokerChatPage()),
        );
      }
    } catch (e) {
      // On error, just open with no ID (will create new)
      print('Error checking for active chat: $e');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIBrokerChatPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🔵 FloatingAIBrokerButton: Building widget at right=$rightOffset, bottom=$bottomOffset',
    );

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final unreadCount = appState.notificationService.unreadCount;
        final hasUnread = unreadCount > 0;

        print('🔵 FloatingAIBrokerButton: Unread count = $unreadCount');

        return Positioned(
          right: rightOffset,
          bottom: bottomOffset,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                rightOffset -= details.delta.dx;
                bottomOffset -= details.delta.dy;

                // Keep within bounds
                final size = MediaQuery.of(context).size;
                rightOffset = rightOffset.clamp(16.0, size.width - 76.0);
                bottomOffset = bottomOffset.clamp(16.0, size.height - 76.0);
              });
            },
            child: AnimatedBuilder(
              animation: hasUnread
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: hasUnread ? _scaleAnimation.value : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _openAIBroker,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // AI Icon
                      const Center(
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // Badge with unread count
                      if (hasUnread)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
