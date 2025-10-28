import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user notification
///
/// Notifications are created for important events like:
/// - Join requests for events
/// - Join request responses (approved/rejected)
/// - Event updates
/// - Chat messages
class NotificationModel {
  final String id;
  final String userId; // Recipient user ID
  final NotificationType type;
  final String title;
  final String message;
  final String? eventId; // Related event (if applicable)
  final String? senderId; // User who triggered the notification
  final String? senderName;
  final String? senderPhotoUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.eventId,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.isRead,
    required this.createdAt,
  });

  /// Create notification from Firestore document
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      eventId: json['eventId'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert notification to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toFirestore(),
      'title': title,
      'message': message,
      if (eventId != null) 'eventId': eventId,
      if (senderId != null) 'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? eventId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Types of notifications
enum NotificationType {
  joinRequest,     // Someone requested to join your event
  joinApproved,    // Your join request was approved
  joinRejected,    // Your join request was rejected
  eventUpdate,     // Event you're in was updated
  eventCancelled,  // Event you're in was cancelled
  chatMessage,     // New message in event chat
  eventReminder,   // Event starting soon
  ;

  /// Get display name in Russian
  String get displayName {
    switch (this) {
      case NotificationType.joinRequest:
        return 'Запрос на присоединение';
      case NotificationType.joinApproved:
        return 'Запрос одобрен';
      case NotificationType.joinRejected:
        return 'Запрос отклонен';
      case NotificationType.eventUpdate:
        return 'Обновление события';
      case NotificationType.eventCancelled:
        return 'Событие отменено';
      case NotificationType.chatMessage:
        return 'Новое сообщение';
      case NotificationType.eventReminder:
        return 'Напоминание о событии';
    }
  }

  /// Get icon for notification type
  String get icon {
    switch (this) {
      case NotificationType.joinRequest:
        return '👋';
      case NotificationType.joinApproved:
        return '✅';
      case NotificationType.joinRejected:
        return '❌';
      case NotificationType.eventUpdate:
        return '📝';
      case NotificationType.eventCancelled:
        return '🚫';
      case NotificationType.chatMessage:
        return '💬';
      case NotificationType.eventReminder:
        return '⏰';
    }
  }

  /// Convert to Firestore string
  String toFirestore() => name;

  /// Parse from Firestore string
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.eventUpdate,
    );
  }
}
