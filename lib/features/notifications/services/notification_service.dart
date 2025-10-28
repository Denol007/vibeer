import '../models/notification_model.dart';

/// Service for managing user notifications
abstract class NotificationService {
  /// Get stream of notifications for current user
  Stream<List<NotificationModel>> getUserNotifications();

  /// Get count of unread notifications
  Stream<int> getUnreadCount();

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? eventId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
  });

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Delete all read notifications
  Future<void> deleteAllRead();
}
