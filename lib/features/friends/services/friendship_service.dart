import '../models/friend_request_model.dart';
import '../../profile/models/user_model.dart';

/// Abstract interface for friendship service
abstract class FriendshipService {
  /// Send friend request to another user
  Future<void> sendFriendRequest(String receiverId);

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId);

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId);

  /// Remove friend (unfriend)
  Future<void> removeFriend(String friendId);

  /// Get stream of incoming friend requests (requests sent to current user)
  Stream<List<FriendRequestModel>> getIncomingRequests();

  /// Get stream of outgoing friend requests (requests sent by current user)
  Stream<List<FriendRequestModel>> getOutgoingRequests();

  /// Get stream of friends (accepted friend requests)
  Stream<List<UserModel>> getFriends();

  /// Check friendship status with another user
  /// Returns: null (no request), 'pending_sent', 'pending_received', 'friends'
  Future<String?> checkFriendshipStatus(String userId);

  /// Check if user is friend
  Future<bool> isFriend(String userId);
}

/// Exceptions
class FriendshipException implements Exception {
  final String message;
  const FriendshipException(this.message);
  
  @override
  String toString() => 'FriendshipException: $message';
}

class DuplicateRequestException extends FriendshipException {
  const DuplicateRequestException(super.message);
}

class SelfFriendException extends FriendshipException {
  const SelfFriendException(super.message);
}

class RequestNotFoundException extends FriendshipException {
  const RequestNotFoundException(super.message);
}
