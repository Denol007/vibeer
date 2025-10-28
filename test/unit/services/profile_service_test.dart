import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vibe_app/features/profile/services/profile_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

import 'profile_service_test.mocks.dart';

/// Unit tests for ProfileService interface
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T033-T041).
@GenerateMocks([ProfileService])
void main() {
  group('ProfileService Contract', () {
    late ProfileService mockProfileService;

    setUp(() {
      mockProfileService = MockProfileService();
    });

    group('getProfile', () {
      test('should return user profile by ID', () async {
        final testProfile = UserModel(
          id: 'user123',
          name: 'Marina Petrova',
          email: 'marina@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://storage.googleapis.com/photo.jpg',
          aboutMe: 'Love board games!',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockProfileService.getProfile('user123'),
        ).thenAnswer((_) async => testProfile);

        final result = await mockProfileService.getProfile('user123');

        expect(result, isNotNull);
        expect(result?.id, 'user123');
        expect(result?.name, 'Marina Petrova');
      });

      test('should return null for non-existent user', () async {
        when(
          mockProfileService.getProfile('nonexistent'),
        ).thenAnswer((_) async => null);

        final result = await mockProfileService.getProfile('nonexistent');

        expect(result, isNull);
      });

      test('should throw ProfileNotFoundException for invalid ID', () async {
        when(
          mockProfileService.getProfile('invalid'),
        ).thenThrow(ProfileNotFoundException('Profile not found'));

        expect(
          () => mockProfileService.getProfile('invalid'),
          throwsA(isA<ProfileNotFoundException>()),
        );
      });
    });

    group('getCurrentUserProfile', () {
      test('should return current authenticated user profile', () async {
        final testProfile = UserModel(
          id: 'currentUser',
          name: 'Current User',
          email: 'current@gmail.com',
          age: 24,
          profilePhotoUrl: 'https://storage.googleapis.com/photo.jpg',
          authProvider: 'apple',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockProfileService.getCurrentUserProfile(),
        ).thenAnswer((_) async => testProfile);

        final result = await mockProfileService.getCurrentUserProfile();

        expect(result, isNotNull);
        expect(result?.id, 'currentUser');
      });

      test('should return null when no user is authenticated', () async {
        when(
          mockProfileService.getCurrentUserProfile(),
        ).thenAnswer((_) async => null);

        final result = await mockProfileService.getCurrentUserProfile();

        expect(result, isNull);
      });
    });

    group('createProfile', () {
      test('should create profile with all required fields', () async {
        final photoFile = File('/path/to/photo.jpg');

        when(
          mockProfileService.createProfile(
            name: 'New User',
            age: 20,
            profilePhoto: photoFile,
            aboutMe: 'Hello!',
            ageConfirmed: true,
          ),
        ).thenAnswer((_) async => {});

        await mockProfileService.createProfile(
          name: 'New User',
          age: 20,
          profilePhoto: photoFile,
          aboutMe: 'Hello!',
          ageConfirmed: true,
        );

        verify(
          mockProfileService.createProfile(
            name: 'New User',
            age: 20,
            profilePhoto: photoFile,
            aboutMe: 'Hello!',
            ageConfirmed: true,
          ),
        ).called(1);
      });

      test(
        'should throw ProfileValidationException for underage user',
        () async {
          final photoFile = File('/path/to/photo.jpg');

          when(
            mockProfileService.createProfile(
              name: 'Underage',
              age: 17,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: true,
            ),
          ).thenThrow(ProfileValidationException('User must be 18+'));

          expect(
            () => mockProfileService.createProfile(
              name: 'Underage',
              age: 17,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: true,
            ),
            throwsA(isA<ProfileValidationException>()),
          );
        },
      );

      test(
        'should throw ProfileValidationException when age not confirmed',
        () async {
          final photoFile = File('/path/to/photo.jpg');

          when(
            mockProfileService.createProfile(
              name: 'User',
              age: 20,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: false,
            ),
          ).thenThrow(ProfileValidationException('Age confirmation required'));

          expect(
            () => mockProfileService.createProfile(
              name: 'User',
              age: 20,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: false,
            ),
            throwsA(isA<ProfileValidationException>()),
          );
        },
      );

      test(
        'should throw ProfileUploadException on photo upload failure',
        () async {
          final photoFile = File('/path/to/photo.jpg');

          when(
            mockProfileService.createProfile(
              name: 'User',
              age: 20,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: true,
            ),
          ).thenThrow(ProfileUploadException('Failed to upload photo'));

          expect(
            () => mockProfileService.createProfile(
              name: 'User',
              age: 20,
              profilePhoto: photoFile,
              aboutMe: 'Test',
              ageConfirmed: true,
            ),
            throwsA(isA<ProfileUploadException>()),
          );
        },
      );
    });

    group('updateProfile', () {
      test('should update profile with new age', () async {
        when(
          mockProfileService.updateProfile(age: 23),
        ).thenAnswer((_) async => {});

        await mockProfileService.updateProfile(age: 23);

        verify(mockProfileService.updateProfile(age: 23)).called(1);
      });

      test('should update profile with new photo', () async {
        final newPhoto = File('/path/to/new_photo.jpg');

        when(
          mockProfileService.updateProfile(newProfilePhoto: newPhoto),
        ).thenAnswer((_) async => {});

        await mockProfileService.updateProfile(newProfilePhoto: newPhoto);

        verify(
          mockProfileService.updateProfile(newProfilePhoto: newPhoto),
        ).called(1);
      });

      test('should update profile with new aboutMe', () async {
        when(
          mockProfileService.updateProfile(aboutMe: 'Updated bio'),
        ).thenAnswer((_) async => {});

        await mockProfileService.updateProfile(aboutMe: 'Updated bio');

        verify(
          mockProfileService.updateProfile(aboutMe: 'Updated bio'),
        ).called(1);
      });

      test('should throw ProfileValidationException for invalid age', () async {
        when(
          mockProfileService.updateProfile(age: 17),
        ).thenThrow(ProfileValidationException('Age must be 18-25'));

        expect(
          () => mockProfileService.updateProfile(age: 17),
          throwsA(isA<ProfileValidationException>()),
        );
      });

      test(
        'should throw ProfileValidationException for aboutMe too long',
        () async {
          final longBio = 'a' * 501;
          when(
            mockProfileService.updateProfile(aboutMe: longBio),
          ).thenThrow(ProfileValidationException('aboutMe max 500 chars'));

          expect(
            () => mockProfileService.updateProfile(aboutMe: longBio),
            throwsA(isA<ProfileValidationException>()),
          );
        },
      );
    });

    group('uploadProfilePhoto', () {
      test('should upload photo and return download URL', () async {
        final photoFile = File('/path/to/photo.jpg');
        const downloadUrl =
            'https://storage.googleapis.com/vibe-app/user123.jpg';

        when(
          mockProfileService.uploadProfilePhoto('user123', photoFile),
        ).thenAnswer((_) async => downloadUrl);

        final result = await mockProfileService.uploadProfilePhoto(
          'user123',
          photoFile,
        );

        expect(result, downloadUrl);
        expect(result, contains('storage.googleapis.com'));
      });

      test('should throw ProfileUploadException on upload failure', () async {
        final photoFile = File('/path/to/photo.jpg');

        when(
          mockProfileService.uploadProfilePhoto('user123', photoFile),
        ).thenThrow(ProfileUploadException('Upload failed'));

        expect(
          () => mockProfileService.uploadProfilePhoto('user123', photoFile),
          throwsA(isA<ProfileUploadException>()),
        );
      });

      test(
        'should throw ProfileUploadException for invalid file type',
        () async {
          final invalidFile = File('/path/to/document.pdf');

          when(
            mockProfileService.uploadProfilePhoto('user123', invalidFile),
          ).thenThrow(ProfileUploadException('Invalid file type'));

          expect(
            () => mockProfileService.uploadProfilePhoto('user123', invalidFile),
            throwsA(isA<ProfileUploadException>()),
          );
        },
      );

      test('should throw ProfileUploadException for file too large', () async {
        final largeFile = File('/path/to/large_photo.jpg');

        when(
          mockProfileService.uploadProfilePhoto('user123', largeFile),
        ).thenThrow(ProfileUploadException('File exceeds 5MB limit'));

        expect(
          () => mockProfileService.uploadProfilePhoto('user123', largeFile),
          throwsA(isA<ProfileUploadException>()),
        );
      });
    });
  });
}

/// Custom exception classes for testing
class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';
}

class ProfileNotFoundException extends ProfileException {
  ProfileNotFoundException(super.message);

  @override
  String toString() => 'ProfileNotFoundException: $message';
}

class ProfileValidationException extends ProfileException {
  ProfileValidationException(super.message);

  @override
  String toString() => 'ProfileValidationException: $message';
}

class ProfileUploadException extends ProfileException {
  ProfileUploadException(super.message);

  @override
  String toString() => 'ProfileUploadException: $message';
}
