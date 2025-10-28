import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/events/screens/create_event_screen.dart';

/// Widget tests for Create Event Screen - T021
void main() {
  group('CreateEventScreen Widget', () {
    testWidgets('should have all required fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CreateEventScreen())),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Participants'), findsOneWidget);
    });

    testWidgets('should validate participants count (1-5)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CreateEventScreen())),
      );

      await tester.enterText(find.byKey(const Key('participants')), '6');
      await tester.tap(find.text('Create Event'));
      await tester.pump();

      expect(find.text('Max 5 participants'), findsOneWidget);
    });
  });
}
