import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_app/features/chat/models/message_model.dart';

/// Unit tests for MessageModel
///
/// These tests MUST FAIL initially as part of TDD workflow.
/// Implementation will be done in Phase 3.3 (T028-T032).
void main() {
  group('MessageModel', () {
    // Test data
    final validMessageJson = {
      'id': 'msg001',
      'senderId': 'user456',
      'senderName': 'Alex Ivanov',
      'senderPhotoUrl': 'https://storage.googleapis.com/vibe-app/user456.jpg',
      'text': 'Hi everyone! Looking forward to tonight!',
      'timestamp': 1728010500,
      'isSystemMessage': false,
    };

    final systemMessageJson = {
      'id': 'msg002',
      'senderId': 'system',
      'senderName': 'System',
      'senderPhotoUrl': '',
      'text': 'Marina Petrova joined the chat',
      'timestamp': 1728010600,
      'isSystemMessage': true,
    };

    group('fromJson', () {
      test('should create MessageModel from valid JSON', () {
        final message = MessageModel.fromJson(validMessageJson);

        expect(message.id, 'msg001');
        expect(message.senderId, 'user456');
        expect(message.senderName, 'Alex Ivanov');
        expect(message.senderPhotoUrl, validMessageJson['senderPhotoUrl']);
        expect(message.text, 'Hi everyone! Looking forward to tonight!');
        expect(message.timestamp, isNotNull);
        expect(message.isSystemMessage, false);
      });

      test('should create system message from JSON', () {
        final message = MessageModel.fromJson(systemMessageJson);

        expect(message.isSystemMessage, true);
        expect(message.senderId, 'system');
        expect(message.text, contains('joined the chat'));
      });

      test('should handle missing optional isSystemMessage', () {
        final jsonWithoutFlag = {...validMessageJson};
        jsonWithoutFlag.remove('isSystemMessage');

        final message = MessageModel.fromJson(jsonWithoutFlag);

        expect(message.isSystemMessage, false); // Default value
      });

      test('should throw when required field is missing', () {
        final invalidJson = {...validMessageJson};
        invalidJson.remove('text');

        expect(
          () => MessageModel.fromJson(invalidJson),
          throwsA(isA<Exception>()),
        );
      });

      test('should parse timestamp correctly', () {
        final message = MessageModel.fromJson(validMessageJson);

        expect(message.timestamp, isA<DateTime>());
        expect(message.timestamp.millisecondsSinceEpoch, greaterThan(0));
      });
    });

    group('toJson', () {
      test('should convert MessageModel to JSON', () {
        final message = MessageModel.fromJson(validMessageJson);
        final json = message.toJson();

        expect(json['id'], 'msg001');
        expect(json['senderId'], 'user456');
        expect(json['senderName'], 'Alex Ivanov');
        expect(json['text'], 'Hi everyone! Looking forward to tonight!');
        expect(json['isSystemMessage'], false);
      });

      test('should include timestamp in JSON', () {
        final message = MessageModel.fromJson(validMessageJson);
        final json = message.toJson();

        expect(json['timestamp'], isNotNull);
        expect(json['timestamp'], isA<int>());
      });

      test('should include system message flag in JSON', () {
        final message = MessageModel.fromJson(systemMessageJson);
        final json = message.toJson();

        expect(json['isSystemMessage'], true);
      });

      test('should include denormalized sender data', () {
        final message = MessageModel.fromJson(validMessageJson);
        final json = message.toJson();

        expect(json['senderName'], isNotEmpty);
        expect(json['senderPhotoUrl'], isNotEmpty);
      });
    });

    group('validation', () {
      test('should validate text is not empty', () {
        final emptyTextJson = {...validMessageJson, 'text': ''};

        expect(
          () => MessageModel.fromJson(emptyTextJson),
          throwsA(predicate((e) => e.toString().contains('text'))),
        );
      });

      test('should validate text length (max 1000 chars)', () {
        final longText = 'a' * 1001;
        final invalidJson = {...validMessageJson, 'text': longText};

        expect(
          () => MessageModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('text') ||
                  e.toString().contains('1000'),
            ),
          ),
        );
      });

      test('should accept maximum valid text length', () {
        final maxText = 'a' * 1000;
        final json = {...validMessageJson, 'text': maxText};

        final message = MessageModel.fromJson(json);
        expect(message.text.length, 1000);
      });

      test('should validate senderId is not empty', () {
        final invalidJson = {...validMessageJson, 'senderId': ''};

        expect(
          () => MessageModel.fromJson(invalidJson),
          throwsA(predicate((e) => e.toString().contains('sender'))),
        );
      });

      test('should validate senderName is not empty for regular messages', () {
        final invalidJson = {...validMessageJson, 'senderName': ''};

        expect(
          () => MessageModel.fromJson(invalidJson),
          throwsA(predicate((e) => e.toString().contains('name'))),
        );
      });

      test('should validate timestamp is in the past', () {
        final futureTime =
            DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final invalidJson = {...validMessageJson, 'timestamp': futureTime};

        expect(
          () => MessageModel.fromJson(invalidJson),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('timestamp') ||
                  e.toString().contains('future'),
            ),
          ),
        );
      });
    });

    group('system messages', () {
      test('should create system message for user joined', () {
        final message = MessageModel.createSystemMessage(
          id: 'msg999',
          text: 'Marina Petrova joined the chat',
        );

        expect(message.isSystemMessage, true);
        expect(message.senderId, 'system');
        expect(message.text, contains('joined'));
      });

      test('should create system message for user left', () {
        final message = MessageModel.createSystemMessage(
          id: 'msg1000',
          text: 'Alex Ivanov left the chat',
        );

        expect(message.isSystemMessage, true);
        expect(message.text, contains('left'));
      });

      test('should create system message for event update', () {
        final message = MessageModel.createSystemMessage(
          id: 'msg1001',
          text: 'Event time updated',
        );

        expect(message.isSystemMessage, true);
        expect(message.text, contains('updated'));
      });

      test('should have system as senderId for system messages', () {
        final message = MessageModel.fromJson(systemMessageJson);

        expect(message.senderId, 'system');
        expect(message.isSystemMessage, true);
      });
    });

    group('helper methods', () {
      test('should check if message is from specific user', () {
        final message = MessageModel.fromJson(validMessageJson);

        expect(message.isFromUser('user456'), true);
        expect(message.isFromUser('user999'), false);
      });

      test('should check if message is a system message', () {
        final userMessage = MessageModel.fromJson(validMessageJson);
        final systemMessage = MessageModel.fromJson(systemMessageJson);

        expect(userMessage.isSystem, false);
        expect(systemMessage.isSystem, true);
      });

      test('should get time ago string', () {
        final message = MessageModel.fromJson(validMessageJson);
        final timeAgo = message.timeAgo;

        expect(timeAgo, isNotNull);
        expect(timeAgo, isA<String>());
      });

      test('should get formatted timestamp', () {
        final message = MessageModel.fromJson(validMessageJson);
        final formatted = message.formattedTime;

        expect(formatted, isNotNull);
        expect(formatted, isA<String>());
        expect(formatted, isNotEmpty);
      });

      test('should check if message is recent (within 5 minutes)', () {
        final recentTime =
            DateTime.now()
                .subtract(const Duration(minutes: 3))
                .millisecondsSinceEpoch ~/
            1000;
        final recentJson = {...validMessageJson, 'timestamp': recentTime};
        final message = MessageModel.fromJson(recentJson);

        expect(message.isRecent, true);
      });

      test('should check if message is not recent (older than 5 minutes)', () {
        final message = MessageModel.fromJson(validMessageJson);

        expect(message.isRecent, false); // Test data is old
      });

      test('should get message preview (truncated text)', () {
        final longText =
            'This is a very long message that should be truncated' * 10;
        final json = {...validMessageJson, 'text': longText.substring(0, 500)};
        final message = MessageModel.fromJson(json);
        final preview = message.preview(maxLength: 50);

        expect(preview.length, lessThanOrEqualTo(53)); // 50 + "..."
        expect(preview, endsWith('...'));
      });

      test('should not truncate short message preview', () {
        final message = MessageModel.fromJson(validMessageJson);
        final preview = message.preview(maxLength: 100);

        expect(preview, message.text);
        expect(preview, isNot(endsWith('...')));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final message1 = MessageModel.fromJson(validMessageJson);
        final message2 = MessageModel.fromJson(validMessageJson);

        expect(message1, equals(message2));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('should not be equal when id differs', () {
        final message1 = MessageModel.fromJson(validMessageJson);
        final json2 = {...validMessageJson, 'id': 'different-id'};
        final message2 = MessageModel.fromJson(json2);

        expect(message1, isNot(equals(message2)));
      });

      test('should not be equal when text differs', () {
        final message1 = MessageModel.fromJson(validMessageJson);
        final json2 = {...validMessageJson, 'text': 'Different text'};
        final message2 = MessageModel.fromJson(json2);

        expect(message1, isNot(equals(message2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final message = MessageModel.fromJson(validMessageJson);
        final updated = message.copyWith(text: 'Updated message text');

        expect(updated.id, message.id);
        expect(updated.text, 'Updated message text');
        expect(updated.senderId, message.senderId);
        expect(updated.timestamp, message.timestamp);
      });

      test('should not modify original when using copyWith', () {
        final message = MessageModel.fromJson(validMessageJson);
        final originalText = message.text;

        message.copyWith(text: 'New text');

        expect(message.text, originalText);
      });
    });

    group('sorting', () {
      test('should sort messages by timestamp ascending', () {
        final message1 = MessageModel.fromJson({
          ...validMessageJson,
          'timestamp': 1728010500,
        });
        final message2 = MessageModel.fromJson({
          ...validMessageJson,
          'id': 'msg002',
          'timestamp': 1728010600,
        });
        final message3 = MessageModel.fromJson({
          ...validMessageJson,
          'id': 'msg003',
          'timestamp': 1728010400,
        });

        final messages = [message2, message1, message3];
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        expect(messages[0].id, 'msg003');
        expect(messages[1].id, 'msg001');
        expect(messages[2].id, 'msg002');
      });

      test('should compare messages by timestamp', () {
        final earlier = MessageModel.fromJson({
          ...validMessageJson,
          'timestamp': 1728010500,
        });
        final later = MessageModel.fromJson({
          ...validMessageJson,
          'id': 'msg002',
          'timestamp': 1728010600,
        });

        expect(earlier.isBefore(later), true);
        expect(later.isAfter(earlier), true);
      });
    });

    group('edge cases', () {
      test('should handle single character message', () {
        final json = {...validMessageJson, 'text': 'a'};
        final message = MessageModel.fromJson(json);

        expect(message.text, 'a');
      });

      test('should handle message with special characters', () {
        final specialText = '😀 Hello! @user #event 👍🏻 https://example.com';
        final json = {...validMessageJson, 'text': specialText};
        final message = MessageModel.fromJson(json);

        expect(message.text, specialText);
      });

      test('should handle message with newlines', () {
        final multilineText = 'Line 1\nLine 2\nLine 3';
        final json = {...validMessageJson, 'text': multilineText};
        final message = MessageModel.fromJson(json);

        expect(message.text, contains('\n'));
        expect(message.text.split('\n').length, 3);
      });

      test('should trim whitespace from text', () {
        final json = {...validMessageJson, 'text': '  Hello  '};
        final message = MessageModel.fromJson(json);

        expect(message.text, 'Hello');
      });
    });
  });
}
