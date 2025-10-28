import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/events/models/join_request_model.dart';
import 'package:vibe_app/features/events/services/join_requests_service.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/notifications/services/notification_service.dart';
import 'package:vibe_app/features/notifications/models/notification_model.dart';

/// Firebase implementation of JoinRequestsService
///
/// Manages join requests for events using Firestore.
class FirebaseJoinRequestsService implements JoinRequestsService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final NotificationService _notificationService;

  FirebaseJoinRequestsService({
    required AuthService authService,
    required NotificationService notificationService,
    FirebaseFirestore? firestore,
  })  : _authService = authService,
        _notificationService = notificationService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<JoinRequestModel>> getIncomingRequests() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('joinRequests')
        .where('organizerId', isEqualTo: currentUser.id)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    JoinRequestModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  @override
  Stream<List<JoinRequestModel>> getMyRequests() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Simplified query - sort client-side to avoid index requirement
    return _firestore
        .collection('joinRequests')
        .where('requesterId', isEqualTo: currentUser.id)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) =>
                    JoinRequestModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();

          // Client-side sorting by createdAt (newest first)
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return requests;
        });
  }

  @override
  Stream<List<JoinRequestModel>> getEventRequests(String eventId) {
    // Simplified query to avoid composite index requirement
    // Filter by status and sort client-side
    return _firestore
        .collection('joinRequests')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          // Client-side filtering for pending status only
          final requests = snapshot.docs
              .map(
                (doc) =>
                    JoinRequestModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .where((request) => request.status == 'pending')
              .toList();

          // Client-side sorting by createdAt (oldest first)
          requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return requests;
        });
  }

  @override
  Future<JoinRequestModel> sendJoinRequest(String eventId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const RequestPermissionException('Must be logged in');
    }

    try {
      // Get event details
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists) {
        throw const RequestNotFoundException('Event not found');
      }

      final eventData = eventDoc.data()!;
      final organizerId = eventData['organizerId'] as String;

      // Check if user is organizer
      if (organizerId == currentUser.id) {
        throw const SelfJoinException('Cannot join your own event');
      }

      // Check for duplicate request
      final existingRequest = await _firestore
          .collection('joinRequests')
          .where('eventId', isEqualTo: eventId)
          .where('requesterId', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw const DuplicateRequestException('Request already sent');
      }

      // Create request with proper field names
      final requestData = {
        'eventId': eventId,
        'requesterId': currentUser.id,
        'requesterName': currentUser.name,
        'requesterPhotoUrl': currentUser.profilePhotoUrl,
        'requesterAge': currentUser.age,
        'requesterAboutMe': currentUser.aboutMe,
        'organizerId': organizerId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('joinRequests')
          .add(requestData);

      // Fetch the created document to get server timestamp
      final createdDoc = await docRef.get();

      if (!createdDoc.exists || createdDoc.data() == null) {
        throw const JoinRequestException('Failed to create join request');
      }

      final joinRequest = JoinRequestModel.fromJson({
        ...createdDoc.data()!,
        'id': createdDoc.id,
      });

      // Create notification for organizer
      try {
        final eventTitle = eventData['title'] as String? ?? 'событие';
        await _notificationService.createNotification(
          userId: organizerId,
          type: NotificationType.joinRequest,
          title: 'Новый запрос на присоединение',
          message: '${currentUser.name} хочет присоединиться к "$eventTitle"',
          eventId: eventId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderPhotoUrl: currentUser.profilePhotoUrl,
        );
      } catch (e) {
        // Don't fail the join request if notification fails
        // Log error but continue
      }

      return joinRequest;
    } on JoinRequestException {
      rethrow;
    } catch (e) {
      throw JoinRequestException('Failed to send join request: $e');
    }
  }

  @override
  Future<void> approveRequest(String requestId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const RequestPermissionException('Must be logged in');
    }

    try {
      final requestDoc = await _firestore
          .collection('joinRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw const RequestNotFoundException('Request not found');
      }

      final requestData = requestDoc.data()!;
      final organizerId = requestData['organizerId'] as String;
      final eventId = requestData['eventId'] as String;
      // Fix: Use 'requesterId' instead of 'userId' to match sendJoinRequest
      final requesterId = requestData['requesterId'] as String;

      // Check if current user is organizer
      if (organizerId != currentUser.id) {
        throw const RequestPermissionException('Only organizer can approve');
      }

      // Get event details for notification
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      final eventTitle = eventDoc.data()?['title'] as String? ?? 'событие';

      // Update request status
      await _firestore.collection('joinRequests').doc(requestId).update({
        'status': 'approved',
      });

      // Add user to event participants and increment counter
      await _firestore.collection('events').doc(eventId).update({
        'participantIds': FieldValue.arrayUnion([requesterId]),
        'currentParticipants': FieldValue.increment(1),
      });

      // Create notification for requester
      try {
        await _notificationService.createNotification(
          userId: requesterId,
          type: NotificationType.joinApproved,
          title: 'Запрос одобрен!',
          message: 'Ваш запрос на участие в "$eventTitle" был одобрен',
          eventId: eventId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderPhotoUrl: currentUser.profilePhotoUrl,
        );
      } catch (e) {
        // Don't fail the approval if notification fails
      }
    } on JoinRequestException {
      rethrow;
    } catch (e) {
      throw JoinRequestException('Failed to approve request: $e');
    }
  }

  @override
  Future<void> declineRequest(String requestId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const RequestPermissionException('Must be logged in');
    }

    try {
      final requestDoc = await _firestore
          .collection('joinRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw const RequestNotFoundException('Request not found');
      }

      final requestData = requestDoc.data()!;
      final organizerId = requestData['organizerId'] as String;
      final eventId = requestData['eventId'] as String;
      final requesterId = requestData['requesterId'] as String;

      // Check if current user is organizer
      if (organizerId != currentUser.id) {
        throw const RequestPermissionException('Only organizer can decline');
      }

      // Get event details for notification
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      final eventTitle = eventDoc.data()?['title'] as String? ?? 'событие';

      // Update request status
      await _firestore.collection('joinRequests').doc(requestId).update({
        'status': 'declined',
      });

      // Create notification for requester
      try {
        await _notificationService.createNotification(
          userId: requesterId,
          type: NotificationType.joinRejected,
          title: 'Запрос отклонён',
          message: 'Ваш запрос на участие в "$eventTitle" был отклонён',
          eventId: eventId,
          senderId: currentUser.id,
          senderName: currentUser.name,
          senderPhotoUrl: currentUser.profilePhotoUrl,
        );
      } catch (e) {
        // Don't fail the decline if notification fails
      }
    } on JoinRequestException {
      rethrow;
    } catch (e) {
      throw JoinRequestException('Failed to decline request: $e');
    }
  }

  @override
  Future<void> autoDeclinePendingRequests(String eventId) async {
    try {
      final pendingRequests = await _firestore
          .collection('joinRequests')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Batch update all pending requests to declined
      final batch = _firestore.batch();
      for (final doc in pendingRequests.docs) {
        batch.update(doc.reference, {'status': 'declined'});
      }
      await batch.commit();
    } catch (e) {
      throw JoinRequestException('Failed to auto-decline requests: $e');
    }
  }
}
