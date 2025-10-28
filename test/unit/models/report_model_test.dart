import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/safety/models/report_model.dart';

/// Unit tests for ReportModel
///
/// These tests validate the ReportModel (Report entity from data-model.md)

void main() {
  group('ReportModel', () {
    // Test data
    final validReportJson = {
      'id': 'report555',
      'reporterId': 'user123',
      'reporterEmail': 'marina@example.com',
      'reportedType': 'user',
      'reportedId': 'user999',
      'reportedName': 'Suspicious User',
      'reason': 'Inappropriate behavior in chat',
      'status': 'pending',
      'createdAt': 1759561000, // October 4, 2025
    };

    group('fromJson', () {
      test('should parse valid JSON for user report', () {
        final report = ReportModel.fromJson(validReportJson);

        expect(report.id, 'report555');
        expect(report.reporterId, 'user123');
        expect(report.reporterEmail, 'marina@example.com');
        expect(report.reportedType, 'user');
        expect(report.reportedId, 'user999');
        expect(report.reportedName, 'Suspicious User');
        expect(report.reason, 'Inappropriate behavior in chat');
        expect(report.status, 'pending');
        expect(report.createdAt.year, 2025);
        expect(report.reviewedAt, null);
        expect(report.reviewNotes, null);
      });

      test('should parse valid JSON for event report', () {
        final eventReportJson = Map<String, dynamic>.from(validReportJson);
        eventReportJson['reportedType'] = 'event';
        eventReportJson['reportedId'] = 'event789';
        eventReportJson['reportedName'] = 'Fake Event';

        final report = ReportModel.fromJson(eventReportJson);

        expect(report.reportedType, 'event');
        expect(report.reportedId, 'event789');
      });

      test('should handle optional reviewedAt and reviewNotes', () {
        final reviewedReportJson = Map<String, dynamic>.from(validReportJson);
        reviewedReportJson['status'] = 'reviewed';
        reviewedReportJson['reviewedAt'] = 1759566000;
        reviewedReportJson['reviewNotes'] =
            'User warned, no further action needed';

        final report = ReportModel.fromJson(reviewedReportJson);

        expect(report.status, 'reviewed');
        expect(report.reviewedAt, isNotNull);
        expect(report.reviewNotes, 'User warned, no further action needed');
      });

      test('should throw when required field is missing', () {
        final jsonWithoutReason = Map<String, dynamic>.from(validReportJson);
        jsonWithoutReason.remove('reason');

        expect(
          () => ReportModel.fromJson(jsonWithoutReason),
          throwsA(isA<Exception>()),
        );
      });

      test('should parse Timestamp from Firestore', () {
        final jsonWithTimestamp = Map<String, dynamic>.from(validReportJson);
        jsonWithTimestamp['createdAt'] = {
          '_seconds': 1759561000,
          '_nanoseconds': 0,
        };

        final report = ReportModel.fromJson(jsonWithTimestamp);

        expect(report.createdAt, isNotNull);
        expect(report.createdAt.year, 2025);
      });
    });

    group('validation', () {
      test('should validate reportedType is valid', () {
        final invalidJson = Map<String, dynamic>.from(validReportJson);
        invalidJson['reportedType'] = 'invalid';

        expect(
          () => ReportModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('reportedType'),
            ),
          ),
        );
      });

      test('should accept valid reportedType values', () {
        final userReport = ReportModel.fromJson(validReportJson);
        expect(userReport.reportedType, 'user');

        final eventReportJson = Map<String, dynamic>.from(validReportJson);
        eventReportJson['reportedType'] = 'event';
        final eventReport = ReportModel.fromJson(eventReportJson);
        expect(eventReport.reportedType, 'event');
      });

      test('should validate status is valid', () {
        final invalidJson = Map<String, dynamic>.from(validReportJson);
        invalidJson['status'] = 'invalid';

        expect(
          () => ReportModel.fromJson(invalidJson),
          throwsA(
            predicate((e) => e is Exception && e.toString().contains('status')),
          ),
        );
      });

      test('should accept valid status values', () {
        final pendingReport = ReportModel.fromJson(validReportJson);
        expect(pendingReport.status, 'pending');

        final reviewedJson = Map<String, dynamic>.from(validReportJson);
        reviewedJson['status'] = 'reviewed';
        final reviewedReport = ReportModel.fromJson(reviewedJson);
        expect(reviewedReport.status, 'reviewed');
      });

      test('should validate reason has minimum length', () {
        final invalidJson = Map<String, dynamic>.from(validReportJson);
        invalidJson['reason'] = 'Short';

        expect(
          () => ReportModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('10 characters'),
            ),
          ),
        );
      });

      test('should validate reason has maximum length', () {
        final invalidJson = Map<String, dynamic>.from(validReportJson);
        invalidJson['reason'] = 'A' * 1001;

        expect(
          () => ReportModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('1000 characters'),
            ),
          ),
        );
      });

      test('should validate email format', () {
        final invalidJson = Map<String, dynamic>.from(validReportJson);
        invalidJson['reporterEmail'] = 'not-an-email';

        expect(
          () => ReportModel.fromJson(invalidJson),
          throwsA(
            predicate((e) => e is Exception && e.toString().contains('email')),
          ),
        );
      });
    });

    group('toJson', () {
      test('should convert to JSON with timestamps as seconds', () {
        final report = ReportModel.fromJson(validReportJson);
        final json = report.toJson();

        expect(json['id'], 'report555');
        expect(json['reporterId'], 'user123');
        expect(json['reporterEmail'], 'marina@example.com');
        expect(json['reportedType'], 'user');
        expect(json['reportedId'], 'user999');
        expect(json['reason'], contains('Inappropriate'));
        expect(json['status'], 'pending');
        expect(json['createdAt'], isA<int>());
        expect(json['reviewedAt'], null);
        expect(json['reviewNotes'], null);
      });

      test('should include optional fields in JSON when present', () {
        final reviewedReportJson = Map<String, dynamic>.from(validReportJson);
        reviewedReportJson['status'] = 'reviewed';
        reviewedReportJson['reviewedAt'] = 1759566000;
        reviewedReportJson['reviewNotes'] = 'Resolved';

        final report = ReportModel.fromJson(reviewedReportJson);
        final json = report.toJson();

        expect(json['reviewedAt'], isA<int>());
        expect(json['reviewNotes'], 'Resolved');
      });
    });

    group('copyWith', () {
      test('should create copy with new values', () {
        final original = ReportModel.fromJson(validReportJson);
        final newReviewDate = DateTime(2025, 10, 5);
        final copied = original.copyWith(
          status: 'reviewed',
          reviewedAt: newReviewDate,
          reviewNotes: 'Case closed',
        );

        expect(copied.id, original.id);
        expect(copied.reason, original.reason);
        expect(copied.status, 'reviewed');
        expect(copied.reviewedAt, newReviewDate);
        expect(copied.reviewNotes, 'Case closed');
        expect(original.status, 'pending');
        expect(original.reviewedAt, null);
      });

      test('should keep original values when null', () {
        final original = ReportModel.fromJson(validReportJson);
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.status, original.status);
        expect(copied.reviewedAt, original.reviewedAt);
      });
    });

    group('helper methods', () {
      test('should check if report is pending', () {
        final pending = ReportModel.fromJson(validReportJson);
        expect(pending.isPending, true);
        expect(pending.isReviewed, false);

        final reviewedJson = Map<String, dynamic>.from(validReportJson);
        reviewedJson['status'] = 'reviewed';
        final reviewed = ReportModel.fromJson(reviewedJson);
        expect(reviewed.isPending, false);
        expect(reviewed.isReviewed, true);
      });

      test('should check if reporting a user', () {
        final report = ReportModel.fromJson(validReportJson);
        expect(report.isUserReport, true);
        expect(report.isEventReport, false);
      });

      test('should check if reporting an event', () {
        final eventReportJson = Map<String, dynamic>.from(validReportJson);
        eventReportJson['reportedType'] = 'event';
        final report = ReportModel.fromJson(eventReportJson);

        expect(report.isUserReport, false);
        expect(report.isEventReport, true);
      });

      test('should check if report was created by specific user', () {
        final report = ReportModel.fromJson(validReportJson);
        expect(report.isCreatedBy('user123'), true);
        expect(report.isCreatedBy('user456'), false);
      });

      test('should check if reporting specific item', () {
        final report = ReportModel.fromJson(validReportJson);
        expect(report.isReporting('user999'), true);
        expect(report.isReporting('user456'), false);
      });

      test('should check if report has been reviewed', () {
        final pending = ReportModel.fromJson(validReportJson);
        expect(pending.hasBeenReviewed, false);

        final reviewedJson = Map<String, dynamic>.from(validReportJson);
        reviewedJson['reviewedAt'] = 1759566000;
        final reviewed = ReportModel.fromJson(reviewedJson);
        expect(reviewed.hasBeenReviewed, true);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final report1 = ReportModel.fromJson(validReportJson);
        final report2 = ReportModel.fromJson(validReportJson);

        expect(report1, equals(report2));
        expect(report1.hashCode, equals(report2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final report1 = ReportModel.fromJson(validReportJson);
        final differentJson = Map<String, dynamic>.from(validReportJson);
        differentJson['id'] = 'report999';
        final report2 = ReportModel.fromJson(differentJson);

        expect(report1, isNot(equals(report2)));
        expect(report1.hashCode, isNot(equals(report2.hashCode)));
      });
    });
  });
}
