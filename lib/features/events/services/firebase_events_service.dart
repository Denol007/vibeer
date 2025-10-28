import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/events/models/event_category.dart';
import 'package:vibe_app/features/events/models/event_model.dart';
import 'package:vibe_app/features/events/services/events_service.dart';

/// Firebase implementation of [EventsService]
///
/// Manages events in Firestore with geohash-based location queries.
class FirebaseEventsService implements EventsService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseEventsService({
    required AuthService authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<EventModel>> getActiveEventsInBounds({
    required GeoPoint center,
    required double radiusKm,
  }) {
    try {
      // Use GeoFlutterFire for geohash-based queries
      final collectionRef = _firestore.collection('events');

      return GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: GeoFirePoint(center),
            radiusInKm: radiusKm,
            field: 'location',
            geopointFrom: (data) =>
                (data['location'] as Map<String, dynamic>)['geopoint']
                    as GeoPoint,
            strictMode: true,
          )
          .map((documentSnapshots) {
            // Filter for active status (can't use where clause with geo queries)
            return documentSnapshots
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['status'] ==
                      'active',
                )
                .map(
                  (doc) => EventModel.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }),
                )
                .toList();
          });
    } catch (e) {
      // Return error stream
      return Stream.error(EventException('Failed to query events: $e'));
    }
  }

  @override
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) {
        return null;
      }

      return EventModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw EventException('Failed to get event: $e');
    }
  }

  @override
  Stream<List<EventModel>> getMyOrganizedEvents() {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      // Simplified query to avoid composite index
      // Filter by organizerId only, do status filtering and sorting in-memory
      return _firestore
          .collection('events')
          .where('organizerId', isEqualTo: currentUser.id)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map(
                  (doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}),
                )
                .where(
                  (event) =>
                      event.status == 'active' || event.status == 'cancelled',
                )
                .toList();

            // Sort by createdAt descending (newest first)
            events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return events;
          });
    } catch (e) {
      return Stream.error(EventException('Failed to get organized events: $e'));
    }
  }

  @override
  Stream<List<EventModel>> getMyParticipatingEvents() {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      // Simplified query to avoid composite index
      // Filter by participantIds only, do status filtering and sorting in-memory
      return _firestore
          .collection('events')
          .where('participantIds', arrayContains: currentUser.id)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map(
                  (doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}),
                )
                .where((event) => event.status == 'active')
                .toList();

            // Sort by startTime ascending (soonest first)
            events.sort((a, b) => a.startTime.compareTo(b.startTime));

            return events;
          });
    } catch (e) {
      return Stream.error(
        EventException('Failed to get participating events: $e'),
      );
    }
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required GeoPoint location,
    String? locationName,
    required DateTime startTime,
    required int neededParticipants,
  }) async {
    try {
      // Validate current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const EventException('No authenticated user');
      }

      // Validate start time (must be in the future)
      final now = DateTime.now();
      if (startTime.isBefore(now)) {
        throw const EventValidationException('Event must be in the future');
      }

      // Validate needed participants (1-5)
      if (neededParticipants < 1 || neededParticipants > 5) {
        throw const EventValidationException('Needed participants must be 1-5');
      }

      // Generate geohash using GeoFlutterFire
      final geoPoint = GeoFirePoint(location);

      // Create event document
      final eventData = {
        'title': title,
        'description': description,
        'category': category.toFirestore(),
        'organizerId': currentUser.id,
        'organizerName': currentUser.name,
        'organizerPhotoUrl': currentUser.profilePhotoUrl,
        'location': geoPoint.data,
        'locationName': locationName,
        'geohash': geoPoint.geohash,
        'startTime': Timestamp.fromDate(startTime),
        'neededParticipants': neededParticipants,
        'currentParticipants': 1,
        'participantIds': [currentUser.id],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('events').add(eventData);

      // Fetch created document to get server timestamps
      final createdDoc = await docRef.get();

      return EventModel.fromJson({...createdDoc.data()!, 'id': createdDoc.id});
    } on EventException {
      rethrow;
    } catch (e) {
      throw EventException('Failed to create event: $e');
    }
  }

  @override
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      // Validate current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const EventException('No authenticated user');
      }

      // Get event to check permissions
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventNotFoundException('Event not found: $eventId');
      }

      if (event.organizerId != currentUser.id) {
        throw const EventPermissionException('Only organizer can update event');
      }

      // Add updatedAt timestamp
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('events').doc(eventId).update(updateData);
    } on EventException {
      rethrow;
    } catch (e) {
      throw EventException('Failed to update event: $e');
    }
  }

  @override
  Future<void> cancelEvent(String eventId) async {
    try {
      // Validate current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const EventException('No authenticated user');
      }

      // Get event to check permissions
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventNotFoundException('Event not found: $eventId');
      }

      if (event.organizerId != currentUser.id) {
        throw const EventPermissionException('Only organizer can cancel');
      }

      // Update status to cancelled
      await _firestore.collection('events').doc(eventId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Note: Cloud Function will handle participant notifications
    } on EventException {
      rethrow;
    } catch (e) {
      throw EventException('Failed to cancel event: $e');
    }
  }

  @override
  Future<void> addParticipant(String eventId, String userId) async {
    try {
      // Get event
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventNotFoundException('Event not found: $eventId');
      }

      // Check if event is full
      if (event.currentParticipants >= event.neededParticipants) {
        throw const EventFullException('Event is full');
      }

      // Add participant
      await _firestore.collection('events').doc(eventId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on EventException {
      rethrow;
    } catch (e) {
      throw EventException('Failed to add participant: $e');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      // Validate current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const EventException('No authenticated user');
      }

      // Get event to check permissions
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventNotFoundException('Event not found: $eventId');
      }

      if (event.organizerId != currentUser.id) {
        throw const EventPermissionException('Only organizer can delete');
      }

      // Delete related data in batch
      final batch = _firestore.batch();

      // Delete all join requests for this event
      final joinRequests = await _firestore
          .collection('joinRequests')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in joinRequests.docs) {
        batch.delete(doc.reference);
      }

      // Delete all messages in this event's chat
      final messages = await _firestore
          .collection('messages')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the event itself
      batch.delete(_firestore.collection('events').doc(eventId));

      // Commit all deletions
      await batch.commit();
    } on EventException {
      rethrow;
    } catch (e) {
      throw EventException('Failed to delete event: $e');
    }
  }

  @override
  Future<void> archiveExpiredEvents() async {
    try {
      // Query active events that started >1 hour ago
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final expiredEvents = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'active')
          .where('startTime', isLessThan: Timestamp.fromDate(oneHourAgo))
          .get();

      // Batch update to archived status
      final batch = _firestore.batch();
      for (final doc in expiredEvents.docs) {
        batch.update(doc.reference, {
          'status': 'archived',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw EventException('Failed to archive expired events: $e');
    }
  }
}
