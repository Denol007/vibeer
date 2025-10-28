import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/notifications/models/notification_model.dart';
import 'package:vibe_app/features/notifications/services/notification_service.dart';

/// Firebase implementation of NotificationService
///
/// Stores notifications in Firestore under /notifications collection
/// Indexed by userId for efficient queries
class FirebaseNotificationService implements NotificationService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseNotificationService({
    required AuthService authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<NotificationModel>> getUserNotifications() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.id)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent 50 notifications
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<int> getUnreadCount() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.id)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    final unreadNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.id)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? eventId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    final notification = NotificationModel(
      id: '', // Will be set by Firestore
      userId: userId,
      type: type,
      title: title,
      message: message,
      eventId: eventId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('notifications').add(notification.toJson());
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  @override
  Future<void> deleteAllRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    final readNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.id)
        .where('isRead', isEqualTo: true)
        .get();

    for (final doc in readNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
