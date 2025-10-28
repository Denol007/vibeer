import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/safety/models/block_model.dart';

/// Unit tests for BlockModel
///
/// These tests validate the BlockModel (BlockRelationship entity from data-model.md)

void main() {
  group('BlockModel', () {
    // Test data
    final validBlockJson = {
      'blockerId': 'user123',
      'blockedId': 'user456',
      'createdAt': 1759556000, // October 4, 2025 00:00:00 UTC
    };

    group('fromJson', () {
      test('should parse valid JSON', () {
        final block = BlockModel.fromJson(validBlockJson);

        expect(block.blockerId, 'user123');
        expect(block.blockedId, 'user456');
        expect(block.createdAt.year, 2025);
        expect(block.createdAt.month, 10);
      });

      test('should throw when required field is missing', () {
        final jsonWithoutBlockerId = Map<String, dynamic>.from(validBlockJson);
        jsonWithoutBlockerId.remove('blockerId');

        expect(
          () => BlockModel.fromJson(jsonWithoutBlockerId),
          throwsA(isA<Exception>()),
        );
      });

      test('should parse Timestamp from Firestore', () {
        final jsonWithTimestamp = {
          ...validBlockJson,
          'createdAt': {'_seconds': 1759556000, '_nanoseconds': 0},
        };

        final block = BlockModel.fromJson(jsonWithTimestamp);

        expect(block.createdAt, isNotNull);
        expect(block.createdAt.year, 2025);
      });
    });

    group('validation', () {
      test('should validate blockerId is not empty', () {
        final invalidJson = Map<String, dynamic>.from(validBlockJson);
        invalidJson['blockerId'] = '';

        expect(
          () => BlockModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('blockerId'),
            ),
          ),
        );
      });

      test('should validate blockedId is not empty', () {
        final invalidJson = Map<String, dynamic>.from(validBlockJson);
        invalidJson['blockedId'] = '';

        expect(
          () => BlockModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('blockedId'),
            ),
          ),
        );
      });

      test('should validate user cannot block themselves', () {
        final selfBlockJson = Map<String, dynamic>.from(validBlockJson);
        selfBlockJson['blockedId'] = selfBlockJson['blockerId'];

        expect(
          () => BlockModel.fromJson(selfBlockJson),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('cannot block'),
            ),
          ),
        );
      });
    });

    group('toJson', () {
      test('should convert to JSON with timestamp as seconds', () {
        final block = BlockModel.fromJson(validBlockJson);
        final json = block.toJson();

        expect(json['blockerId'], 'user123');
        expect(json['blockedId'], 'user456');
        expect(json['createdAt'], isA<int>());
        expect(json['createdAt'], 1759556000);
      });

      test('should include all required fields in JSON', () {
        final block = BlockModel.fromJson(validBlockJson);
        final json = block.toJson();

        expect(json.containsKey('blockerId'), true);
        expect(json.containsKey('blockedId'), true);
        expect(json.containsKey('createdAt'), true);
      });
    });

    group('copyWith', () {
      test('should create copy with new values', () {
        final original = BlockModel.fromJson(validBlockJson);
        final newDate = DateTime(2025, 10, 5);
        final copied = original.copyWith(createdAt: newDate);

        expect(copied.blockerId, original.blockerId);
        expect(copied.blockedId, original.blockedId);
        expect(copied.createdAt, newDate);
        expect(original.createdAt.day, 4); // Original unchanged
      });

      test('should keep original values when null', () {
        final original = BlockModel.fromJson(validBlockJson);
        final copied = original.copyWith();

        expect(copied.blockerId, original.blockerId);
        expect(copied.blockedId, original.blockedId);
        expect(copied.createdAt, original.createdAt);
      });
    });

    group('helper methods', () {
      test('should generate composite document ID', () {
        final block = BlockModel.fromJson(validBlockJson);
        final docId = block.documentId;

        expect(docId, 'user123_user456');
      });

      test('should check if blocking specific user', () {
        final block = BlockModel.fromJson(validBlockJson);

        expect(block.isBlockingUser('user456'), true);
        expect(block.isBlockingUser('user789'), false);
      });

      test('should check if created by specific user', () {
        final block = BlockModel.fromJson(validBlockJson);

        expect(block.isCreatedBy('user123'), true);
        expect(block.isCreatedBy('user456'), false);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final block1 = BlockModel.fromJson(validBlockJson);
        final block2 = BlockModel.fromJson(validBlockJson);

        expect(block1, equals(block2));
        expect(block1.hashCode, equals(block2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final block1 = BlockModel.fromJson(validBlockJson);
        final differentJson = Map<String, dynamic>.from(validBlockJson);
        differentJson['blockedId'] = 'user789';
        final block2 = BlockModel.fromJson(differentJson);

        expect(block1, isNot(equals(block2)));
        expect(block1.hashCode, isNot(equals(block2.hashCode)));
      });
    });
  });
}
