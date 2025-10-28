import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/message_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../services/chat_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/events_provider.dart';

/// Group Chat Screen - T054
///
/// Real-time chat interface for event participants.
/// Features:
/// - Message list (reversed, newest at bottom)
/// - Auto-scroll to latest message
/// - Message input with send button
/// - Participant list in header
/// - Real-time updates via ChatService stream
class GroupChatScreen extends ConsumerStatefulWidget {
  final String eventId;

  const GroupChatScreen({super.key, required this.eventId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  String? _errorMessage;
  MessageModel? _replyingTo;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle reply to message
  void _handleReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
    });
  }

  /// Cancel reply
  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  /// Handle send message
  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Capture reply data before clearing
    final replyToMessageId = _replyingTo?.id;
    final replyToText = _replyingTo?.text;
    final replyToSenderName = _replyingTo?.senderName;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _replyingTo = null; // Clear reply state
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendMessage(
        eventId: widget.eventId,
        text: text,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );
    } on ChatException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Не удалось отправить сообщение';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Show participants list - navigate to EventParticipantsScreen
  Future<void> _showParticipantsList(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Load event data to get organizer and participants
      final eventsService = ref.read(eventsServiceProvider);
      final event = await eventsService.getEvent(widget.eventId);

      if (!mounted) return;

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (event == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось загрузить данные события'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Navigate to participants screen
      final participantIds = event.participantIds.join(',');
      if (context.mounted) {
        context.push(
          '/event/${event.id}/participants?organizerId=${event.organizerId}&participantIds=$participantIds',
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.watch(chatServiceProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUserId = authService.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат события'),
        actions: [
          // Participants list button
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => _showParticipantsList(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatService.getEventMessages(widget.eventId),
              builder: (context, snapshot) {
                // Show loading only on first load when there's no data yet
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: LoadingIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки сообщений',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Пока нет сообщений',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Начните разговор!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // Use reverse: true to keep scroll position stable
                // New messages appear at the bottom without jumping
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Reverse the index to show messages in correct order
                    final reversedIndex = messages.length - 1 - index;
                    final message = messages[reversedIndex];
                    return MessageBubble(
                      message: message,
                      currentUserId: currentUserId,
                      onReply: () => _handleReply(message),
                    );
                  },
                );
              },
            ),
          ),

          // Reply bar (shown when replying)
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.surfaceVariant,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    color: AppColors.primary,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ответ для ${_replyingTo!.senderName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

          // Message input
          MessageInput(onSend: _handleSendMessage, isLoading: _isSending),
        ],
      ),
    );
  }
}
