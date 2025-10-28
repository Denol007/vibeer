/// User Settings Model
///
/// Stores user preferences and settings
class UserSettingsModel {
  final bool pushNotificationsEnabled;
  final bool chatNotificationsEnabled;
  final bool joinRequestNotificationsEnabled;

  const UserSettingsModel({
    required this.pushNotificationsEnabled,
    required this.chatNotificationsEnabled,
    required this.joinRequestNotificationsEnabled,
  });

  /// Default settings with all notifications enabled
  factory UserSettingsModel.defaults() {
    return const UserSettingsModel(
      pushNotificationsEnabled: true,
      chatNotificationsEnabled: true,
      joinRequestNotificationsEnabled: true,
    );
  }

  /// Create from Firestore map
  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      chatNotificationsEnabled: json['chatNotificationsEnabled'] as bool? ?? true,
      joinRequestNotificationsEnabled:
          json['joinRequestNotificationsEnabled'] as bool? ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'chatNotificationsEnabled': chatNotificationsEnabled,
      'joinRequestNotificationsEnabled': joinRequestNotificationsEnabled,
    };
  }

  /// Create copy with updated fields
  UserSettingsModel copyWith({
    bool? pushNotificationsEnabled,
    bool? chatNotificationsEnabled,
    bool? joinRequestNotificationsEnabled,
  }) {
    return UserSettingsModel(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      chatNotificationsEnabled:
          chatNotificationsEnabled ?? this.chatNotificationsEnabled,
      joinRequestNotificationsEnabled: joinRequestNotificationsEnabled ??
          this.joinRequestNotificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettingsModel &&
        other.pushNotificationsEnabled == pushNotificationsEnabled &&
        other.chatNotificationsEnabled == chatNotificationsEnabled &&
        other.joinRequestNotificationsEnabled ==
            joinRequestNotificationsEnabled;
  }

  @override
  int get hashCode {
    return pushNotificationsEnabled.hashCode ^
        chatNotificationsEnabled.hashCode ^
        joinRequestNotificationsEnabled.hashCode;
  }
}
