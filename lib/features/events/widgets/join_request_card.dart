import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../models/join_request_model.dart';

/// Join Request Card Widget - T053
///
/// Displays join request information with approve/decline actions.
/// Shows requester profile, about me, and time of request.
class JoinRequestCard extends StatefulWidget {
  final JoinRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final bool isLoading;

  const JoinRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onDecline,
    this.isLoading = false,
  });

  @override
  State<JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<JoinRequestCard> {
  /// Format time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else if (diff.inDays == 1) {
      return 'Вчера в ${DateFormat('HH:mm').format(time)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн назад';
    } else {
      return DateFormat('d MMM').format(time);
    }
  }

  /// Navigate to user profile
  void _navigateToProfile(BuildContext context) {
    context.push('/user/${widget.request.requesterId}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester info row
            Row(
              children: [
                // Photo
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: CachedNetworkImageProvider(
                      widget.request.requesterPhotoUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and age
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.requesterName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.request.requesterAge} лет',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Time since request
                Text(
                  _formatTime(widget.request.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // About me section
            if (widget.request.requesterAboutMe != null &&
                widget.request.requesterAboutMe!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.request.requesterAboutMe!.length > 150
                    ? '${widget.request.requesterAboutMe!.substring(0, 150)}...'
                    : widget.request.requesterAboutMe!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.isLoading ? null : widget.onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: widget.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(Icons.close, size: 20),
                    label: const Text('Отклонить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isLoading ? null : widget.onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: widget.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: const Text('Принять'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
