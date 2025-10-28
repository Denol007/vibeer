import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/user_model.dart';
import '../models/friend_request_model.dart';
import '../services/friendship_service.dart';
import '../services/firebase_friendship_service.dart';

/// Provider for FriendshipService instance
final friendshipServiceProvider = Provider<FriendshipService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final profileService = ref.watch(profileServiceProvider);
  
  return FirebaseFriendshipService(
    firestore: FirebaseFirestore.instance,
    authService: authService,
    profileService: profileService,
  );
});

/// Provider for incoming friend requests stream
final incomingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final friendshipService = ref.watch(friendshipServiceProvider);
  return friendshipService.getIncomingRequests();
});

/// Provider for outgoing friend requests stream
final outgoingFriendRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final friendshipService = ref.watch(friendshipServiceProvider);
  return friendshipService.getOutgoingRequests();
});

/// Provider for friends list stream
final friendsListProvider = StreamProvider<List<UserModel>>((ref) {
  final friendshipService = ref.watch(friendshipServiceProvider);
  return friendshipService.getFriends();
});

/// Provider to check friendship status with specific user
final friendshipStatusProvider = FutureProvider.family<String?, String>((ref, userId) {
  final friendshipService = ref.watch(friendshipServiceProvider);
  return friendshipService.checkFriendshipStatus(userId);
});

/// Provider to check if user is friend
final isFriendProvider = FutureProvider.family<bool, String>((ref, userId) {
  final friendshipService = ref.watch(friendshipServiceProvider);
  return friendshipService.isFriend(userId);
});
