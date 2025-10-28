import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/chat/screens/group_chat_screen.dart';

/// Widget tests for Group Chat Screen - T023
void main() {
  group('GroupChatScreen Widget', () {
    testWidgets('should display message list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: GroupChatScreen(eventId: 'event123')),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have message input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: GroupChatScreen(eventId: 'event123')),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should have send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: GroupChatScreen(eventId: 'event123')),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
