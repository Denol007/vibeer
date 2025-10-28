import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/safety_service.dart';
import '../services/firebase_safety_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for SafetyService instance
///
/// Provides FirebaseSafetyService for user blocking and reporting functionality.
final safetyServiceProvider = Provider<SafetyService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseSafetyService(authService: authService);
});
