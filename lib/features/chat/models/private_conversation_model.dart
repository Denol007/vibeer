import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for private conversation between two users
///
/// Represents a 1-on-1 chat conversation with metadata
class PrivateConversationModel {
  final String id; // conversation ID (sorted userIds joined)
  final List<String> participantIds; // Always 2 users
  final Map<String, dynamic> participantData; // {userId: {name, photoUrl}}
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts; // {userId: count}
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivateConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantData,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.unreadCounts = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create conversation ID from two user IDs (sorted alphabetically)
  static String createConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get the other participant's ID
  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  /// Get the other participant's name
  String getOtherUserName(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return participantData[otherId]?['name'] ?? 'Unknown';
  }

  /// Get the other participant's photo URL
  String getOtherUserPhotoUrl(String currentUserId) {
    final otherId = getOtherUserId(currentUserId);
    return participantData[otherId]?['photoUrl'] ?? '';
  }

  /// Get unread count for specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  factory PrivateConversationModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw Exception('Conversation ID is required');
    if (json['participantIds'] == null) {
      throw Exception('Participant IDs are required');
    }

    final participantIds = List<String>.from(json['participantIds'] as List);
    if (participantIds.length != 2) {
      throw Exception('Private conversation must have exactly 2 participants');
    }

    // Parse participantData
    final participantData = Map<String, dynamic>.from(
      json['participantData'] as Map? ?? {},
    );

    // Parse timestamps
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      return DateTime.now();
    }

    final lastMessageTime = json['lastMessageTime'] != null
        ? parseTimestamp(json['lastMessageTime'])
        : null;

    // Parse unread counts
    final unreadCounts = Map<String, int>.from(
      (json['unreadCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value as int),
          ) ??
          {},
    );

    return PrivateConversationModel(
      id: json['id'] as String,
      participantIds: participantIds,
      participantData: participantData,
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageTime: lastMessageTime,
      unreadCounts: unreadCounts,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantData': participantData,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PrivateConversationModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, dynamic>? participantData,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivateConversationModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantData: participantData ?? this.participantData,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
