import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/events/models/join_request_model.dart';

/// Unit tests for JoinRequestModel
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T028-T032).

void main() {
  group('JoinRequestModel', () {
    // Test data
    final validRequestJson = {
      'id': 'req123',
      'eventId': 'event789',
      'requesterId': 'user456',
      'requesterName': 'Marina Petrova',
      'requesterPhotoUrl': 'https://example.com/marina.jpg',
      'requesterAge': 23,
      'requesterAboutMe': 'Love outdoor adventures!',
      'organizerId': 'user123',
      'status': 'pending',
      'createdAt': 1704067200, // 2024-01-01 00:00:00 UTC
    };

    group('fromJson', () {
      test('should parse valid JSON', () {
        final request = JoinRequestModel.fromJson(validRequestJson);

        expect(request.id, 'req123');
        expect(request.eventId, 'event789');
        expect(request.requesterId, 'user456');
        expect(request.requesterName, 'Marina Petrova');
        expect(request.requesterPhotoUrl, 'https://example.com/marina.jpg');
        expect(request.requesterAge, 23);
        expect(request.requesterAboutMe, 'Love outdoor adventures!');
        expect(request.organizerId, 'user123');
        expect(request.status, 'pending');
        expect(request.createdAt.year, 2024);
        expect(request.respondedAt, null);
      });

      test('should handle missing optional requesterAboutMe', () {
        final jsonWithoutAboutMe = Map<String, dynamic>.from(validRequestJson);
        jsonWithoutAboutMe.remove('requesterAboutMe');

        final request = JoinRequestModel.fromJson(jsonWithoutAboutMe);

        expect(request.requesterAboutMe, null);
        expect(request.requesterDisplayName, 'Marina Petrova');
      });

      test('should parse respondedAt when present', () {
        final jsonWithResponse = Map<String, dynamic>.from(validRequestJson);
        jsonWithResponse['respondedAt'] = 1704153600; // 2024-01-02 00:00:00 UTC

        final request = JoinRequestModel.fromJson(jsonWithResponse);

        expect(request.respondedAt, isNotNull);
        expect(request.respondedAt!.year, 2024);
        expect(request.respondedAt!.day, 2);
      });
    });

    group('validation', () {
      test('should validate requester is not organizer', () {
        final selfRequestJson = Map<String, dynamic>.from(validRequestJson);
        selfRequestJson['requesterId'] =
            selfRequestJson['organizerId'] as String;

        expect(
          () => JoinRequestModel.fromJson(selfRequestJson),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('organizer') &&
                  e.toString().contains('join their own event'),
            ),
          ),
        );
      });

      test('should validate requester age range', () {
        final youngUserJson = Map<String, dynamic>.from(validRequestJson);
        youngUserJson['requesterAge'] = 17;

        expect(
          () => JoinRequestModel.fromJson(youngUserJson),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('18') &&
                  e.toString().contains('25'),
            ),
          ),
        );

        final oldUserJson = Map<String, dynamic>.from(validRequestJson);
        oldUserJson['requesterAge'] = 26;

        expect(
          () => JoinRequestModel.fromJson(oldUserJson),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('18') &&
                  e.toString().contains('25'),
            ),
          ),
        );
      });

      test('should validate status is valid', () {
        final invalidStatusJson = Map<String, dynamic>.from(validRequestJson);
        invalidStatusJson['status'] = 'maybe';

        expect(
          () => JoinRequestModel.fromJson(invalidStatusJson),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('status') &&
                  e.toString().contains('pending'),
            ),
          ),
        );
      });
    });

    group('toJson', () {
      test('should convert to JSON with timestamps as seconds', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        final json = request.toJson();

        expect(json['id'], 'req123');
        expect(json['eventId'], 'event789');
        expect(json['requesterId'], 'user456');
        expect(json['requesterName'], 'Marina Petrova');
        expect(json['requesterPhotoUrl'], 'https://example.com/marina.jpg');
        expect(json['requesterAge'], 23);
        expect(json['requesterAboutMe'], 'Love outdoor adventures!');
        expect(json['organizerId'], 'user123');
        expect(json['status'], 'pending');
        expect(json['createdAt'], isA<int>());
        expect(json['respondedAt'], null);
      });

      test('should include respondedAt in JSON when present', () {
        final jsonWithResponse = Map<String, dynamic>.from(validRequestJson);
        jsonWithResponse['respondedAt'] = 1704153600;

        final request = JoinRequestModel.fromJson(jsonWithResponse);
        final json = request.toJson();

        expect(json['respondedAt'], isA<int>());
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = JoinRequestModel.fromJson(validRequestJson);
        final copied = original.copyWith(
          status: 'approved',
          respondedAt: DateTime(2024, 1, 2),
        );

        expect(copied.id, original.id);
        expect(copied.eventId, original.eventId);
        expect(copied.status, 'approved');
        expect(copied.respondedAt, isNotNull);
        expect(original.status, 'pending');
        expect(original.respondedAt, null);
      });

      test('should keep original values when null', () {
        final original = JoinRequestModel.fromJson(validRequestJson);
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.status, original.status);
        expect(copied.respondedAt, original.respondedAt);
      });
    });

    group('approve', () {
      test('should update status to approved', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        final approved = request.approve();

        expect(approved.status, 'approved');
        expect(approved.respondedAt, isNotNull);
        expect(
          approved.respondedAt!.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
          true,
        );
        expect(request.status, 'pending');
      });

      test('should throw when not pending', () {
        final approvedJson = Map<String, dynamic>.from(validRequestJson);
        approvedJson['status'] = 'approved';
        approvedJson['respondedAt'] = 1704153600;

        final request = JoinRequestModel.fromJson(approvedJson);

        expect(
          () => request.approve(),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('pending'),
            ),
          ),
        );
      });
    });

    group('decline', () {
      test('should update status to declined', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        final declined = request.decline();

        expect(declined.status, 'declined');
        expect(declined.respondedAt, isNotNull);
        expect(
          declined.respondedAt!.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
          true,
        );
        expect(request.status, 'pending');
      });

      test('should throw when not pending', () {
        final declinedJson = Map<String, dynamic>.from(validRequestJson);
        declinedJson['status'] = 'declined';
        declinedJson['respondedAt'] = 1704153600;

        final request = JoinRequestModel.fromJson(declinedJson);

        expect(
          () => request.decline(),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('pending'),
            ),
          ),
        );
      });
    });

    group('helper methods', () {
      test('should check if request has been responded', () {
        final pending = JoinRequestModel.fromJson(validRequestJson);
        expect(pending.hasBeenResponded, false);

        final approved = pending.approve();
        expect(approved.hasBeenResponded, true);

        final declined = pending.decline();
        expect(declined.hasBeenResponded, true);
      });

      test('should calculate response time', () {
        final pending = JoinRequestModel.fromJson(validRequestJson);
        expect(pending.responseTime, null);

        final jsonWithResponse = Map<String, dynamic>.from(validRequestJson);
        jsonWithResponse['status'] = 'approved';
        jsonWithResponse['respondedAt'] = 1704153600; // 24 hours later

        final approved = JoinRequestModel.fromJson(jsonWithResponse);
        expect(approved.responseTime, isNotNull);
        expect(approved.responseTime!.inHours, 24);
      });

      test('should get requester display name', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        expect(request.requesterDisplayName, 'Marina Petrova');
      });

      test('should check if request is from specific user', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        expect(request.isFromUser('user456'), true);
        expect(request.isFromUser('user789'), false);
      });

      test('should check if request is for specific event', () {
        final request = JoinRequestModel.fromJson(validRequestJson);
        expect(request.isForEvent('event789'), true);
        expect(request.isForEvent('event456'), false);
      });

      test('should check status with convenience getters', () {
        final pending = JoinRequestModel.fromJson(validRequestJson);
        expect(pending.isPending, true);
        expect(pending.isApproved, false);
        expect(pending.isDeclined, false);

        final approved = pending.approve();
        expect(approved.isPending, false);
        expect(approved.isApproved, true);
        expect(approved.isDeclined, false);

        final declined = pending.decline();
        expect(declined.isPending, false);
        expect(declined.isApproved, false);
        expect(declined.isDeclined, true);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final request1 = JoinRequestModel.fromJson(validRequestJson);
        final request2 = JoinRequestModel.fromJson(validRequestJson);

        expect(request1, equals(request2));
        expect(request1.hashCode, equals(request2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final request1 = JoinRequestModel.fromJson(validRequestJson);
        final differentJson = Map<String, dynamic>.from(validRequestJson);
        differentJson['id'] = 'req999';
        final request2 = JoinRequestModel.fromJson(differentJson);

        expect(request1, isNot(equals(request2)));
        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });
    });
  });
}
