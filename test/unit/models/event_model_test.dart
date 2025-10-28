import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/events/models/event_model.dart';

/// Unit tests for EventModel
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T028-T032).
void main() {
  group('EventModel', () {
    // Test data
    final validEventJson = {
      'id': 'event789',
      'title': 'Board games at Anti-cafe',
      'description':
          'Looking for 2 people to play Catan and Carcassonne. Bring your favorite game!',
      'organizerId': 'user123',
      'organizerName': 'Marina Petrova',
      'organizerPhotoUrl':
          'https://storage.googleapis.com/vibe-app/user123.jpg',
      'location': {'latitude': 55.7558, 'longitude': 37.6173},
      'geohash': 'ucfv0j82c',
      'locationName': 'Anti-cafe Ziferblat',
      'startTime': 1728050400,
      'neededParticipants': 2,
      'currentParticipants': 3,
      'participantIds': ['user123', 'user456', 'user789'],
      'status': 'active',
      'createdAt': 1728000000,
      'updatedAt': 1728010000,
    };

    group('fromJson', () {
      test('should create EventModel from valid JSON', () {
        final event = EventModel.fromJson(validEventJson);

        expect(event.id, 'event789');
        expect(event.title, 'Board games at Anti-cafe');
        expect(event.description, contains('Catan'));
        expect(event.organizerId, 'user123');
        expect(event.organizerName, 'Marina Petrova');
        expect(event.organizerPhotoUrl, validEventJson['organizerPhotoUrl']);
        expect(event.location, isNotNull);
        expect(event.geohash, 'ucfv0j82c');
        expect(event.locationName, 'Anti-cafe Ziferblat');
        expect(event.neededParticipants, 2);
        expect(event.currentParticipants, 3);
        expect(event.participantIds, ['user123', 'user456', 'user789']);
        expect(event.status, 'active');
      });

      test('should handle missing optional locationName', () {
        final jsonWithoutLocation = {...validEventJson};
        jsonWithoutLocation.remove('locationName');

        final event = EventModel.fromJson(jsonWithoutLocation);

        expect(event.locationName, isNull);
      });

      test('should throw when required field is missing', () {
        final invalidJson = {...validEventJson};
        invalidJson.remove('title');

        expect(
          () => EventModel.fromJson(invalidJson),
          throwsA(isA<Exception>()),
        );
      });

      test('should parse location correctly', () {
        final event = EventModel.fromJson(validEventJson);

        expect(event.location.latitude, closeTo(55.7558, 0.0001));
        expect(event.location.longitude, closeTo(37.6173, 0.0001));
      });

      test('should initialize with organizer in participantIds', () {
        final jsonWithOrganizer = {...validEventJson};
        jsonWithOrganizer['participantIds'] = ['user123'];
        jsonWithOrganizer['currentParticipants'] = 1;

        final event = EventModel.fromJson(jsonWithOrganizer);

        expect(event.participantIds, contains('user123'));
        expect(event.participantIds.length, 1);
      });
    });

    group('toJson', () {
      test('should convert EventModel to JSON', () {
        final event = EventModel.fromJson(validEventJson);
        final json = event.toJson();

        expect(json['id'], 'event789');
        expect(json['title'], 'Board games at Anti-cafe');
        expect(json['organizerId'], 'user123');
        expect(json['status'], 'active');
        expect(json['neededParticipants'], 2);
        expect(json['currentParticipants'], 3);
      });

      test('should include geohash in JSON', () {
        final event = EventModel.fromJson(validEventJson);
        final json = event.toJson();

        expect(json['geohash'], isNotEmpty);
        expect(json['geohash'], 'ucfv0j82c');
      });

      test('should include location as GeoPoint', () {
        final event = EventModel.fromJson(validEventJson);
        final json = event.toJson();

        expect(json['location'], isNotNull);
        expect(json['location'], isA<Map>());
      });

      test('should include timestamps', () {
        final event = EventModel.fromJson(validEventJson);
        final json = event.toJson();

        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
        expect(json['startTime'], isNotNull);
      });
    });

    group('validation', () {
      test('should validate title length (1-100 chars)', () {
        final emptyTitleJson = {...validEventJson, 'title': ''};

        expect(
          () => EventModel.fromJson(emptyTitleJson),
          throwsA(predicate((e) => e.toString().contains('title'))),
        );

        final longTitleJson = {...validEventJson, 'title': 'a' * 101};

        expect(
          () => EventModel.fromJson(longTitleJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('title') ||
                  e.toString().contains('100'),
            ),
          ),
        );
      });

      test('should validate description length (1-500 chars)', () {
        final emptyDescJson = {...validEventJson, 'description': ''};

        expect(
          () => EventModel.fromJson(emptyDescJson),
          throwsA(predicate((e) => e.toString().contains('description'))),
        );

        final longDescJson = {...validEventJson, 'description': 'a' * 501};

        expect(
          () => EventModel.fromJson(longDescJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('description') ||
                  e.toString().contains('500'),
            ),
          ),
        );
      });

      test('should validate neededParticipants range (1-5)', () {
        final invalidMin = {...validEventJson, 'neededParticipants': 0};
        expect(
          () => EventModel.fromJson(invalidMin),
          throwsA(predicate((e) => e.toString().contains('participants'))),
        );

        final invalidMax = {...validEventJson, 'neededParticipants': 6};
        expect(
          () => EventModel.fromJson(invalidMax),
          throwsA(predicate((e) => e.toString().contains('participants'))),
        );
      });

      test('should validate status is valid enum', () {
        final invalidStatus = {...validEventJson, 'status': 'invalid'};

        expect(
          () => EventModel.fromJson(invalidStatus),
          throwsA(predicate((e) => e.toString().contains('status'))),
        );
      });

      test('should accept valid status values', () {
        final validStatuses = ['active', 'cancelled', 'archived'];

        for (final status in validStatuses) {
          final json = {...validEventJson, 'status': status};
          final event = EventModel.fromJson(json);
          expect(event.status, status);
        }
      });

      test('should validate participantIds contains organizerId', () {
        final jsonWithoutOrganizer = {...validEventJson};
        jsonWithoutOrganizer['participantIds'] = ['user456', 'user789'];

        expect(
          () => EventModel.fromJson(jsonWithoutOrganizer),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('organizer') ||
                  e.toString().contains('participant'),
            ),
          ),
        );
      });

      test(
        'should validate currentParticipants matches participantIds length',
        () {
          final mismatchJson = {...validEventJson};
          mismatchJson['currentParticipants'] = 5;
          mismatchJson['participantIds'] = ['user123', 'user456'];

          expect(
            () => EventModel.fromJson(mismatchJson),
            throwsA(predicate((e) => e.toString().contains('participant'))),
          );
        },
      );
    });

    group('status transitions', () {
      test('should transition from active to cancelled', () {
        final event = EventModel.fromJson(validEventJson);
        final cancelled = event.cancel();

        expect(cancelled.status, 'cancelled');
        expect(cancelled.updatedAt, isNot(equals(event.updatedAt)));
      });

      test('should transition from active to archived', () {
        final event = EventModel.fromJson(validEventJson);
        final archived = event.archive();

        expect(archived.status, 'archived');
        expect(archived.updatedAt, isNot(equals(event.updatedAt)));
      });

      test('should not allow cancelling archived event', () {
        final archivedJson = {...validEventJson, 'status': 'archived'};
        final event = EventModel.fromJson(archivedJson);

        expect(
          () => event.cancel(),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('archived') ||
                  e.toString().contains('cannot'),
            ),
          ),
        );
      });

      test('should not allow archiving cancelled event', () {
        final cancelledJson = {...validEventJson, 'status': 'cancelled'};
        final event = EventModel.fromJson(cancelledJson);

        expect(
          () => event.archive(),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('cancelled') ||
                  e.toString().contains('cannot'),
            ),
          ),
        );
      });
    });

    group('participant management', () {
      test('should add participant correctly', () {
        final event = EventModel.fromJson(validEventJson);
        final updated = event.addParticipant('user999');

        expect(updated.participantIds, contains('user999'));
        expect(updated.currentParticipants, event.currentParticipants + 1);
      });

      test('should not add duplicate participant', () {
        final event = EventModel.fromJson(validEventJson);

        expect(
          () => event.addParticipant('user456'), // Already in list
          throwsA(predicate((e) => e.toString().contains('already'))),
        );
      });

      test('should not exceed max participants', () {
        final fullEventJson = {...validEventJson};
        fullEventJson['participantIds'] = [
          'user1',
          'user2',
          'user3',
          'user4',
          'user5',
          'user6',
        ];
        fullEventJson['currentParticipants'] = 6;

        final event = EventModel.fromJson(fullEventJson);

        expect(
          () => event.addParticipant('user7'),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('full') || e.toString().contains('max'),
            ),
          ),
        );
      });

      test('should remove participant correctly', () {
        final event = EventModel.fromJson(validEventJson);
        final updated = event.removeParticipant('user456');

        expect(updated.participantIds, isNot(contains('user456')));
        expect(updated.currentParticipants, event.currentParticipants - 1);
      });

      test('should not remove organizer', () {
        final event = EventModel.fromJson(validEventJson);

        expect(
          () => event.removeParticipant('user123'), // Organizer
          throwsA(predicate((e) => e.toString().contains('organizer'))),
        );
      });
    });

    group('helper methods', () {
      test('should check if event is full', () {
        final event = EventModel.fromJson(validEventJson);
        expect(event.isFull, false); // 3 participants, not at max of 6

        final fullEventJson = {...validEventJson};
        fullEventJson['currentParticipants'] = 6;
        fullEventJson['participantIds'] = [
          'user1',
          'user2',
          'user3',
          'user4',
          'user5',
          'user6',
        ];
        final fullEvent = EventModel.fromJson(fullEventJson);
        expect(fullEvent.isFull, true); // 6 participants = max capacity
      });

      test('should check if user is participant', () {
        final event = EventModel.fromJson(validEventJson);

        expect(event.isParticipant('user456'), true);
        expect(event.isParticipant('user999'), false);
      });

      test('should check if user is organizer', () {
        final event = EventModel.fromJson(validEventJson);

        expect(event.isOrganizer('user123'), true);
        expect(event.isOrganizer('user456'), false);
      });

      test('should calculate available spots', () {
        final event = EventModel.fromJson(validEventJson);
        final availableSpots = event.availableSpots;

        expect(
          availableSpots,
          event.neededParticipants - event.currentParticipants,
        );
      });

      test('should check if event is active', () {
        final event = EventModel.fromJson(validEventJson);
        expect(event.isActive, true);

        final archivedJson = {...validEventJson, 'status': 'archived'};
        final archivedEvent = EventModel.fromJson(archivedJson);
        expect(archivedEvent.isActive, false);
      });

      test('should format time until event', () {
        final event = EventModel.fromJson(validEventJson);
        final timeUntil = event.timeUntilStart;

        expect(timeUntil, isNotNull);
        expect(timeUntil, isA<Duration>());
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final event1 = EventModel.fromJson(validEventJson);
        final event2 = EventModel.fromJson(validEventJson);

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when id differs', () {
        final event1 = EventModel.fromJson(validEventJson);
        final json2 = {...validEventJson, 'id': 'different-id'};
        final event2 = EventModel.fromJson(json2);

        expect(event1, isNot(equals(event2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final event = EventModel.fromJson(validEventJson);
        final updated = event.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
        );

        expect(updated.id, event.id);
        expect(updated.title, 'Updated Title');
        expect(updated.description, 'Updated Description');
        expect(updated.organizerId, event.organizerId);
      });

      test('should not modify original when using copyWith', () {
        final event = EventModel.fromJson(validEventJson);
        final originalTitle = event.title;

        event.copyWith(title: 'New Title');

        expect(event.title, originalTitle);
      });
    });
  });
}
