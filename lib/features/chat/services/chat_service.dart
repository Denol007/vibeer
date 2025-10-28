import 'package:vibe_app/features/chat/models/message_model.dart';
import 'package:vibe_app/features/chat/models/private_conversation_model.dart';

/// Abstract interface for chat service
abstract class ChatService {
  /// Stream of messages for event chat
  Stream<List<MessageModel>> getEventMessages(String eventId, {int limit = 50});

  /// Send text message to event chat
  Future<void> sendMessage({
    required String eventId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  });

  /// Send system message
  Future<void> sendSystemMessage(String eventId, String text);

  /// Load older messages (pagination)
  Future<List<MessageModel>> loadOlderMessages({
    required String eventId,
    required DateTime before,
    int limit = 50,
  });

  /// Mark messages as read
  Future<void> markMessagesRead(String eventId);

  /// Leave group chat
  Future<void> leaveChat(String eventId);

  // ===== PRIVATE CHAT METHODS =====

  /// Get all private conversations for current user
  Stream<List<PrivateConversationModel>> getUserConversations();

  /// Get or create private conversation with another user
  Future<PrivateConversationModel> getOrCreateConversation(String otherUserId);

  /// Stream of messages for private conversation
  Stream<List<MessageModel>> getPrivateMessages(
    String conversationId, {
    int limit = 50,
  });

  /// Send message in private conversation
  Future<void> sendPrivateMessage({
    required String conversationId,
    required String recipientId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  });

  /// Mark private messages as read
  Future<void> markPrivateMessagesRead(String conversationId);

  /// Delete conversation (for current user only)
  Future<void> deleteConversation(String conversationId);
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);
  @override
  String toString() => 'ChatException: $message';
}

class ChatPermissionException extends ChatException {
  const ChatPermissionException(super.message);
}

class ChatNotFoundException extends ChatException {
  const ChatNotFoundException(super.message);
}

class MessageTooLongException extends ChatException {
  const MessageTooLongException(super.message);
}
