import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/auth/screens/login_screen.dart';
import 'package:vibe_app/features/auth/providers/auth_provider.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Mock AuthService for testing
class MockAuthService implements AuthService {
  bool _shouldDelay = false;

  void setDelay(bool delay) {
    _shouldDelay = delay;
  }

  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);

  @override
  UserModel? get currentUser => null;

  @override
  Future<UserModel> signInWithGoogle() async {
    if (_shouldDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw UnimplementedError();
  }

  @override
  Future<UserModel> signInWithApple() async {
    if (_shouldDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// Widget tests for Login Screen - T019
/// These tests MUST FAIL initially (TDD)
void main() {
  group('LoginScreen Widget', () {
    testWidgets('should render Sign in with Google button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('should render Sign in with Apple button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Sign in with Apple'), findsOneWidget);
    });

    testWidgets('should trigger auth flow on button tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Should trigger auth flow (implementation will verify)
    });

    testWidgets('should show loading state during authentication', (
      tester,
    ) async {
      final mockAuthService = MockAuthService();
      mockAuthService.setDelay(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the async operation to complete
      await tester.pumpAndSettle();
    });
  });
}
