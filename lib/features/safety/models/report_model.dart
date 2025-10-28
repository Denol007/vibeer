import 'package:cloud_firestore/cloud_firestore.dart';

/// ReportModel represents a report of a user or event
/// Maps to Report entity in data-model.md
/// Collection: `reports`
class ReportModel {
  final String id;
  final String reporterId;
  final String reporterEmail;
  final String reportedType; // 'user' | 'event'
  final String reportedId;
  final String reportedName;
  final String reason;
  final String status; // 'pending' | 'reviewed'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterEmail,
    required this.reportedType,
    required this.reportedId,
    required this.reportedName,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewNotes,
  });

  /// Creates a ReportModel from Firestore JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) throw Exception('id is required');
    if (json['reporterId'] == null) throw Exception('reporterId is required');
    if (json['reporterEmail'] == null)
      throw Exception('reporterEmail is required');
    if (json['reportedType'] == null)
      throw Exception('reportedType is required');
    if (json['reportedId'] == null) throw Exception('reportedId is required');
    if (json['reportedName'] == null)
      throw Exception('reportedName is required');
    if (json['reason'] == null) throw Exception('reason is required');
    if (json['status'] == null) throw Exception('status is required');
    if (json['createdAt'] == null) throw Exception('createdAt is required');

    // Validate reportedType
    final reportedType = json['reportedType'] as String;
    if (reportedType != 'user' && reportedType != 'event') {
      throw Exception('reportedType must be "user" or "event"');
    }

    // Validate status
    final status = json['status'] as String;
    if (status != 'pending' && status != 'reviewed') {
      throw Exception('status must be "pending" or "reviewed"');
    }

    // Validate reason length
    final reason = json['reason'] as String;
    if (reason.length < 10) {
      throw Exception('Report reason must be at least 10 characters');
    }
    if (reason.length > 1000) {
      throw Exception('Report reason must not exceed 1000 characters');
    }

    // Validate email format
    final reporterEmail = json['reporterEmail'] as String;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(reporterEmail)) {
      throw Exception('Invalid email format');
    }

    // Parse createdAt timestamp
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
      throw Exception('Invalid createdAt timestamp format');
    }

    // Parse optional reviewedAt timestamp
    DateTime? reviewedAt;
    if (json['reviewedAt'] != null) {
      if (json['reviewedAt'] is int) {
        reviewedAt = DateTime.fromMillisecondsSinceEpoch(
          (json['reviewedAt'] as int) * 1000,
        );
      } else if (json['reviewedAt'] is Timestamp) {
        reviewedAt = (json['reviewedAt'] as Timestamp).toDate();
      } else if (json['reviewedAt'] is Map) {
        // Handle Firestore Timestamp as Map (e.g., from test data)
        final timestampMap = json['reviewedAt'] as Map<String, dynamic>;
        final seconds = timestampMap['_seconds'] as int;
        reviewedAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reporterEmail: reporterEmail,
      reportedType: reportedType,
      reportedId: json['reportedId'] as String,
      reportedName: json['reportedName'] as String,
      reason: reason,
      status: status,
      createdAt: createdAt,
      reviewedAt: reviewedAt,
      reviewNotes: json['reviewNotes'] as String?,
    );
  }

  /// Converts ReportModel to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterEmail': reporterEmail,
      'reportedType': reportedType,
      'reportedId': reportedId,
      'reportedName': reportedName,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'reviewedAt': reviewedAt != null
          ? reviewedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'reviewNotes': reviewNotes,
    };
  }

  /// Creates a copy with optional new values
  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reporterEmail,
    String? reportedType,
    String? reportedId,
    String? reportedName,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      reportedType: reportedType ?? this.reportedType,
      reportedId: reportedId ?? this.reportedId,
      reportedName: reportedName ?? this.reportedName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  /// Checks if report status is pending
  bool get isPending => status == 'pending';

  /// Checks if report status is reviewed
  bool get isReviewed => status == 'reviewed';

  /// Checks if this is a user report
  bool get isUserReport => reportedType == 'user';

  /// Checks if this is an event report
  bool get isEventReport => reportedType == 'event';

  /// Checks if report was created by a specific user
  bool isCreatedBy(String userId) => reporterId == userId;

  /// Checks if report is about a specific item (user or event)
  bool isReporting(String itemId) => reportedId == itemId;

  /// Checks if report has been reviewed (has reviewedAt timestamp)
  bool get hasBeenReviewed => reviewedAt != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel &&
        other.id == id &&
        other.reporterId == reporterId &&
        other.reporterEmail == reporterEmail &&
        other.reportedType == reportedType &&
        other.reportedId == reportedId &&
        other.reportedName == reportedName &&
        other.reason == reason &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.reviewedAt == reviewedAt &&
        other.reviewNotes == reviewNotes;
  }

  @override
  int get hashCode => Object.hash(
    id,
    reporterId,
    reporterEmail,
    reportedType,
    reportedId,
    reportedName,
    reason,
    status,
    createdAt,
    reviewedAt,
    reviewNotes,
  );

  @override
  String toString() {
    return 'ReportModel(id: $id, reporterId: $reporterId, reportedType: $reportedType, reportedId: $reportedId, status: $status)';
  }
}
