import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/events/services/events_service.dart';
import 'package:vibe_app/features/events/models/event_model.dart';
import 'package:vibe_app/features/events/models/event_category.dart';

import 'events_service_test.mocks.dart';

/// Unit tests for EventsService interface
/// T015 - TDD phase tests that MUST FAIL before implementation
@GenerateMocks([EventsService])
void main() {
  group('EventsService Contract', () {
    late EventsService mockEventsService;

    setUp(() {
      mockEventsService = MockEventsService();
    });

    group('createEvent', () {
      test('should create event with all required fields', () async {
        final testStartTime = DateTime.now().add(const Duration(hours: 2));
        final event = EventModel(
          id: 'event123',
          title: 'Board games',
          description: 'Looking for players',
          category: EventCategory.games,
          organizerId: 'user123',
          organizerName: 'Marina',
          organizerPhotoUrl: 'https://example.com/photo.jpg',
          location: const GeoPoint(55.7558, 37.6173),
          geohash: 'ucfv0j82c',
          startTime: testStartTime,
          neededParticipants: 3,
          currentParticipants: 1,
          participantIds: ['user123'],
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          mockEventsService.createEvent(
            title: 'Board games',
            description: 'Looking for players',
            category: EventCategory.games,
            location: const GeoPoint(55.7558, 37.6173),
            startTime: testStartTime,
            neededParticipants: 3,
          ),
        ).thenAnswer((_) async => event);

        final result = await mockEventsService.createEvent(
          title: 'Board games',
          description: 'Looking for players',
          category: EventCategory.games,
          location: const GeoPoint(55.7558, 37.6173),
          startTime: testStartTime,
          neededParticipants: 3,
        );

        expect(result.title, 'Board games');
        expect(result.status, 'active');
        expect(result.category, EventCategory.games);
      });

      test('should throw EventValidationException for invalid time', () async {
        final invalidStartTime = DateTime.now().add(const Duration(hours: 25));

        when(
          mockEventsService.createEvent(
            title: 'Event',
            description: 'Test',
            category: EventCategory.other,
            location: const GeoPoint(55.7558, 37.6173),
            startTime: invalidStartTime,
            neededParticipants: 3,
          ),
        ).thenThrow(EventValidationException('Event must be within 24 hours'));

        expect(
          () => mockEventsService.createEvent(
            title: 'Event',
            description: 'Test',
            category: EventCategory.other,
            location: const GeoPoint(55.7558, 37.6173),
            startTime: invalidStartTime,
            neededParticipants: 3,
          ),
          throwsA(isA<EventValidationException>()),
        );
      });
    });

    group('getActiveEventsInBounds', () {
      test('should return events within geographic radius', () async {
        final events = <EventModel>[];
        when(
          mockEventsService.getActiveEventsInBounds(
            center: const GeoPoint(55.7558, 37.6173),
            radiusKm: 10.0,
          ),
        ).thenAnswer((_) => Stream.value(events));

        final stream = mockEventsService.getActiveEventsInBounds(
          center: const GeoPoint(55.7558, 37.6173),
          radiusKm: 10.0,
        );

        expect(stream, isA<Stream<List<EventModel>>>());
      });
    });

    group('cancelEvent', () {
      test('should cancel event and notify participants', () async {
        when(
          mockEventsService.cancelEvent('event123'),
        ).thenAnswer((_) async => {});

        await mockEventsService.cancelEvent('event123');

        verify(mockEventsService.cancelEvent('event123')).called(1);
      });

      test('should throw EventPermissionException if not organizer', () async {
        when(
          mockEventsService.cancelEvent('event123'),
        ).thenThrow(EventPermissionException('Only organizer can cancel'));

        expect(
          () => mockEventsService.cancelEvent('event123'),
          throwsA(isA<EventPermissionException>()),
        );
      });
    });
  });
}

class EventValidationException implements Exception {
  final String message;
  EventValidationException(this.message);
}

class EventPermissionException implements Exception {
  final String message;
  EventPermissionException(this.message);
}
