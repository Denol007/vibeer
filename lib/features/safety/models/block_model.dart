import 'package:cloud_firestore/cloud_firestore.dart';

/// BlockModel represents a block relationship between two users
/// Maps to BlockRelationship entity in data-model.md
/// Collection: `blocks`
/// Document ID format: `{blockerId}_{blockedId}`
class BlockModel {
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const BlockModel({
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  /// Creates a BlockModel from Firestore JSON
  factory BlockModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['blockerId'] == null) throw Exception('blockerId is required');
    if (json['blockedId'] == null) throw Exception('blockedId is required');
    if (json['createdAt'] == null) throw Exception('createdAt is required');

    // Validate IDs are not empty
    final blockerId = json['blockerId'] as String;
    final blockedId = json['blockedId'] as String;

    if (blockerId.isEmpty) {
      throw Exception('blockerId cannot be empty');
    }
    if (blockedId.isEmpty) {
      throw Exception('blockedId cannot be empty');
    }

    // Validate user cannot block themselves
    if (blockerId == blockedId) {
      throw Exception('User cannot block themselves');
    }

    // Parse timestamp
    DateTime createdAt;
    if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int) * 1000,
      );
    } else if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is Map) {
      // Handle Firestore Timestamp as Map (e.g., from test data)
      final timestampMap = json['createdAt'] as Map<String, dynamic>;
      final seconds = timestampMap['_seconds'] as int;
      createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } else {
      throw Exception('Invalid timestamp format');
    }

    return BlockModel(
      blockerId: blockerId,
      blockedId: blockedId,
      createdAt: createdAt,
    );
  }

  /// Converts BlockModel to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Creates a copy with optional new values
  BlockModel copyWith({
    String? blockerId,
    String? blockedId,
    DateTime? createdAt,
  }) {
    return BlockModel(
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Generates the composite document ID for Firestore
  /// Format: `{blockerId}_{blockedId}`
  String get documentId => '${blockerId}_$blockedId';

  /// Checks if this block is blocking a specific user
  bool isBlockingUser(String userId) => blockedId == userId;

  /// Checks if this block was created by a specific user
  bool isCreatedBy(String userId) => blockerId == userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockModel &&
        other.blockerId == blockerId &&
        other.blockedId == blockedId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(blockerId, blockedId, createdAt);

  @override
  String toString() {
    return 'BlockModel(blockerId: $blockerId, blockedId: $blockedId, createdAt: $createdAt)';
  }
}
