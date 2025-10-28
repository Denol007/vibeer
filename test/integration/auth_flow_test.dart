import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibe_app/main.dart' as app;

/// Integration test for complete authentication flow - T024
/// Scenario: User installs app → Sign in with Google → Age confirmation → Photo upload → Profile complete
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete registration flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Step 1: Should show login screen
    expect(find.text('Sign in with Google'), findsOneWidget);

    // Step 2: Tap Google sign-in
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    // Step 3: Should navigate to profile setup
    expect(find.text('Complete Your Profile'), findsOneWidget);

    // Step 4: Confirm age (18+)
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Step 5: Upload photo
    await tester.tap(find.text('Upload Photo'));
    await tester.pumpAndSettle();

    // Step 6: Complete profile
    await tester.tap(find.text('Complete Profile'));
    await tester.pumpAndSettle();

    // Step 7: Should navigate to map screen
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
