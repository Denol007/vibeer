import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/features/safety/services/block_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Firebase implementation of BlockService
class FirebaseBlockService implements BlockService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  FirebaseBlockService({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _firestore = firestore,
        _authService = authService;

  @override
  Future<void> blockUser(String userId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const BlockException('Must be logged in to block users');
      }

      if (currentUser.id == userId) {
        throw const BlockException('Cannot block yourself');
      }

      // Create block document
      final blockDoc = _firestore.collection('blockedUsers').doc();
      await blockDoc.set({
        'blockerId': currentUser.id,
        'blockedUserId': userId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User $userId blocked by ${currentUser.id}');
    } catch (e) {
      if (e is BlockException) {
        rethrow;
      }
      throw BlockException('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const BlockException('Must be logged in to unblock users');
      }

      // Find and delete the block document
      final blockQuery = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: currentUser.id)
          .where('blockedUserId', isEqualTo: userId)
          .get();

      if (blockQuery.docs.isEmpty) {
        throw const BlockException('User is not blocked');
      }

      // Delete all matching block documents (should be only one)
      final batch = _firestore.batch();
      for (final doc in blockQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ User $userId unblocked by ${currentUser.id}');
    } catch (e) {
      if (e is BlockException) {
        rethrow;
      }
      throw BlockException('Failed to unblock user: $e');
    }
  }

  @override
  Stream<List<UserModel>> getBlockedUsers() {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: currentUser.id)
          .orderBy('blockedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        // Get all blocked user IDs
        final blockedUserIds = snapshot.docs
            .map((doc) => doc.data()['blockedUserId'] as String)
            .toList();

        if (blockedUserIds.isEmpty) {
          return <UserModel>[];
        }

        // Fetch user documents for all blocked users
        final userDocs = await Future.wait(
          blockedUserIds.map(
            (userId) => _firestore.collection('users').doc(userId).get(),
          ),
        );

        // Convert to UserModel list
        return userDocs
            .where((doc) => doc.exists)
            .map((doc) => UserModel.fromJson({
                  ...doc.data()!,
                  'id': doc.id,
                }))
            .toList();
      });
    } catch (e) {
      return Stream.error(BlockException('Failed to get blocked users: $e'));
    }
  }

  @override
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return false;
      }

      final blockQuery = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: currentUser.id)
          .where('blockedUserId', isEqualTo: userId)
          .limit(1)
          .get();

      return blockQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if user is blocked: $e');
      return false;
    }
  }

  @override
  Future<bool> isBlockedBy(String userId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return false;
      }

      final blockQuery = await _firestore
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: userId)
          .where('blockedUserId', isEqualTo: currentUser.id)
          .limit(1)
          .get();

      return blockQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if blocked by user: $e');
      return false;
    }
  }
}
