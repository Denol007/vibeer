import 'package:cloud_firestore/cloud_firestore.dart';

/// Message data model for Vibe MVP
///
/// Represents a chat message in an event's group chat.
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String text;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    this.isSystemMessage = false,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.readBy = const [],
  });

  /// Creates a MessageModel from JSON (Firestore document)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) throw Exception('Message ID is required');
    if (json['senderId'] == null) throw Exception('Sender ID is required');
    if (json['senderName'] == null) throw Exception('Sender name is required');
    if (json['senderPhotoUrl'] == null)
      throw Exception('Sender photo URL is required');
    if (json['text'] == null) throw Exception('Message text is required');
    if (json['timestamp'] == null)
      throw Exception('Message timestamp is required');

    // Validate senderId and senderName are not empty for regular messages
    final senderId = json['senderId'] as String;
    final senderName = json['senderName'] as String;
    final isSystemMessage = json['isSystemMessage'] as bool? ?? false;

    if (!isSystemMessage && senderId.isEmpty) {
      throw Exception('sender ID cannot be empty for regular messages');
    }
    if (!isSystemMessage && senderName.isEmpty) {
      throw Exception('sender name cannot be empty for regular messages');
    }

    // Validate and trim text
    final text = (json['text'] as String).trim();
    if (text.isEmpty || text.length > 1000) {
      throw Exception('Message text must be 1-1000 characters');
    }

    // Parse timestamp
    DateTime timestamp;
    if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int) * 1000,
      );
    } else if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else {
      throw Exception('Invalid timestamp format');
    }

    // Validate timestamp is in the past
    if (timestamp.isAfter(DateTime.now())) {
      throw Exception('Message timestamp cannot be in the future');
    }

    // Parse optional reply fields
    final replyToMessageId = json['replyToMessageId'] as String?;
    final replyToText = json['replyToText'] as String?;
    final replyToSenderName = json['replyToSenderName'] as String?;

    // Parse readBy list
    final readBy =
        (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [];

    return MessageModel(
      id: json['id'] as String,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: json['senderPhotoUrl'] as String,
      text: text,
      timestamp: timestamp,
      isSystemMessage: isSystemMessage,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      readBy: readBy,
    );
  }

  /// Converts MessageModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'isSystemMessage': isSystemMessage,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      'readBy': readBy,
    };
  }

  /// Creates a copy of this message with modified fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? text,
    DateTime? timestamp,
    bool? isSystemMessage,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      readBy: readBy ?? this.readBy,
    );
  }

  /// Creates a system message
  factory MessageModel.createSystemMessage({
    required String id,
    required String text,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      senderId: 'system',
      senderName: 'System',
      senderPhotoUrl: '',
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      isSystemMessage: true,
    );
  }

  /// Generates a preview of the message
  String preview({int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Gets preview (first 50 characters)
  String get previewText => preview();

  /// Checks if message is from a specific user
  bool isFromUser(String userId) => senderId == userId;

  /// Checks if this is a system message (alias for isSystemMessage)
  bool get isSystem => isSystemMessage;

  /// Gets time elapsed since message was sent as a human-readable string
  String get timeAgo {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Gets formatted time string (HH:mm)
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Checks if message is recent (within last 5 minutes)
  bool get isRecent {
    final duration = DateTime.now().difference(timestamp);
    return duration.inMinutes < 5;
  }

  /// Checks if this message is before another
  bool isBefore(MessageModel other) => timestamp.isBefore(other.timestamp);

  /// Checks if this message is after another
  bool isAfter(MessageModel other) => timestamp.isAfter(other.timestamp);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageModel &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderPhotoUrl == senderPhotoUrl &&
        other.text == text &&
        other.timestamp == timestamp &&
        other.isSystemMessage == isSystemMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderId,
      senderName,
      senderPhotoUrl,
      text,
      timestamp,
      isSystemMessage,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, text: $preview, isSystemMessage: $isSystemMessage)';
  }

  /// Compares messages by timestamp for sorting
  int compareTo(MessageModel other) {
    return timestamp.compareTo(other.timestamp);
  }
}
