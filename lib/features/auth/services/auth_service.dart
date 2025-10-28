import 'package:vibe_app/features/profile/models/user_model.dart';

/// Abstract interface for authentication service
///
/// Handles user authentication via OAuth providers (Google, Apple)
/// and manages authentication state throughout the app.
abstract class AuthService {
  /// Stream of authentication state changes
  ///
  /// Emits [UserModel] when user is authenticated, null when signed out.
  /// Listens to both Firebase Auth state and Firestore user document changes.
  Stream<UserModel?> get authStateChanges;

  /// Currently authenticated user (nullable)
  ///
  /// Returns cached [UserModel] if user is signed in, null otherwise.
  UserModel? get currentUser;

  /// Sign in with Google OAuth
  ///
  /// Opens Google Sign-In flow, authenticates with Firebase,
  /// then fetches or creates user document in Firestore.
  ///
  /// Returns [UserModel] on success.
  /// Throws [AuthCancelledException] if user cancels the flow.
  /// Throws [AuthNetworkException] on network errors.
  /// Throws [AuthInvalidCredentialException] on invalid credentials.
  Future<UserModel> signInWithGoogle();

  /// Sign in with Apple ID
  ///
  /// Opens Apple Sign-In flow, authenticates with Firebase,
  /// then fetches or creates user document in Firestore.
  ///
  /// Returns [UserModel] on success.
  /// Throws [AuthCancelledException] if user cancels the flow.
  /// Throws [AuthException] on other errors.
  Future<UserModel> signInWithApple();

  /// Sign out current user
  ///
  /// Signs out from Firebase Auth and clears cached user data.
  /// Throws [AuthException] if sign out fails.
  Future<void> signOut();

  /// Delete current user account and all associated data
  ///
  /// Deletes Firebase Auth account, triggers Cloud Function to clean up
  /// user data (profile, events, messages, etc.).
  ///
  /// Throws [AuthException] if no user is authenticated or deletion fails.
  Future<void> deleteAccount();
}

/// Base authentication exception
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// User cancelled OAuth flow
class AuthCancelledException extends AuthException {
  const AuthCancelledException(super.message);

  @override
  String toString() => 'AuthCancelledException: $message';
}

/// Network error during authentication
class AuthNetworkException extends AuthException {
  const AuthNetworkException(super.message);

  @override
  String toString() => 'AuthNetworkException: $message';
}

/// Invalid credentials provided
class AuthInvalidCredentialException extends AuthException {
  const AuthInvalidCredentialException(super.message);

  @override
  String toString() => 'AuthInvalidCredentialException: $message';
}
