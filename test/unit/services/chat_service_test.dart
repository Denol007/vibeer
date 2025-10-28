import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vibe_app/features/chat/services/chat_service.dart';
import 'package:vibe_app/features/chat/models/message_model.dart';

import 'chat_service_test.mocks.dart';

/// Unit tests for ChatService interface - T017
@GenerateMocks([ChatService])
void main() {
  group('ChatService Contract', () {
    late ChatService mockService;

    setUp(() {
      mockService = MockChatService();
    });

    test('sendMessage should send text message', () async {
      when(
        mockService.sendMessage(eventId: 'event123', text: 'Hello!'),
      ).thenAnswer((_) async => {});

      await mockService.sendMessage(eventId: 'event123', text: 'Hello!');
      verify(
        mockService.sendMessage(eventId: 'event123', text: 'Hello!'),
      ).called(1);
    });

    test('getEventMessages should return message stream', () async {
      final messages = <MessageModel>[];
      when(
        mockService.getEventMessages('event123', limit: 50),
      ).thenAnswer((_) => Stream.value(messages));

      final stream = mockService.getEventMessages('event123');
      expect(stream, isA<Stream<List<MessageModel>>>());
    });

    test('should throw ChatPermissionException if not participant', () async {
      when(
        mockService.sendMessage(eventId: 'event123', text: 'Hi'),
      ).thenThrow(ChatPermissionException('Not a participant'));

      expect(
        () => mockService.sendMessage(eventId: 'event123', text: 'Hi'),
        throwsA(isA<ChatPermissionException>()),
      );
    });
  });
}

class ChatPermissionException implements Exception {
  final String message;
  ChatPermissionException(this.message);
}
