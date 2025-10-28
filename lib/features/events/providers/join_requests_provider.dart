import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/join_requests_service.dart';
import '../services/firebase_join_requests_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

/// Provider for JoinRequestsService instance
///
/// Provides FirebaseJoinRequestsService for real-time join request management.
final joinRequestsServiceProvider = Provider<JoinRequestsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return FirebaseJoinRequestsService(
    authService: authService,
    notificationService: notificationService,
  );
});
