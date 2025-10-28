import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/auth/screens/profile_setup_screen.dart';

/// Widget tests for Profile Setup Screen - T020
void main() {
  group('ProfileSetupScreen Widget', () {
    testWidgets('should require age confirmation checkbox', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ProfileSetupScreen())),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('I confirm I am 18+'), findsOneWidget);
    });

    testWidgets('should require profile photo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ProfileSetupScreen())),
      );

      expect(find.text('Upload Photo'), findsOneWidget);
    });

    testWidgets('should validate age (≥18)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ProfileSetupScreen())),
      );

      await tester.enterText(find.byType(TextField).first, '17');
      await tester.tap(find.text('Complete Profile'));
      await tester.pump();

      expect(find.text('Must be 18 or older'), findsOneWidget);
    });
  });
}
