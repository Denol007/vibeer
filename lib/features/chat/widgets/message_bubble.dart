import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../models/message_model.dart';

/// Message Bubble Widget - T055
///
/// Displays a chat message with different styling for:
/// - Own messages (right-aligned, primary color)
/// - Other messages (left-aligned, gray)
/// - System messages (centered, gray, italic)
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onReply,
  });

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today: show only time
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Вчера ${DateFormat('HH:mm').format(timestamp)}';
    } else if (now.difference(timestamp).inDays < 7) {
      // Last 7 days: show day of week
      final weekday = [
        'Пн',
        'Вт',
        'Ср',
        'Чт',
        'Пт',
        'Сб',
        'Вс',
      ][timestamp.weekday - 1];
      return '$weekday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      // Older: show date
      return DateFormat('d MMM HH:mm').format(timestamp);
    }
  }

  /// Navigate to user profile
  void _navigateToProfile(BuildContext context, String userId) {
    context.push('/user/$userId');
  }

  @override
  Widget build(BuildContext context) {
    // System message styling
    if (message.isSystemMessage) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final isOwnMessage = message.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user's photo on left
          if (!isOwnMessage) ...[
            GestureDetector(
              onTap: () => _navigateToProfile(context, message.senderId),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: message.senderPhotoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  memCacheWidth: 64,
                  memCacheHeight: 64,
                  maxWidthDiskCache: 64,
                  maxHeightDiskCache: 64,
                  placeholder: (context, url) => Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
            // Sender name (for other users)
            if (!isOwnMessage)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: GestureDetector(
                  onTap: () => _navigateToProfile(context, message.senderId),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),                // Message content with long-press
                GestureDetector(
                  onLongPress: onReply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnMessage
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isOwnMessage
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isOwnMessage
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show replied message if exists
                        if (message.replyToMessageId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isOwnMessage
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isOwnMessage
                                      ? Colors.white
                                      : AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToSenderName ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOwnMessage
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message.replyToText ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isOwnMessage
                                        ? Colors.white.withOpacity(0.8)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Message text
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isOwnMessage
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Timestamp and read status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOwnMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            // Read status (only for own messages)
                            if (isOwnMessage && message.readBy.length > 1) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 14,
                                color: Colors.blue[300],
                              ),
                            ] else if (isOwnMessage) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Own user's photo on right
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: message.senderPhotoUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                memCacheWidth: 64,
                memCacheHeight: 64,
                maxWidthDiskCache: 64,
                maxHeightDiskCache: 64,
                placeholder: (context, url) => Container(
                  width: 32,
                  height: 32,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 32,
                  height: 32,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
