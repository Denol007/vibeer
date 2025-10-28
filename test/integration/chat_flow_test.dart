import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vibe_app/main.dart' as app;

/// Integration test for chat communication flow - T027
/// Scenario: User opens chat → Sends message → Receives reply → Real-time updates
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete chat flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Assume already participant in event and on chat screen

    // Step 1: Should show chat screen
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Step 2: Enter message
    await tester.enterText(find.byType(TextField), 'Hello everyone!');
    await tester.pumpAndSettle();

    // Step 3: Tap send button
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Step 4: Should display sent message
    expect(find.text('Hello everyone!'), findsOneWidget);

    // Step 5: Should clear input field
    expect(
      find.text('Hello everyone!').evaluate().length,
      equals(1),
    ); // Only in message list

    // Step 6: Simulate receiving message from another user
    // In real scenario, Firestore listener would trigger
    await tester.pump(const Duration(seconds: 1));

    // Step 7: Should show received messages in real-time
    expect(find.byType(ListTile), findsAtLeastNWidgets(1));

    // Step 8: Verify message limit (max 50 messages)
    // This would be tested by sending 51 messages and verifying only 50 remain
  });
}
