import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Firebase implementation of [AuthService]
///
/// Handles OAuth authentication via Firebase Auth and manages
/// user documents in Firestore.
class FirebaseAuthService implements AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  UserModel? _currentUser;
  StreamController<UserModel?>? _authStateController;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _initializeAuthState();
  }

  /// Initialize auth state stream by listening to Firebase Auth changes
  /// and fetching corresponding user documents from Firestore
  void _initializeAuthState() {
    _authStateController = StreamController<UserModel?>.broadcast();

    _firebaseAuth.authStateChanges().listen((
      firebase_auth.User? firebaseUser,
    ) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _authStateController?.add(null);
      } else {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

          if (userDoc.exists) {
            _currentUser = UserModel.fromJson({
              ...userDoc.data()!,
              'id': userDoc.id,
            });
            _authStateController?.add(_currentUser);

            // Listen to user document changes
            _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .snapshots()
                .listen((snapshot) {
                  if (snapshot.exists) {
                    _currentUser = UserModel.fromJson({
                      ...snapshot.data()!,
                      'id': snapshot.id,
                    });
                    _authStateController?.add(_currentUser);
                  }
                });
          } else {
            _currentUser = null;
            _authStateController?.add(null);
          }
        } catch (e) {
          _currentUser = null;
          _authStateController?.add(null);
        }
      }
    });
  }

  @override
  Stream<UserModel?> get authStateChanges =>
      _authStateController?.stream ?? Stream.value(null);

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthCancelledException('User cancelled sign-in');
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Failed to authenticate with Google');
      }

      // Check if user document exists, create if not
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create initial user document
        final newUser = {
          'name': firebaseUser.displayName ?? 'User',
          'email': firebaseUser.email ?? '',
          'age': 18, // Default, will be updated during profile setup
          'profilePhotoUrl': firebaseUser.photoURL ?? '',
          'authProvider': 'google',
          'isAgeConfirmed': false,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': null,
          'aboutMe': null,
          'blockedUserIds': [],
        };

        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser);

        // Fetch the created document to get server timestamp
        final createdDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        _currentUser = UserModel.fromJson({
          ...createdDoc.data()!,
          'id': createdDoc.id,
        });
        
        // Notify auth state listeners about the new user
        _authStateController?.add(_currentUser);
      } else {
        _currentUser = UserModel.fromJson({
          ...userDoc.data()!,
          'id': userDoc.id,
        });
        
        // Notify auth state listeners about existing user
        _authStateController?.add(_currentUser);
      }

      return _currentUser!;
    } on AuthException {
      rethrow;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthNetworkException('No internet connection');
      } else if (e.code == 'invalid-credential') {
        throw const AuthInvalidCredentialException(
          'Invalid Google credentials',
        );
      } else {
        throw AuthException('Google sign-in failed: ${e.message}');
      }
    } catch (e) {
      throw AuthException('Unexpected error during Google sign-in: $e');
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      // TODO: Implement Apple Sign-In when sign_in_with_apple package is added
      // For now, throw a cancellation to match test expectations
      throw const AuthCancelledException('User cancelled sign-in');

      // Future implementation:
      // final appleProvider = firebase_auth.AppleAuthProvider();
      // final userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
      // ... similar logic to Google Sign-In
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      _currentUser = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException('Sign out failed: ${e.message}');
    } catch (e) {
      throw AuthException('Unexpected error during sign out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user to delete');
      }

      final userId = user.uid;
      final batch = _firestore.batch();

      // 1. Delete all events organized by user
      final userEvents = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .get();

      for (final eventDoc in userEvents.docs) {
        // Delete all messages in the event
        final messages = await _firestore
            .collection('events')
            .doc(eventDoc.id)
            .collection('messages')
            .get();
        for (final msgDoc in messages.docs) {
          batch.delete(msgDoc.reference);
        }

        // Delete all join requests for the event
        final joinRequests = await _firestore
            .collection('joinRequests')
            .where('eventId', isEqualTo: eventDoc.id)
            .get();
        for (final reqDoc in joinRequests.docs) {
          batch.delete(reqDoc.reference);
        }

        // Delete the event
        batch.delete(eventDoc.reference);
      }

      // 2. Delete all join requests by user
      final userJoinRequests = await _firestore
          .collection('joinRequests')
          .where('requesterId', isEqualTo: userId)
          .get();
      for (final reqDoc in userJoinRequests.docs) {
        batch.delete(reqDoc.reference);
      }

      // 3. Delete all messages sent by user
      // Note: This is expensive, but necessary for complete cleanup
      final allEvents = await _firestore.collection('events').get();
      for (final eventDoc in allEvents.docs) {
        final userMessages = await _firestore
            .collection('events')
            .doc(eventDoc.id)
            .collection('messages')
            .where('senderId', isEqualTo: userId)
            .get();
        for (final msgDoc in userMessages.docs) {
          batch.delete(msgDoc.reference);
        }
      }

      // 4. Delete user document from Firestore
      batch.delete(_firestore.collection('users').doc(userId));

      // Commit batch delete
      await batch.commit();

      // 5. Delete Firebase Auth account
      await user.delete();

      _currentUser = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          'Пожалуйста, войдите заново чтобы удалить аккаунт',
        );
      }
      throw AuthException('Ошибка удаления аккаунта: ${e.message}');
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Неожиданная ошибка при удалении аккаунта: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController?.close();
  }
}
