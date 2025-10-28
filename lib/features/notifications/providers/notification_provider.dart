import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/auth/providers/auth_provider.dart';
import 'package:vibe_app/features/notifications/models/notification_model.dart';
import 'package:vibe_app/features/notifications/services/firebase_notification_service.dart';
import 'package:vibe_app/features/notifications/services/notification_service.dart';

/// Provider for NotificationService instance
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseNotificationService(authService: authService);
});

/// Provider for user notifications stream
final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUserNotifications();
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUnreadCount();
});
