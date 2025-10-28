import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibe_app/main.dart' as app;

/// Integration test for event creation flow - T025
/// Scenario: User creates event → Fills form → Selects location → Sets time → Publishes → Appears on map
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete event creation flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Assume already logged in and on map screen

    // Step 1: Tap create event button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Step 2: Should show create event form
    expect(find.text('Create Event'), findsOneWidget);

    // Step 3: Fill required fields
    await tester.enterText(find.byKey(const Key('title')), 'Test Event');
    await tester.enterText(
      find.byKey(const Key('description')),
      'Test Description',
    );
    await tester.enterText(find.byKey(const Key('participants')), '3');

    // Step 4: Select location on map
    await tester.tap(find.text('Select Location'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 300)); // Tap map
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Step 5: Set time (within 24 hours)
    await tester.tap(find.text('Select Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Step 6: Submit event
    await tester.tap(find.text('Create Event'));
    await tester.pumpAndSettle();

    // Step 7: Should navigate back to map with event marker
    expect(find.byType(GoogleMap), findsOneWidget);
    expect(find.text('Test Event'), findsOneWidget);
  });
}
