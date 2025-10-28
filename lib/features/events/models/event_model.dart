import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_category.dart';

/// Event data model for Vibe MVP
///
/// Represents a spontaneous meetup event with location and participants.
class EventModel {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final String organizerId;
  final String organizerName;
  final String organizerPhotoUrl;
  final GeoPoint location;
  final String geohash;
  final String? locationName;
  final DateTime startTime;
  final int neededParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final String status; // 'active', 'cancelled', 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.organizerPhotoUrl,
    required this.location,
    required this.geohash,
    this.locationName,
    required this.startTime,
    required this.neededParticipants,
    required this.currentParticipants,
    required this.participantIds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an EventModel from JSON (Firestore document)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) throw Exception('Event ID is required');
    if (json['title'] == null) throw Exception('Event title is required');
    if (json['description'] == null)
      throw Exception('Event description is required');
    if (json['organizerId'] == null)
      throw Exception('Organizer ID is required');
    if (json['organizerName'] == null)
      throw Exception('Organizer name is required');
    if (json['organizerPhotoUrl'] == null)
      throw Exception('Organizer photo URL is required');
    if (json['location'] == null) throw Exception('Event location is required');
    if (json['geohash'] == null) throw Exception('Event geohash is required');
    if (json['startTime'] == null)
      throw Exception('Event start time is required');
    if (json['neededParticipants'] == null)
      throw Exception('Needed participants is required');
    if (json['currentParticipants'] == null)
      throw Exception('Current participants is required');
    if (json['participantIds'] == null)
      throw Exception('Participant IDs is required');
    if (json['status'] == null) throw Exception('Event status is required');
    if (json['createdAt'] == null) throw Exception('Created at is required');
    if (json['updatedAt'] == null) throw Exception('Updated at is required');

    // Validate title length
    final title = json['title'] as String;
    if (title.isEmpty || title.length > 100) {
      throw Exception('Event title must be 1-100 characters');
    }

    // Validate description length
    final description = json['description'] as String;
    if (description.isEmpty || description.length > 500) {
      throw Exception('Event description must be 1-500 characters');
    }

    // Parse location
    // GeoFlutterFire stores location as { geopoint: GeoPoint, geohash: string }
    final locationData = json['location'];
    GeoPoint location;

    if (locationData is GeoPoint) {
      // Direct GeoPoint (from tests or old data)
      location = locationData;
    } else if (locationData is Map<String, dynamic>) {
      // GeoFlutterFire format
      if (locationData.containsKey('geopoint')) {
        location = locationData['geopoint'] as GeoPoint;
      } else {
        // Fallback: manual latitude/longitude
        location = GeoPoint(
          (locationData['latitude'] as num).toDouble(),
          (locationData['longitude'] as num).toDouble(),
        );
      }
    } else {
      throw Exception('Invalid location format');
    }

    // Validate neededParticipants range
    final neededParticipants = json['neededParticipants'] as int;
    if (neededParticipants < 1 || neededParticipants > 5) {
      throw Exception('Needed participants must be between 1 and 5');
    }

    // Parse participantIds
    final participantIds = (json['participantIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList();

    // Validate max 6 participants
    if (participantIds.length > 6) {
      throw Exception('Maximum 6 participants allowed');
    }

    // Auto-fix currentParticipants if it doesn't match participantIds length
    // This can happen if data was corrupted or migration is in progress
    final currentParticipants = participantIds.length;

    // Validate status
    final status = json['status'] as String;
    if (status != 'active' && status != 'cancelled' && status != 'archived') {
      throw Exception('Invalid event status');
    }

    // Parse timestamps
    DateTime startTime;
    if (json['startTime'] is int) {
      startTime = DateTime.fromMillisecondsSinceEpoch(
        (json['startTime'] as int) * 1000,
      );
    } else if (json['startTime'] is Timestamp) {
      startTime = (json['startTime'] as Timestamp).toDate();
    } else {
      throw Exception('Invalid startTime format');
    }

    DateTime createdAt;
    if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int) * 1000,
      );
    } else if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else {
      throw Exception('Invalid createdAt format');
    }

    DateTime updatedAt;
    if (json['updatedAt'] is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as int) * 1000,
      );
    } else if (json['updatedAt'] is Timestamp) {
      updatedAt = (json['updatedAt'] as Timestamp).toDate();
    } else {
      throw Exception('Invalid updatedAt format');
    }

    // Parse category (default to 'other' for existing events without category)
    final categoryString = json['category'] as String?;
    final category = categoryString != null
        ? EventCategory.fromString(categoryString)
        : EventCategory.other;

    return EventModel(
      id: json['id'] as String,
      title: title,
      description: description,
      category: category,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String,
      organizerPhotoUrl: json['organizerPhotoUrl'] as String,
      location: location,
      geohash: json['geohash'] as String,
      locationName: json['locationName'] as String?,
      startTime: startTime,
      neededParticipants: neededParticipants,
      currentParticipants: currentParticipants,
      participantIds: participantIds,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts EventModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toFirestore(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'geohash': geohash,
      'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
      'neededParticipants': neededParticipants,
      'currentParticipants': currentParticipants,
      'participantIds': participantIds,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updatedAt': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };

    if (locationName != null) {
      json['locationName'] = locationName!;
    }

    return json;
  }

  /// Creates a copy of this event with modified fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    String? organizerId,
    String? organizerName,
    String? organizerPhotoUrl,
    GeoPoint? location,
    String? geohash,
    String? locationName,
    DateTime? startTime,
    int? neededParticipants,
    int? currentParticipants,
    List<String>? participantIds,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerPhotoUrl: organizerPhotoUrl ?? this.organizerPhotoUrl,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      locationName: locationName ?? this.locationName,
      startTime: startTime ?? this.startTime,
      neededParticipants: neededParticipants ?? this.neededParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Cancels this event (active → cancelled)
  EventModel cancel() {
    if (status == 'archived') {
      throw Exception('Cannot cancel an archived event');
    }
    if (status == 'cancelled') {
      throw Exception('Event is already cancelled');
    }

    return copyWith(status: 'cancelled', updatedAt: DateTime.now());
  }

  /// Archives this event (active → archived)
  EventModel archive() {
    if (status == 'cancelled') {
      throw Exception('Cannot archive a cancelled event');
    }
    if (status == 'archived') {
      throw Exception('Event is already archived');
    }

    return copyWith(status: 'archived', updatedAt: DateTime.now());
  }

  /// Adds a participant to this event
  EventModel addParticipant(String userId) {
    if (participantIds.contains(userId)) {
      throw Exception('User is already a participant');
    }

    if (participantIds.length >= 6) {
      throw Exception('Event is full - maximum 6 participants');
    }

    final newParticipantIds = [...participantIds, userId];

    return copyWith(
      participantIds: newParticipantIds,
      currentParticipants: newParticipantIds.length,
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a participant from this event
  EventModel removeParticipant(String userId) {
    if (userId == organizerId) {
      throw Exception('Cannot remove organizer from event');
    }

    if (!participantIds.contains(userId)) {
      throw Exception('User is not a participant');
    }

    final newParticipantIds = participantIds
        .where((id) => id != userId)
        .toList();

    return copyWith(
      participantIds: newParticipantIds,
      currentParticipants: newParticipantIds.length,
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if event is full (reached maximum capacity of 6 participants)
  bool get isFull => currentParticipants >= 6;

  /// Checks if event has enough participants (reached needed count)
  bool get hasEnoughParticipants =>
      currentParticipants >= neededParticipants + 1;

  /// Checks if user is organizer
  bool isOrganizer(String userId) => organizerId == userId;

  /// Checks if user is participant
  bool isParticipant(String userId) => participantIds.contains(userId);

  /// Checks if event is active
  bool get isActive => status == 'active';

  /// Checks if event is in the past
  bool get isPast => DateTime.now().isAfter(startTime);

  /// Gets available spots (needed - current, can be negative)
  int get availableSpots => neededParticipants - currentParticipants;

  /// Gets time until event starts
  Duration get timeUntilStart {
    return startTime.difference(DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.organizerId == organizerId &&
        other.organizerName == organizerName &&
        other.organizerPhotoUrl == organizerPhotoUrl &&
        other.location.latitude == location.latitude &&
        other.location.longitude == location.longitude &&
        other.geohash == geohash &&
        other.locationName == locationName &&
        other.startTime == startTime &&
        other.neededParticipants == neededParticipants &&
        other.currentParticipants == currentParticipants &&
        _listEquals(other.participantIds, participantIds) &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      organizerId,
      organizerName,
      organizerPhotoUrl,
      location.latitude,
      location.longitude,
      geohash,
      locationName,
      startTime,
      neededParticipants,
      currentParticipants,
      Object.hashAll(participantIds),
      status,
      createdAt,
      updatedAt,
    );
  }

  /// Helper to compare lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, organizerId: $organizerId, '
        'status: $status, currentParticipants: $currentParticipants/$neededParticipants)';
  }
}
