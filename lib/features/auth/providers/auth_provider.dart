import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
// import 'package:vibe_app/features/auth/services/mock_auth_service.dart';
import 'package:vibe_app/features/auth/services/firebase_auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Provider for AuthService instance
///
/// Uses FirebaseAuthService for real authentication with Firebase.
/// For testing without Firebase, switch to MockAuthService.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
  // For testing without Firebase:
  // return MockAuthService();
});

/// Provider for authentication state changes
///
/// Streams authentication state changes from [AuthService].
/// Emits [UserModel] when user is signed in, null when signed out.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (user) => user != null ? HomeScreen() : LoginScreen(),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => ErrorWidget(),
/// );
/// ```
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user
///
/// Provides synchronous access to the currently authenticated user.
/// Returns null if no user is signed in.
///
/// Usage:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// if (user != null) {
///   Text('Hello, ${user.name}');
/// }
/// ```
final currentUserProvider = Provider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});
