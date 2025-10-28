import '../models/user_settings_model.dart';

/// Abstract service for managing user settings
abstract class UserSettingsService {
  /// Get current user's settings
  Stream<UserSettingsModel> getUserSettings();

  /// Update push notifications setting
  Future<void> updatePushNotifications(bool enabled);

  /// Update chat notifications setting
  Future<void> updateChatNotifications(bool enabled);

  /// Update join request notifications setting
  Future<void> updateJoinRequestNotifications(bool enabled);

  /// Update multiple settings at once
  Future<void> updateSettings(UserSettingsModel settings);
}
