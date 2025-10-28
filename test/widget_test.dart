// Basic smoke test for Vibe app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/app.dart';

void main() {
  testWidgets('Vibe app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: VibeApp()));
    await tester.pumpAndSettle();

    // Verify that our app loads and shows a placeholder (splash screen)
    // The app should navigate to /splash initially
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
