import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/chat/models/message_model.dart';
import 'package:vibe_app/features/chat/models/private_conversation_model.dart';
import 'package:vibe_app/features/chat/services/chat_service.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';

/// Firebase implementation of ChatService
///
/// Manages real-time chat messages for event groups using Firestore.
class FirebaseChatService implements ChatService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseChatService({
    required AuthService authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MessageModel>> getEventMessages(
    String eventId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => MessageModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  @override
  Future<void> sendMessage({
    required String eventId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const ChatPermissionException('Must be logged in to send messages');
    }

    // Validate message length
    if (text.trim().isEmpty) {
      throw const MessageTooLongException('Message cannot be empty');
    }
    if (text.length > 500) {
      throw const MessageTooLongException(
        'Message cannot exceed 500 characters',
      );
    }

    try {
      // Check if user is participant of the event
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists) {
        throw const ChatNotFoundException('Event not found');
      }

      final eventData = eventDoc.data()!;
      final participantIds = List<String>.from(
        eventData['participantIds'] ?? [],
      );
      final organizerId = eventData['organizerId'] as String;

      if (!participantIds.contains(currentUser.id) &&
          organizerId != currentUser.id) {
        throw const ChatPermissionException(
          'Only event participants can send messages',
        );
      }

      // Create message with client timestamp
      // Using client timestamp instead of serverTimestamp to avoid null issues
      final now = DateTime.now();
      final messageData = {
        'senderId': currentUser.id,
        'senderName': currentUser.name,
        'senderPhotoUrl': currentUser.profilePhotoUrl,
        'text': text.trim(),
        'timestamp': Timestamp.fromDate(now),
        'isSystemMessage': false,
        'readBy': [currentUser.id], // Sender has read their own message
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      };

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add(messageData);
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException('Failed to send message: $e');
    }
  }

  @override
  Future<void> sendSystemMessage(String eventId, String text) async {
    try {
      final messageData = {
        'senderId': 'system',
        'senderName': 'System',
        'senderPhotoUrl': '',
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isSystemMessage': true,
      };

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add(messageData);
    } catch (e) {
      throw ChatException('Failed to send system message: $e');
    }
  }

  @override
  Future<List<MessageModel>> loadOlderMessages({
    required String eventId,
    required DateTime before,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .where('timestamp', isLessThan: Timestamp.fromDate(before))
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw ChatException('Failed to load older messages: $e');
    }
  }

  @override
  Future<void> markMessagesRead(String eventId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Update last read timestamp for this user in the event
      await _firestore.collection('events').doc(eventId).update({
        'lastReadBy.${currentUser.id}': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-critical error, can fail silently
    }
  }

  @override
  Future<void> leaveChat(String eventId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const ChatPermissionException('Must be logged in');
    }

    try {
      // Remove user from participants
      await _firestore.collection('events').doc(eventId).update({
        'participantIds': FieldValue.arrayRemove([currentUser.id]),
      });

      // Send system message
      await sendSystemMessage(
        eventId,
        '${currentUser.name} покинул(а) событие',
      );
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException('Failed to leave chat: $e');
    }
  }

  // ===== PRIVATE CHAT IMPLEMENTATION =====

  @override
  Stream<List<PrivateConversationModel>> getUserConversations() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUser.id)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PrivateConversationModel.fromJson(
                    {...doc.data(), 'id': doc.id},
                  ))
              .toList();
        });
  }

  @override
  Future<PrivateConversationModel> getOrCreateConversation(
    String otherUserId,
  ) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const ChatPermissionException('Must be logged in');
    }

    if (currentUser.id == otherUserId) {
      throw const ChatException('Cannot create conversation with yourself');
    }

    // Create conversation ID (sorted user IDs)
    final conversationId = PrivateConversationModel.createConversationId(
      currentUser.id,
      otherUserId,
    );

    try {
      // Check if conversation exists
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        return PrivateConversationModel.fromJson({
          ...conversationDoc.data()!,
          'id': conversationDoc.id,
        });
      }

      // Get other user's profile data
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUserDoc.exists) {
        throw const ChatNotFoundException('User not found');
      }

      final otherUserData = otherUserDoc.data()!;
      final now = DateTime.now();

      // Create new conversation
      final conversationData = {
        'participantIds': [currentUser.id, otherUserId],
        'participantData': {
          currentUser.id: {
            'name': currentUser.name,
            'photoUrl': currentUser.profilePhotoUrl,
          },
          otherUserId: {
            'name': otherUserData['name'] ?? 'Unknown',
            'photoUrl': otherUserData['profilePhotoUrl'] ?? '',
          },
        },
        'lastMessage': null,
        'lastMessageSenderId': null,
        'lastMessageTime': null,
        'unreadCounts': {
          currentUser.id: 0,
          otherUserId: 0,
        },
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set(conversationData);

      return PrivateConversationModel.fromJson({
        ...conversationData,
        'id': conversationId,
      });
    } catch (e) {
      if (e is ChatException) rethrow;
      throw ChatException('Failed to get or create conversation: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getPrivateMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  @override
  Future<void> sendPrivateMessage({
    required String conversationId,
    required String recipientId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const ChatPermissionException('Must be logged in to send messages');
    }

    // Validate message
    if (text.trim().isEmpty) {
      throw const MessageTooLongException('Message cannot be empty');
    }
    if (text.length > 500) {
      throw const MessageTooLongException(
        'Message cannot exceed 500 characters',
      );
    }

    try {
      // Verify conversation exists and user is participant
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw const ChatNotFoundException('Conversation not found');
      }

      final conversationData = conversationDoc.data()!;
      final participantIds = List<String>.from(
        conversationData['participantIds'] ?? [],
      );

      if (!participantIds.contains(currentUser.id)) {
        throw const ChatPermissionException(
          'You are not a participant of this conversation',
        );
      }

      final now = DateTime.now();

      // Create message
      final messageData = {
        'senderId': currentUser.id,
        'senderName': currentUser.name,
        'senderPhotoUrl': currentUser.profilePhotoUrl,
        'text': text.trim(),
        'timestamp': Timestamp.fromDate(now),
        'isSystemMessage': false,
        'readBy': [currentUser.id],
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      };

      // Add message to subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation metadata
      final currentUnreadCount = (conversationData['unreadCounts'] as Map?)
              ?[recipientId] as int? ??
          0;

      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': text.trim(),
        'lastMessageSenderId': currentUser.id,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCounts.$recipientId': currentUnreadCount + 1,
      });
    } on ChatException {
      rethrow;
    } catch (e) {
      throw ChatException('Failed to send private message: $e');
    }
  }

  @override
  Future<void> markPrivateMessagesRead(String conversationId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Reset unread count for current user
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCounts.${currentUser.id}': 0,
      });
    } catch (e) {
      // Non-critical, can fail silently
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const ChatPermissionException('Must be logged in');
    }

    try {
      // For now, just hide it by removing user from participants
      // This preserves messages for the other user
      await _firestore.collection('conversations').doc(conversationId).update({
        'participantIds': FieldValue.arrayRemove([currentUser.id]),
      });
    } catch (e) {
      throw ChatException('Failed to delete conversation: $e');
    }
  }
}
