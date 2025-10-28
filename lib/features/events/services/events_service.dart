import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/events/models/event_model.dart';
import 'package:vibe_app/features/events/models/event_category.dart';

/// Abstract interface for events service
///
/// Manages event creation, discovery, and lifecycle.
abstract class EventsService {
  /// Stream of active events within geographic bounds
  ///
  /// Uses geohashing for efficient location queries.
  ///
  /// [center]: Center point of search area
  /// [radiusKm]: Search radius in kilometers
  ///
  /// Returns stream of active events within radius.
  Stream<List<EventModel>> getActiveEventsInBounds({
    required GeoPoint center,
    required double radiusKm,
  });

  /// Get single event by ID
  ///
  /// Returns [EventModel] if found, null otherwise.
  Future<EventModel?> getEvent(String eventId);

  /// Get events organized by current user
  ///
  /// Returns stream of events where current user is organizer.
  Stream<List<EventModel>> getMyOrganizedEvents();

  /// Get events current user is participating in
  ///
  /// Returns stream of events where current user is participant.
  Stream<List<EventModel>> getMyParticipatingEvents();

  /// Create new event
  ///
  /// Required fields:
  /// - [title]: Event title
  /// - [description]: Event description
  /// - [category]: Event category
  /// - [location]: Geographic location (GeoPoint)
  /// - [locationName]: Optional location name/address
  /// - [startTime]: Event start time (must be in the future)
  /// - [neededParticipants]: Number of participants needed (1-5)
  ///
  /// Returns created [EventModel].
  /// Throws [EventValidationException] for invalid data.
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required GeoPoint location,
    String? locationName,
    required DateTime startTime,
    required int neededParticipants,
  });

  /// Update existing event (organizer only)
  ///
  /// [eventId]: Event to update
  /// [updates]: Map of fields to update
  ///
  /// Throws [EventPermissionException] if not organizer.
  /// Throws [EventNotFoundException] if event doesn't exist.
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates);

  /// Cancel event (organizer only)
  ///
  /// Sets status to 'cancelled' and notifies all participants.
  ///
  /// Throws [EventPermissionException] if not organizer.
  /// Throws [EventNotFoundException] if event doesn't exist.
  Future<void> cancelEvent(String eventId);

  /// Delete event completely (organizer only)
  ///
  /// Permanently removes event document and all related data.
  /// Use with caution - cannot be undone.
  ///
  /// Throws [EventPermissionException] if not organizer.
  /// Throws [EventNotFoundException] if event doesn't exist.
  Future<void> deleteEvent(String eventId);

  /// Add participant to event (after join request approved)
  ///
  /// [eventId]: Event to add participant to
  /// [userId]: User to add
  ///
  /// Throws [EventFullException] if event at capacity.
  /// Throws [EventNotFoundException] if event doesn't exist.
  Future<void> addParticipant(String eventId, String userId);

  /// Archive events that are >1 hour past start time
  ///
  /// Called by scheduled Cloud Function.
  /// Sets status to 'archived' for expired active events.
  Future<void> archiveExpiredEvents();
}

/// Base event exception
class EventException implements Exception {
  final String message;

  const EventException(this.message);

  @override
  String toString() => 'EventException: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Event not found
class EventNotFoundException extends EventException {
  const EventNotFoundException(super.message);

  @override
  String toString() => 'EventNotFoundException: $message';
}

/// Event at capacity
class EventFullException extends EventException {
  const EventFullException(super.message);

  @override
  String toString() => 'EventFullException: $message';
}

/// User not authorized for operation
class EventPermissionException extends EventException {
  const EventPermissionException(super.message);

  @override
  String toString() => 'EventPermissionException: $message';
}

/// Invalid event data
class EventValidationException extends EventException {
  const EventValidationException(super.message);

  @override
  String toString() => 'EventValidationException: $message';
}
