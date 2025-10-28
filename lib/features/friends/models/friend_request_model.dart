import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend Request data model
///
/// Represents a friend request between two users.
/// Status can be: 'pending', 'accepted', 'declined'
class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderPhotoUrl;
  final String receiverName;
  final String receiverPhotoUrl;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.receiverName,
    required this.receiverPhotoUrl,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Creates a FriendRequestModel from JSON (Firestore document)
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      senderName: json['senderName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String,
      receiverName: json['receiverName'] as String,
      receiverPhotoUrl: json['receiverPhotoUrl'] as String,
      status: json['status'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts FriendRequestModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  /// Creates a copy of this model with some fields replaced
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? senderPhotoUrl,
    String? receiverName,
    String? receiverPhotoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// Check if request is pending
  bool get isPending => status == 'pending';

  /// Check if request is accepted
  bool get isAccepted => status == 'accepted';

  /// Check if request is declined
  bool get isDeclined => status == 'declined';
}
