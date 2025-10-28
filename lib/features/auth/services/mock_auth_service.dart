import 'dart:async';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Mock AuthService for testing without Firebase
///
/// This allows you to test the app without setting up Firebase.
/// Replace with FirebaseAuthService once Firebase is configured.
class MockAuthService implements AuthService {
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create a mock user
    _currentUser = UserModel(
      id: 'mock-user-123',
      name: 'Test User',
      email: 'test@example.com',
      age: 22,
      profilePhotoUrl: 'https://via.placeholder.com/150',
      authProvider: 'google',
      isAgeConfirmed: true,
      createdAt: DateTime.now(),
      aboutMe: 'Mock user for testing',
      blockedUserIds: const [],
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(
      id: 'mock-user-456',
      name: 'Apple Test User',
      email: 'apple@example.com',
      age: 23,
      profilePhotoUrl: 'https://via.placeholder.com/150',
      authProvider: 'apple',
      isAgeConfirmed: true,
      createdAt: DateTime.now(),
      aboutMe: 'Mock Apple user for testing',
      blockedUserIds: const [],
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
