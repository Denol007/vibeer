import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model for Vibe MVP
///
/// Represents a registered user with profile information.
/// All users must be 18+ and have confirmed their age.
class UserModel {
  final String id;
  final String name;
  final String email;
  final int age;
  final String profilePhotoUrl;
  final String? aboutMe;
  final String? username; // Optional unique username like @denol
  final String authProvider;
  final bool isAgeConfirmed;
  final DateTime createdAt;
  final List<String> blockedUserIds;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.profilePhotoUrl,
    this.aboutMe,
    this.username,
    required this.authProvider,
    required this.isAgeConfirmed,
    required this.createdAt,
    this.blockedUserIds = const [],
  });

  /// Creates a UserModel from JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) throw Exception('User ID is required');
    if (json['name'] == null) throw Exception('User name is required');
    if (json['email'] == null) throw Exception('User email is required');
    if (json['age'] == null) throw Exception('User age is required');
    if (json['profilePhotoUrl'] == null)
      throw Exception('Profile photo URL is required');
    if (json['authProvider'] == null)
      throw Exception('Auth provider is required');
    if (json['isAgeConfirmed'] == null)
      throw Exception('Age confirmation is required');
    if (json['createdAt'] == null) throw Exception('Created at is required');

    // Validate age
    final age = json['age'] as int;
    if (age < 18) {
      throw Exception('User must be at least 18 years old');
    }
    if (age > 25) {
      throw Exception('User must be 25 years old or younger');
    }

    // Validate email format
    final email = json['email'] as String;
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    // Validate aboutMe length if provided
    final aboutMe = json['aboutMe'] as String?;
    if (aboutMe != null && aboutMe.length > 500) {
      throw Exception('About me must be 500 characters or less');
    }

    // Validate username format if provided
    final username = json['username'] as String?;
    if (username != null && !_isValidUsername(username)) {
      throw Exception('Invalid username format: must be 3-20 lowercase alphanumeric characters or underscores');
    }

    // Validate authProvider
    final authProvider = json['authProvider'] as String;
    if (authProvider != 'google' && authProvider != 'apple') {
      throw Exception('Invalid authProvider: must be google or apple');
    }

    // Parse createdAt - handle both int (seconds) and Timestamp
    DateTime createdAt;
    if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int) * 1000,
      );
    } else if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else {
      throw Exception('Invalid createdAt format');
    }

    // Parse blockedUserIds
    final blockedUserIds =
        (json['blockedUserIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: email,
      age: age,
      profilePhotoUrl: json['profilePhotoUrl'] as String,
      aboutMe: aboutMe,
      username: username,
      authProvider: authProvider,
      isAgeConfirmed: json['isAgeConfirmed'] as bool,
      createdAt: createdAt,
      blockedUserIds: blockedUserIds,
    );
  }

  /// Converts UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'profilePhotoUrl': profilePhotoUrl,
      'authProvider': authProvider,
      'isAgeConfirmed': isAgeConfirmed,
      'createdAt':
          createdAt.millisecondsSinceEpoch ~/ 1000, // Return as seconds
      'blockedUserIds': blockedUserIds,
    };

    // Only include aboutMe if it's not null
    if (aboutMe != null) {
      json['aboutMe'] = aboutMe!;
    }

    // Only include username if it's not null
    if (username != null) {
      json['username'] = username!;
    }

    return json;
  }

  /// Creates a copy of this user with modified fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? profilePhotoUrl,
    String? aboutMe,
    String? username,
    String? authProvider,
    bool? isAgeConfirmed,
    DateTime? createdAt,
    List<String>? blockedUserIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      aboutMe: aboutMe ?? this.aboutMe,
      username: username ?? this.username,
      authProvider: authProvider ?? this.authProvider,
      isAgeConfirmed: isAgeConfirmed ?? this.isAgeConfirmed,
      createdAt: createdAt ?? this.createdAt,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }

  /// Returns display name (same as name in MVP)
  String get displayName => name;

  /// Returns user initials for avatar fallback
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Checks if user has blocked another user
  bool hasBlocked(String userId) {
    return blockedUserIds.contains(userId);
  }

  /// Checks if profile is complete (has optional aboutMe field)
  bool get isProfileComplete {
    return aboutMe != null && aboutMe!.isNotEmpty;
  }

  /// Validates email format
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates username format (like @denol)
  /// Rules: 3-20 characters, lowercase letters, numbers, underscores only
  /// Must start with a letter
  static bool _isValidUsername(String username) {
    if (username.length < 3 || username.length > 20) return false;
    final usernameRegex = RegExp(r'^[a-z][a-z0-9_]*$');
    return usernameRegex.hasMatch(username);
  }

  /// Validates username format (public method for UI)
  static bool isValidUsername(String username) {
    return _isValidUsername(username);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.aboutMe == aboutMe &&
        other.username == username &&
        other.authProvider == authProvider &&
        other.isAgeConfirmed == isAgeConfirmed &&
        other.createdAt == createdAt &&
        _listEquals(other.blockedUserIds, blockedUserIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      age,
      profilePhotoUrl,
      aboutMe,
      username,
      authProvider,
      isAgeConfirmed,
      createdAt,
      Object.hashAll(blockedUserIds),
    );
  }

  /// Helper to compare lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, age: $age, '
        'profilePhotoUrl: $profilePhotoUrl, aboutMe: $aboutMe, '
        'authProvider: $authProvider, isAgeConfirmed: $isAgeConfirmed, '
        'createdAt: $createdAt, blockedUserIds: $blockedUserIds)';
  }
}
