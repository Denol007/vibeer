import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../services/firebase_profile_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/providers/storage_provider.dart';

/// Provider for ProfileService instance
///
/// Creates and provides a singleton instance of [FirebaseProfileService]
/// for dependency injection throughout the app.
final profileServiceProvider = Provider<ProfileService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return FirebaseProfileService(
    authService: authService,
    storageService: storageService,
  );
});
