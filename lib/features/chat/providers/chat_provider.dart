import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../services/firebase_chat_service.dart';
import '../models/message_model.dart';
import '../models/private_conversation_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for ChatService instance
///
/// Provides Firebase-based real-time chat functionality.
final chatServiceProvider = Provider<ChatService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseChatService(authService: authService);
});

/// Stream provider for user's private conversations
final userConversationsStreamProvider =
    StreamProvider<List<PrivateConversationModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserConversations();
});

/// Stream provider for private messages in a conversation
final privateMessagesStreamProvider = StreamProvider.family<
    List<MessageModel>,
    String
>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getPrivateMessages(conversationId);
});

