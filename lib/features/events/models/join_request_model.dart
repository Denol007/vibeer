import 'package:cloud_firestore/cloud_firestore.dart';

/// Join Request data model for Vibe MVP
///
/// Represents a user's request to join an event.
class JoinRequestModel {
  final String id;
  final String eventId;
  final String requesterId;
  final String requesterName;
  final String requesterPhotoUrl;
  final int requesterAge;
  final String? requesterAboutMe;
  final String organizerId;
  final String status; // 'pending', 'approved', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  const JoinRequestModel({
    required this.id,
    required this.eventId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhotoUrl,
    required this.requesterAge,
    this.requesterAboutMe,
    required this.organizerId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Creates a JoinRequestModel from JSON (Firestore document)
  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) throw Exception('Request ID is required');
    if (json['eventId'] == null) throw Exception('Event ID is required');
    if (json['requesterId'] == null)
      throw Exception('Requester ID is required');
    if (json['requesterName'] == null)
      throw Exception('Requester name is required');
    if (json['requesterPhotoUrl'] == null)
      throw Exception('Requester photo URL is required');
    if (json['requesterAge'] == null)
      throw Exception('Requester age is required');
    if (json['organizerId'] == null)
      throw Exception('Organizer ID is required');
    if (json['status'] == null) throw Exception('Request status is required');
    if (json['createdAt'] == null) throw Exception('Created at is required');

    // Validate age range
    final age = json['requesterAge'] as int;
    if (age < 18 || age > 25) {
      throw Exception('Requester must be between 18 and 25 years old');
    }

    // Validate status
    final status = json['status'] as String;
    if (status != 'pending' && status != 'approved' && status != 'declined') {
      throw Exception(
        'Invalid request status. Must be pending, approved, or declined',
      );
    }

    // Validate requester is not organizer
    if (json['requesterId'] == json['organizerId']) {
      throw Exception('organizer cannot join their own event');
    }

    // Parse timestamps
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

    DateTime? respondedAt;
    if (json['respondedAt'] != null) {
      if (json['respondedAt'] is int) {
        respondedAt = DateTime.fromMillisecondsSinceEpoch(
          (json['respondedAt'] as int) * 1000,
        );
      } else if (json['respondedAt'] is Timestamp) {
        respondedAt = (json['respondedAt'] as Timestamp).toDate();
      } else {
        throw Exception('Invalid respondedAt format');
      }
    }

    return JoinRequestModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      requesterPhotoUrl: json['requesterPhotoUrl'] as String,
      requesterAge: age,
      requesterAboutMe: json['requesterAboutMe'] as String?,
      organizerId: json['organizerId'] as String,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
    );
  }

  /// Converts JoinRequestModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'eventId': eventId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhotoUrl': requesterPhotoUrl,
      'requesterAge': requesterAge,
      'organizerId': organizerId,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
    };

    if (requesterAboutMe != null) {
      json['requesterAboutMe'] = requesterAboutMe!;
    }

    if (respondedAt != null) {
      json['respondedAt'] = respondedAt!.millisecondsSinceEpoch ~/ 1000;
    }

    return json;
  }

  /// Creates a copy of this request with modified fields
  JoinRequestModel copyWith({
    String? id,
    String? eventId,
    String? requesterId,
    String? requesterName,
    String? requesterPhotoUrl,
    int? requesterAge,
    String? requesterAboutMe,
    String? organizerId,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhotoUrl: requesterPhotoUrl ?? this.requesterPhotoUrl,
      requesterAge: requesterAge ?? this.requesterAge,
      requesterAboutMe: requesterAboutMe ?? this.requesterAboutMe,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// Approves this request
  JoinRequestModel approve() {
    if (status != 'pending') {
      throw Exception('Can only approve pending requests');
    }
    return copyWith(status: 'approved', respondedAt: DateTime.now());
  }

  /// Declines this request
  JoinRequestModel decline() {
    if (status != 'pending') {
      throw Exception('Can only decline pending requests');
    }
    return copyWith(status: 'declined', respondedAt: DateTime.now());
  }

  /// Checks if request is pending
  bool get isPending => status == 'pending';

  /// Checks if request is approved
  bool get isApproved => status == 'approved';

  /// Checks if request is declined
  bool get isDeclined => status == 'declined';

  /// Checks if request has been responded to
  bool get hasBeenResponded => respondedAt != null;

  /// Gets response time duration
  Duration? get responseTime {
    if (respondedAt == null) return null;
    return respondedAt!.difference(createdAt);
  }

  /// Gets requester display name
  String get requesterDisplayName => requesterName;

  /// Checks if request is from a specific user
  bool isFromUser(String userId) => requesterId == userId;

  /// Checks if request is for a specific event
  bool isForEvent(String eventId) => this.eventId == eventId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JoinRequestModel &&
        other.id == id &&
        other.eventId == eventId &&
        other.requesterId == requesterId &&
        other.requesterName == requesterName &&
        other.requesterPhotoUrl == requesterPhotoUrl &&
        other.requesterAge == requesterAge &&
        other.requesterAboutMe == requesterAboutMe &&
        other.organizerId == organizerId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.respondedAt == respondedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      requesterId,
      requesterName,
      requesterPhotoUrl,
      requesterAge,
      requesterAboutMe,
      organizerId,
      status,
      createdAt,
      respondedAt,
    );
  }

  @override
  String toString() {
    return 'JoinRequestModel(id: $id, eventId: $eventId, requesterId: $requesterId, status: $status)';
  }
}
