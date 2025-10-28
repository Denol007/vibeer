import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';
import 'package:vibe_app/features/profile/services/profile_service.dart';
import 'package:vibe_app/shared/services/storage_service.dart';

/// Firebase implementation of [ProfileService]
///
/// Manages user profiles in Firestore and profile photos in Storage.
class FirebaseProfileService implements ProfileService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final StorageService _storageService;

  FirebaseProfileService({
    required AuthService authService,
    required StorageService storageService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _storageService = storageService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel?> getProfile(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const ProfileNotFoundException('Invalid user ID');
      }

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException('Failed to get profile: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return null;
      }

      return await getProfile(currentUser.id);
    } catch (e) {
      throw ProfileException('Failed to get current user profile: $e');
    }
  }

  @override
  Future<void> createProfile({
    required String name,
    required int age,
    required File profilePhoto,
    required String aboutMe,
    required bool ageConfirmed,
  }) async {
    try {
      // Validate age confirmation
      if (!ageConfirmed) {
        throw const ProfileValidationException('Age confirmation required');
      }

      // Validate age range
      if (age < 18 || age > 25) {
        throw const ProfileValidationException('User must be 18+');
      }

      // Validate aboutMe length
      if (aboutMe.length > 500) {
        throw const ProfileValidationException('aboutMe max 500 chars');
      }

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const ProfileException('No authenticated user');
      }

      // Compress and upload profile photo
      final compressedPhoto = await _storageService.compressImage(profilePhoto);
      final photoUrl = await uploadProfilePhoto(
        currentUser.id,
        compressedPhoto,
      );

      // Update user document in Firestore
      await _firestore.collection('users').doc(currentUser.id).update({
        'name': name,
        'age': age,
        'profilePhotoUrl': photoUrl,
        'aboutMe': aboutMe,
        'isAgeConfirmed': true,
      });
    } on ProfileException {
      rethrow;
    } on StorageException catch (e) {
      throw ProfileUploadException('Failed to upload photo: ${e.message}');
    } catch (e) {
      throw ProfileException('Failed to create profile: $e');
    }
  }

  @override
  Future<void> updateProfile({
    int? age,
    File? newProfilePhoto,
    String? aboutMe,
    String? username,
  }) async {
    try {
      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const ProfileException('No authenticated user');
      }

      // Validate age if provided
      if (age != null && (age < 18 || age > 25)) {
        throw const ProfileValidationException('Age must be 18-25');
      }

      // Validate aboutMe length if provided
      if (aboutMe != null && aboutMe.length > 500) {
        throw const ProfileValidationException('aboutMe max 500 chars');
      }

      // Validate and check username availability if provided
      if (username != null) {
        if (!UserModel.isValidUsername(username)) {
          throw const ProfileValidationException(
            'Username must be 3-20 characters: lowercase letters, numbers, underscores only, must start with a letter'
          );
        }

        // Check if username is available (excluding current user)
        final isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          throw const UsernameAlreadyTakenException('Username already taken');
        }
      }

      // Build update map
      final Map<String, dynamic> updates = {};

      if (age != null) {
        updates['age'] = age;
      }

      if (aboutMe != null) {
        updates['aboutMe'] = aboutMe;
      }

      if (username != null) {
        updates['username'] = username;
      }

      if (newProfilePhoto != null) {
        // Compress and upload new photo
        final compressedPhoto = await _storageService.compressImage(
          newProfilePhoto,
        );
        final photoUrl = await uploadProfilePhoto(
          currentUser.id,
          compressedPhoto,
        );
        updates['profilePhotoUrl'] = photoUrl;

        // Optional: Delete old photo from storage
        // (skipping for now to avoid breaking existing references)
      }

      // Update Firestore document if there are changes
      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser.id)
            .update(updates);
      }
    } on ProfileException {
      rethrow;
    } on StorageException catch (e) {
      throw ProfileUploadException('Failed to upload photo: ${e.message}');
    } catch (e) {
      throw ProfileException('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfilePhoto(String userId, File photo) async {
    try {
      // Validate file exists
      if (!await photo.exists()) {
        throw const ProfileUploadException('Photo file not found');
      }

      // Validate file size (max 5MB)
      final fileSize = await photo.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw const ProfileUploadException('File exceeds 5MB limit');
      }

      // Validate file extension
      final extension = photo.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
        throw const ProfileUploadException('Invalid file type');
      }

      // Upload to Firebase Storage
      final storagePath = 'profile_photos/$userId.$extension';
      final downloadUrl = await _storageService.uploadFile(
        path: storagePath,
        file: photo,
      );

      return downloadUrl;
    } on ProfileException {
      rethrow;
    } on StorageException catch (e) {
      throw ProfileUploadException('Upload failed: ${e.message}');
    } catch (e) {
      throw ProfileUploadException('Unexpected error during upload: $e');
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final currentUser = _authService.currentUser;
      
      // Query for existing username
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      // If no documents found, username is available
      if (querySnapshot.docs.isEmpty) {
        return true;
      }

      // If found, check if it belongs to current user (allow keeping same username)
      if (currentUser != null && querySnapshot.docs.first.id == currentUser.id) {
        return true;
      }

      // Username is taken by another user
      return false;
    } catch (e) {
      throw ProfileException('Failed to check username availability: $e');
    }
  }

  @override
  Future<UserModel?> getProfileByUsername(String username) async {
    try {
      if (username.isEmpty) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw ProfileException('Failed to get profile by username: $e');
    }
  }
}
