import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_service.dart';
import '../models/user_settings_model.dart';
import 'user_settings_service.dart';

/// Firebase implementation of UserSettingsService
class FirebaseUserSettingsService implements UserSettingsService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseUserSettingsService({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _firestore = firestore,
        _authService = authService;

  /// Get reference to user's settings document in separate collection
  DocumentReference<Map<String, dynamic>> get _settingsDoc {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to access settings');
    }
    return _firestore.collection('userSettings').doc(currentUser.id);
  }

  @override
  Stream<UserSettingsModel> getUserSettings() {
    return _settingsDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return UserSettingsModel.defaults();
      }

      final data = snapshot.data();
      if (data == null) {
        return UserSettingsModel.defaults();
      }

      return UserSettingsModel.fromJson(data);
    });
  }

  @override
  Future<void> updatePushNotifications(bool enabled) async {
    await _ensureSettingsExist();
    await _settingsDoc.update({
      'pushNotificationsEnabled': enabled,
    });
  }

  @override
  Future<void> updateChatNotifications(bool enabled) async {
    await _ensureSettingsExist();
    await _settingsDoc.update({
      'chatNotificationsEnabled': enabled,
    });
  }

  @override
  Future<void> updateJoinRequestNotifications(bool enabled) async {
    await _ensureSettingsExist();
    await _settingsDoc.update({
      'joinRequestNotificationsEnabled': enabled,
    });
  }

  /// Ensure settings document exists before updating
  Future<void> _ensureSettingsExist() async {
    final snapshot = await _settingsDoc.get();
    if (!snapshot.exists) {
      await _settingsDoc.set(UserSettingsModel.defaults().toJson());
    }
  }

  @override
  Future<void> updateSettings(UserSettingsModel settings) async {
    await _settingsDoc.set(
      settings.toJson(),
      SetOptions(merge: true),
    );
  }
}
