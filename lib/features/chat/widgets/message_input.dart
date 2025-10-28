import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Message Input Widget - T056
///
/// Text input field with send button for chat messages.
/// Features:
/// - Max length 1000 characters
/// - Character counter
/// - Send button disabled when empty
/// - Loading state while sending
class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const MessageInput({super.key, required this.onSend, this.isLoading = false});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  static const int _maxLength = 1000;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Handle send button tap
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.isLoading,
                  maxLength: _maxLength,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Написать сообщение...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    counterText: '', // Hide default counter
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (_) => setState(() {}), // Update button state
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: BoxDecoration(
                color: _controller.text.trim().isEmpty || widget.isLoading
                    ? AppColors.textSecondary.withOpacity(0.3)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _controller.text.trim().isEmpty || widget.isLoading
                    ? null
                    : _handleSend,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
