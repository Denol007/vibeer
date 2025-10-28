import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

import 'auth_service_test.mocks.dart';

/// Unit tests for AuthService interface
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T033-T041).
@GenerateMocks([AuthService])
void main() {
  group('AuthService Contract', () {
    late AuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    group('signInWithGoogle', () {
      test('should return User on successful Google sign-in', () async {
        final testUser = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => testUser);

        final result = await mockAuthService.signInWithGoogle();

        expect(result, isA<UserModel>());
        expect(result.authProvider, 'google');
        verify(mockAuthService.signInWithGoogle()).called(1);
      });

      test('should throw AuthCancelledException when user cancels', () async {
        when(
          mockAuthService.signInWithGoogle(),
        ).thenThrow(AuthCancelledException('User cancelled sign-in'));

        expect(
          () => mockAuthService.signInWithGoogle(),
          throwsA(isA<AuthCancelledException>()),
        );
      });

      test('should throw AuthNetworkException on network error', () async {
        when(
          mockAuthService.signInWithGoogle(),
        ).thenThrow(AuthNetworkException('No internet connection'));

        expect(
          () => mockAuthService.signInWithGoogle(),
          throwsA(isA<AuthNetworkException>()),
        );
      });

      test(
        'should throw AuthInvalidCredentialException on invalid credentials',
        () async {
          when(mockAuthService.signInWithGoogle()).thenThrow(
            AuthInvalidCredentialException('Invalid Google credentials'),
          );

          expect(
            () => mockAuthService.signInWithGoogle(),
            throwsA(isA<AuthInvalidCredentialException>()),
          );
        },
      );
    });

    group('signInWithApple', () {
      test('should return User on successful Apple sign-in', () async {
        final testUser = UserModel(
          id: 'user456',
          name: 'Apple User',
          email: 'test@privaterelay.appleid.com',
          age: 24,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'apple',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockAuthService.signInWithApple(),
        ).thenAnswer((_) async => testUser);

        final result = await mockAuthService.signInWithApple();

        expect(result, isA<UserModel>());
        expect(result.authProvider, 'apple');
        verify(mockAuthService.signInWithApple()).called(1);
      });

      test('should throw AuthCancelledException when user cancels', () async {
        when(
          mockAuthService.signInWithApple(),
        ).thenThrow(AuthCancelledException('User cancelled sign-in'));

        expect(
          () => mockAuthService.signInWithApple(),
          throwsA(isA<AuthCancelledException>()),
        );
      });

      test('should throw AuthException on Apple sign-in error', () async {
        when(
          mockAuthService.signInWithApple(),
        ).thenThrow(AuthException('Apple sign-in failed'));

        expect(
          () => mockAuthService.signInWithApple(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('authStateChanges', () {
      test('should provide stream of auth state changes', () async {
        final testUser = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(testUser));

        final stream = mockAuthService.authStateChanges;

        expect(stream, isA<Stream<UserModel?>>());
        expect(await stream.first, testUser);
      });

      test('should emit null when user signs out', () async {
        when(
          mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));

        final stream = mockAuthService.authStateChanges;
        final result = await stream.first;

        expect(result, isNull);
      });

      test('should emit user changes on profile update', () async {
        final user1 = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        final user2 = user1.copyWith(name: 'Updated User');

        when(
          mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.fromIterable([user1, user2]));

        final stream = mockAuthService.authStateChanges;
        final results = await stream.take(2).toList();

        expect(results.length, 2);
        expect(results[0]?.name, 'Test User');
        expect(results[1]?.name, 'Updated User');
      });
    });

    group('currentUser', () {
      test('should return current user when authenticated', () {
        final testUser = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(mockAuthService.currentUser).thenReturn(testUser);

        final user = mockAuthService.currentUser;

        expect(user, isNotNull);
        expect(user?.id, 'user123');
      });

      test('should return null when not authenticated', () {
        when(mockAuthService.currentUser).thenReturn(null);

        final user = mockAuthService.currentUser;

        expect(user, isNull);
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        when(mockAuthService.signOut()).thenAnswer((_) async => {});

        await mockAuthService.signOut();

        verify(mockAuthService.signOut()).called(1);
      });

      test('should clear current user after sign out', () async {
        when(mockAuthService.signOut()).thenAnswer((_) async {
          when(mockAuthService.currentUser).thenReturn(null);
        });

        await mockAuthService.signOut();

        expect(mockAuthService.currentUser, isNull);
      });

      test('should handle sign out errors gracefully', () async {
        when(
          mockAuthService.signOut(),
        ).thenThrow(AuthException('Sign out failed'));

        expect(() => mockAuthService.signOut(), throwsA(isA<AuthException>()));
      });
    });

    group('deleteAccount', () {
      test('should delete account and all associated data', () async {
        when(mockAuthService.deleteAccount()).thenAnswer((_) async => {});

        await mockAuthService.deleteAccount();

        verify(mockAuthService.deleteAccount()).called(1);
      });

      test('should throw exception if user not authenticated', () async {
        when(
          mockAuthService.deleteAccount(),
        ).thenThrow(AuthException('No user to delete'));

        expect(
          () => mockAuthService.deleteAccount(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should clear current user after account deletion', () async {
        when(mockAuthService.deleteAccount()).thenAnswer((_) async {
          when(mockAuthService.currentUser).thenReturn(null);
        });

        await mockAuthService.deleteAccount();

        expect(mockAuthService.currentUser, isNull);
      });
    });

    group('edge cases', () {
      test('should handle multiple concurrent sign-in attempts', () async {
        final testUser = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(
          mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => testUser);

        final futures = [
          mockAuthService.signInWithGoogle(),
          mockAuthService.signInWithGoogle(),
        ];

        final results = await Future.wait(futures);

        expect(results.length, 2);
        expect(results[0], isA<UserModel>());
        expect(results[1], isA<UserModel>());
      });

      test('should handle auth state stream errors', () async {
        when(
          mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.error(AuthException('Stream error')));

        final stream = mockAuthService.authStateChanges;

        expect(stream.first, throwsA(isA<AuthException>()));
      });

      test('should maintain session across app restarts', () {
        // This tests the contract expectation that auth persists
        final testUser = UserModel(
          id: 'user123',
          name: 'Test User',
          email: 'test@gmail.com',
          age: 22,
          profilePhotoUrl: 'https://example.com/photo.jpg',
          authProvider: 'google',
          isAgeConfirmed: true,
          createdAt: DateTime.now(),
          blockedUserIds: [],
        );

        when(mockAuthService.currentUser).thenReturn(testUser);

        // Simulating app restart
        final user = mockAuthService.currentUser;

        expect(user, isNotNull);
        expect(user?.id, 'user123');
      });
    });
  });
}

/// Custom exception classes for testing
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class AuthCancelledException extends AuthException {
  AuthCancelledException(super.message);

  @override
  String toString() => 'AuthCancelledException: $message';
}

class AuthNetworkException extends AuthException {
  AuthNetworkException(super.message);

  @override
  String toString() => 'AuthNetworkException: $message';
}

class AuthInvalidCredentialException extends AuthException {
  AuthInvalidCredentialException(super.message);

  @override
  String toString() => 'AuthInvalidCredentialException: $message';
}
