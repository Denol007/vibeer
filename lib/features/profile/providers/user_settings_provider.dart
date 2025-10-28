import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_settings_model.dart';
import '../services/firebase_user_settings_service.dart';
import '../services/user_settings_service.dart';

/// Provider for UserSettingsService
final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  return FirebaseUserSettingsService(
    firestore: FirebaseFirestore.instance,
    authService: ref.watch(authServiceProvider),
  );
});

/// Stream provider for current user's settings
final userSettingsProvider = StreamProvider<UserSettingsModel>((ref) {
  final settingsService = ref.watch(userSettingsServiceProvider);
  return settingsService.getUserSettings();
});
