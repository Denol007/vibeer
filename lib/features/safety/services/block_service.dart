import 'package:vibe_app/features/profile/models/user_model.dart';

/// Abstract interface for user blocking service
///
/// Handles blocking and unblocking users to prevent unwanted interactions.
abstract class BlockService {
  /// Block a user
  ///
  /// Prevents the blocked user from:
  /// - Seeing your events
  /// - Sending you join requests
  /// - Messaging you
  ///
  /// Throws [BlockException] if operation fails.
  Future<void> blockUser(String userId);

  /// Unblock a user
  ///
  /// Restores normal interaction with the user.
  ///
  /// Throws [BlockException] if operation fails.
  Future<void> unblockUser(String userId);

  /// Stream of all users blocked by current user
  ///
  /// Returns empty stream if not authenticated.
  Stream<List<UserModel>> getBlockedUsers();

  /// Check if a specific user is blocked by current user
  ///
  /// Returns false if not authenticated.
  Future<bool> isUserBlocked(String userId);

  /// Check if current user is blocked by another user
  ///
  /// Returns false if not authenticated.
  Future<bool> isBlockedBy(String userId);
}

/// Exception thrown by BlockService
class BlockException implements Exception {
  final String message;

  const BlockException(this.message);

  @override
  String toString() => 'BlockException: $message';
}
