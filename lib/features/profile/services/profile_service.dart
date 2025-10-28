import 'dart:io';

import 'package:vibe_app/features/profile/models/user_model.dart';

/// Abstract interface for profile service
///
/// Manages user profiles including creation, updates, and photo uploads.
abstract class ProfileService {
  /// Get user profile by ID
  ///
  /// Returns [UserModel] if profile exists, null otherwise.
  /// Throws [ProfileNotFoundException] if ID is invalid.
  Future<UserModel?> getProfile(String userId);

  /// Get current authenticated user's profile
  ///
  /// Returns [UserModel] if user is authenticated, null otherwise.
  Future<UserModel?> getCurrentUserProfile();

  /// Create initial profile during registration
  ///
  /// Required fields:
  /// - [name]: User's display name
  /// - [age]: User's age (18-25)
  /// - [profilePhoto]: Profile photo file
  /// - [aboutMe]: Bio/description (max 500 chars)
  /// - [ageConfirmed]: Must be true
  ///
  /// Throws [ProfileValidationException] for invalid data.
  /// Throws [ProfileUploadException] on photo upload failure.
  Future<void> createProfile({
    required String name,
    required int age,
    required File profilePhoto,
    required String aboutMe,
    required bool ageConfirmed,
  });

  /// Update existing profile
  ///
  /// All parameters are optional. Only provided fields will be updated.
  ///
  /// - [age]: New age (18-25)
  /// - [newProfilePhoto]: New profile photo file
  /// - [aboutMe]: Updated bio (max 500 chars)
  /// - [username]: Unique username (3-20 chars, lowercase, letters/numbers/underscores)
  ///
  /// Throws [ProfileValidationException] for invalid data.
  /// Throws [ProfileUploadException] on photo upload failure.
  /// Throws [UsernameAlreadyTakenException] if username is taken.
  Future<void> updateProfile({
    int? age,
    File? newProfilePhoto,
    String? aboutMe,
    String? username,
  });

  /// Check if username is available
  ///
  /// Returns true if username is not taken, false otherwise.
  /// Checks against current user's username to allow keeping the same one.
  Future<bool> isUsernameAvailable(String username);

  /// Get user profile by username
  ///
  /// Returns [UserModel] if profile exists with this username, null otherwise.
  Future<UserModel?> getProfileByUsername(String username);

  /// Upload profile photo to Firebase Storage
  ///
  /// [userId]: User ID for storage path
  /// [photo]: Photo file to upload
  ///
  /// Returns download URL of uploaded photo.
  /// Throws [ProfileUploadException] on upload failure.
  Future<String> uploadProfilePhoto(String userId, File photo);
}

/// Base profile exception
class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Profile not found
class ProfileNotFoundException extends ProfileException {
  const ProfileNotFoundException(super.message);

  @override
  String toString() => 'ProfileNotFoundException: $message';
}

/// Invalid profile data
class ProfileValidationException extends ProfileException {
  const ProfileValidationException(super.message);

  @override
  String toString() => 'ProfileValidationException: $message';
}

/// Photo upload failed
class ProfileUploadException extends ProfileException {
  const ProfileUploadException(super.message);

  @override
  String toString() => 'ProfileUploadException: $message';
}

/// Username already taken
class UsernameAlreadyTakenException extends ProfileException {
  const UsernameAlreadyTakenException(super.message);

  @override
  String toString() => 'UsernameAlreadyTakenException: $message';
}
