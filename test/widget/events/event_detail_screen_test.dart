import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/events/screens/event_detail_screen.dart';

/// Widget tests for Event Detail Screen - T022
void main() {
  group('EventDetailScreen Widget', () {
    testWidgets('should display organizer info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: EventDetailScreen(eventId: 'event123')),
        ),
      );

      expect(find.text('Organizer'), findsOneWidget);
    });

    testWidgets('should show "Want to join!" button for participants', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: EventDetailScreen(eventId: 'event123')),
        ),
      );

      expect(find.text('Want to join!'), findsOneWidget);
    });

    testWidgets('should display capacity (current/needed)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: EventDetailScreen(eventId: 'event123')),
        ),
      );

      expect(find.textContaining('/'), findsOneWidget); // "3/5" format
    });
  });
}
