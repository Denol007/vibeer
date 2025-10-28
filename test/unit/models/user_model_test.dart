import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Unit tests for UserModel
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T028-T032).
void main() {
  group('UserModel', () {
    // Test data
    final validUserJson = {
      'id': 'user123',
      'name': 'Marina Petrova',
      'email': 'marina@example.com',
      'age': 22,
      'profilePhotoUrl':
          'https://storage.googleapis.com/vibe-app/profile_photos/user123.jpg',
      'aboutMe': 'Love board games and meeting new people!',
      'authProvider': 'google',
      'isAgeConfirmed': true,
      'createdAt': 1728000000,
      'blockedUserIds': ['user456', 'user789'],
    };

    group('fromJson', () {
      test('should create UserModel from valid JSON', () {
        final user = UserModel.fromJson(validUserJson);

        expect(user.id, 'user123');
        expect(user.name, 'Marina Petrova');
        expect(user.email, 'marina@example.com');
        expect(user.age, 22);
        expect(user.profilePhotoUrl, validUserJson['profilePhotoUrl']);
        expect(user.aboutMe, 'Love board games and meeting new people!');
        expect(user.authProvider, 'google');
        expect(user.isAgeConfirmed, true);
        expect(user.createdAt, isNotNull);
        expect(user.blockedUserIds, ['user456', 'user789']);
      });

      test('should handle missing optional fields', () {
        final jsonWithoutOptional = {
          'id': 'user123',
          'name': 'Marina Petrova',
          'email': 'marina@example.com',
          'age': 22,
          'profilePhotoUrl': 'https://example.com/photo.jpg',
          'authProvider': 'google',
          'isAgeConfirmed': true,
          'createdAt': 1728000000,
        };

        final user = UserModel.fromJson(jsonWithoutOptional);

        expect(user.aboutMe, isNull);
        expect(user.blockedUserIds, isEmpty);
      });

      test('should throw when required field is missing', () {
        final invalidJson = {...validUserJson};
        invalidJson.remove('name');

        expect(
          () => UserModel.fromJson(invalidJson),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty blockedUserIds array', () {
        final jsonWithEmptyBlocked = {...validUserJson, 'blockedUserIds': []};
        final user = UserModel.fromJson(jsonWithEmptyBlocked);

        expect(user.blockedUserIds, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert UserModel to JSON', () {
        final user = UserModel.fromJson(validUserJson);
        final json = user.toJson();

        expect(json['id'], 'user123');
        expect(json['name'], 'Marina Petrova');
        expect(json['email'], 'marina@example.com');
        expect(json['age'], 22);
        expect(json['authProvider'], 'google');
        expect(json['isAgeConfirmed'], true);
        expect(json['blockedUserIds'], ['user456', 'user789']);
      });

      test('should handle null aboutMe in JSON conversion', () {
        final jsonWithoutAboutMe = {...validUserJson};
        jsonWithoutAboutMe.remove('aboutMe');
        final user = UserModel.fromJson(jsonWithoutAboutMe);
        final json = user.toJson();

        expect(json.containsKey('aboutMe'), false);
      });

      test('should include createdAt as timestamp', () {
        final user = UserModel.fromJson(validUserJson);
        final json = user.toJson();

        expect(json['createdAt'], isNotNull);
        expect(json['createdAt'], isA<int>());
      });
    });

    group('validation', () {
      test('should validate minimum age (18+)', () {
        final underageJson = {...validUserJson, 'age': 17};

        expect(
          () => UserModel.fromJson(underageJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('age') || e.toString().contains('18'),
            ),
          ),
        );
      });

      test('should validate maximum age (25)', () {
        final overageJson = {...validUserJson, 'age': 26};

        expect(
          () => UserModel.fromJson(overageJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('age') || e.toString().contains('25'),
            ),
          ),
        );
      });

      test('should accept valid age range (18-25)', () {
        final validAges = [18, 22, 25];

        for (final age in validAges) {
          final json = {...validUserJson, 'age': age};
          final user = UserModel.fromJson(json);
          expect(user.age, age);
        }
      });

      test('should validate isAgeConfirmed is true', () {
        final unconfirmedJson = {...validUserJson, 'isAgeConfirmed': false};

        expect(
          () => UserModel.fromJson(unconfirmedJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('age') ||
                  e.toString().contains('confirmed'),
            ),
          ),
        );
      });

      test('should validate email format', () {
        final invalidEmailJson = {...validUserJson, 'email': 'invalid-email'};

        expect(
          () => UserModel.fromJson(invalidEmailJson),
          throwsA(predicate((e) => e.toString().contains('email'))),
        );
      });

      test('should validate aboutMe length (max 500 chars)', () {
        final longAboutMe = 'a' * 501;
        final invalidJson = {...validUserJson, 'aboutMe': longAboutMe};

        expect(
          () => UserModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('aboutMe') ||
                  e.toString().contains('500'),
            ),
          ),
        );
      });

      test('should validate authProvider is valid', () {
        final invalidProviderJson = {
          ...validUserJson,
          'authProvider': 'facebook',
        };

        expect(
          () => UserModel.fromJson(invalidProviderJson),
          throwsA(predicate((e) => e.toString().contains('authProvider'))),
        );
      });

      test('should accept valid authProviders', () {
        final validProviders = ['google', 'apple'];

        for (final provider in validProviders) {
          final json = {...validUserJson, 'authProvider': provider};
          final user = UserModel.fromJson(json);
          expect(user.authProvider, provider);
        }
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final user1 = UserModel.fromJson(validUserJson);
        final user2 = UserModel.fromJson(validUserJson);

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when id differs', () {
        final user1 = UserModel.fromJson(validUserJson);
        final json2 = {...validUserJson, 'id': 'different-id'};
        final user2 = UserModel.fromJson(json2);

        expect(user1, isNot(equals(user2)));
      });

      test('should not be equal when name differs', () {
        final user1 = UserModel.fromJson(validUserJson);
        final json2 = {...validUserJson, 'name': 'Different Name'};
        final user2 = UserModel.fromJson(json2);

        expect(user1, isNot(equals(user2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final user = UserModel.fromJson(validUserJson);
        final updated = user.copyWith(
          name: 'Updated Name',
          aboutMe: 'Updated bio',
        );

        expect(updated.id, user.id);
        expect(updated.name, 'Updated Name');
        expect(updated.aboutMe, 'Updated bio');
        expect(updated.email, user.email);
        expect(updated.age, user.age);
      });

      test('should not modify original when using copyWith', () {
        final user = UserModel.fromJson(validUserJson);
        final originalName = user.name;

        user.copyWith(name: 'New Name');

        expect(user.name, originalName);
      });
    });

    group('helper methods', () {
      test('should check if user has blocked another user', () {
        final user = UserModel.fromJson(validUserJson);

        expect(user.hasBlocked('user456'), true);
        expect(user.hasBlocked('user789'), true);
        expect(user.hasBlocked('user999'), false);
      });

      test('should check if profile is complete', () {
        final completeUser = UserModel.fromJson(validUserJson);
        expect(completeUser.isProfileComplete, true);

        final incompleteJson = {...validUserJson};
        incompleteJson.remove('aboutMe');
        final incompleteUser = UserModel.fromJson(incompleteJson);
        expect(incompleteUser.isProfileComplete, false);
      });

      test('should format display name properly', () {
        final user = UserModel.fromJson(validUserJson);

        expect(user.displayName, isNotEmpty);
        expect(user.displayName, user.name);
      });
    });
  });
}
