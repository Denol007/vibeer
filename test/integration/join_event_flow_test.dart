import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vibe_app/main.dart' as app;

/// Integration test for join event flow - T026
/// Scenario: User finds event → Views details → Sends request → Organizer approves → Access chat
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete join event flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Assume already logged in and on map screen with visible events

    // Step 1: Tap event marker on map
    await tester.tap(find.byKey(const Key('event_marker_1')));
    await tester.pumpAndSettle();

    // Step 2: Should show event detail screen
    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('Organizer'), findsOneWidget);

    // Step 3: Tap "Want to join!" button
    await tester.tap(find.text('Want to join!'));
    await tester.pumpAndSettle();

    // Step 4: Should show confirmation dialog
    expect(find.text('Request sent!'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Step 5: Simulate organizer approval (via background notification)
    // In real scenario, another user would approve
    // For test, we'll simulate the state change

    // Step 6: Should now show "Open Chat" button
    expect(find.text('Open Chat'), findsOneWidget);

    // Step 7: Tap "Open Chat"
    await tester.tap(find.text('Open Chat'));
    await tester.pumpAndSettle();

    // Step 8: Should navigate to group chat
    expect(find.byType(TextField), findsOneWidget); // Message input
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
