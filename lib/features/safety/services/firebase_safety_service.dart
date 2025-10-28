import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/safety/services/safety_service.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';

/// Firebase implementation of SafetyService
///
/// Manages user blocking and reporting functionality using Firestore.
class FirebaseSafetyService implements SafetyService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseSafetyService({
    required AuthService authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<String>> getBlockedUsers() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get();

      if (!userDoc.exists) {
        return [];
      }

      final data = userDoc.data();
      final blockedUsers = data?['blockedUsers'] as List<dynamic>?;
      return blockedUsers?.cast<String>() ?? [];
    } catch (e) {
      throw SafetyException('Failed to get blocked users: $e');
    }
  }

  @override
  Future<void> blockUser(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const SafetyException('Must be logged in to block users');
    }

    if (userId == currentUser.id) {
      throw const BlockSelfException('Cannot block yourself');
    }

    try {
      await _firestore.collection('users').doc(currentUser.id).update({
        'blockedUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw SafetyException('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const SafetyException('Must be logged in to unblock users');
    }

    try {
      await _firestore.collection('users').doc(currentUser.id).update({
        'blockedUsers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw SafetyException('Failed to unblock user: $e');
    }
  }

  @override
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final blockedUsers = await getBlockedUsers();
      return blockedUsers.contains(userId);
    } catch (e) {
      // If error checking, assume not blocked to avoid false positives
      return false;
    }
  }

  @override
  Future<void> reportUser({
    required String userId,
    required String reason,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const SafetyException('Must be logged in to report users');
    }

    if (reason.trim().isEmpty) {
      throw const ReportValidationException('Report reason cannot be empty');
    }

    if (reason.length > 500) {
      throw const ReportValidationException(
        'Report reason must be less than 500 characters',
      );
    }

    if (userId == currentUser.id) {
      throw const ReportValidationException('Cannot report yourself');
    }

    try {
      await _firestore.collection('reports').add({
        'type': 'user',
        'reportedId': userId,
        'reporterId': currentUser.id,
        'reporterName': currentUser.name,
        'reason': reason.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw SafetyException('Failed to report user: $e');
    }
  }

  @override
  Future<void> reportEvent({
    required String eventId,
    required String reason,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const SafetyException('Must be logged in to report events');
    }

    if (reason.trim().isEmpty) {
      throw const ReportValidationException('Report reason cannot be empty');
    }

    if (reason.length > 500) {
      throw const ReportValidationException(
        'Report reason must be less than 500 characters',
      );
    }

    try {
      await _firestore.collection('reports').add({
        'type': 'event',
        'reportedId': eventId,
        'reporterId': currentUser.id,
        'reporterName': currentUser.name,
        'reason': reason.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw SafetyException('Failed to report event: $e');
    }
  }
}
