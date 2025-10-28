import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/firebase_storage_service.dart';

/// Provider for StorageService instance
///
/// Creates and provides a singleton instance of [FirebaseStorageService]
/// for dependency injection throughout the app.
final storageServiceProvider = Provider<StorageService>((ref) {
  return FirebaseStorageService();
});
