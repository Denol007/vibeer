import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../auth/services/auth_service.dart';
import '../../profile/models/user_model.dart';
import '../../profile/services/profile_service.dart';
import '../models/friend_request_model.dart';
import 'friendship_service.dart';

/// Firebase implementation of FriendshipService
class FirebaseFriendshipService implements FriendshipService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final ProfileService _profileService;
  final Uuid _uuid = const Uuid();

  FirebaseFriendshipService({
    required FirebaseFirestore firestore,
    required AuthService authService,
    required ProfileService profileService,
  })  : _firestore = firestore,
        _authService = authService,
        _profileService = profileService;

  @override
  Future<void> sendFriendRequest(String receiverId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const FriendshipException('Must be logged in to send friend requests');
    }

    if (currentUser.id == receiverId) {
      throw const SelfFriendException('Cannot send friend request to yourself');
    }

    // Check if request already exists
    final existingRequest = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUser.id)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw const DuplicateRequestException('Friend request already sent');
    }

    // Check if reverse request exists
    final reverseRequest = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: currentUser.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (reverseRequest.docs.isNotEmpty) {
      throw const DuplicateRequestException('This user has already sent you a friend request');
    }

    // Check if already friends
    final alreadyFriends = await isFriend(receiverId);
    if (alreadyFriends) {
      throw const FriendshipException('Already friends with this user');
    }

    // Get receiver profile
    final receiverProfile = await _profileService.getProfile(receiverId);
    if (receiverProfile == null) {
      throw const FriendshipException('User not found');
    }

    // Create friend request
    final requestId = _uuid.v4();
    final request = FriendRequestModel(
      id: requestId,
      senderId: currentUser.id,
      receiverId: receiverId,
      senderName: currentUser.name,
      senderPhotoUrl: currentUser.profilePhotoUrl,
      receiverName: receiverProfile.name,
      receiverPhotoUrl: receiverProfile.profilePhotoUrl,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .set(request.toJson());

    print('✅ Friend request sent to $receiverId');
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const FriendshipException('Must be logged in');
    }

    // Get request
    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw const RequestNotFoundException('Friend request not found');
    }

    final request = FriendRequestModel.fromJson({
      ...requestDoc.data()!,
      'id': requestDoc.id,
    });

    // Verify receiver
    if (request.receiverId != currentUser.id) {
      throw const FriendshipException('Not authorized to accept this request');
    }

    // Update request status
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Create friendship document
    final friendshipId = _uuid.v4();
    await _firestore.collection('friendships').doc(friendshipId).set({
      'id': friendshipId,
      'user1Id': request.senderId,
      'user2Id': request.receiverId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Friend request accepted: $requestId');
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const FriendshipException('Must be logged in');
    }

    // Get request
    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw const RequestNotFoundException('Friend request not found');
    }

    final request = FriendRequestModel.fromJson({
      ...requestDoc.data()!,
      'id': requestDoc.id,
    });

    // Verify receiver
    if (request.receiverId != currentUser.id) {
      throw const FriendshipException('Not authorized to decline this request');
    }

    // Update request status
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Friend request declined: $requestId');
  }

  @override
  Future<void> removeFriend(String friendId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw const FriendshipException('Must be logged in');
    }

    // Find friendship document
    final friendshipQuery = await _firestore
        .collection('friendships')
        .where('user1Id', whereIn: [currentUser.id, friendId])
        .get();

    final friendship = friendshipQuery.docs.firstWhere(
      (doc) {
        final data = doc.data();
        return (data['user1Id'] == currentUser.id && data['user2Id'] == friendId) ||
               (data['user1Id'] == friendId && data['user2Id'] == currentUser.id);
      },
      orElse: () => throw const FriendshipException('Friendship not found'),
    );

    // Delete friendship
    await _firestore.collection('friendships').doc(friendship.id).delete();

    print('✅ Removed friend: $friendId');
  }

  @override
  Stream<List<FriendRequestModel>> getIncomingRequests() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUser.id)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendRequestModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  @override
  Stream<List<FriendRequestModel>> getOutgoingRequests() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUser.id)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendRequestModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  @override
  Stream<List<UserModel>> getFriends() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendships')
        .where('user1Id', whereIn: [currentUser.id])
        .snapshots()
        .asyncMap((snapshot) async {
      // Get all friend IDs
      final friendIds = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['user1Id'] == currentUser.id) {
          friendIds.add(data['user2Id'] as String);
        } else {
          friendIds.add(data['user1Id'] as String);
        }
      }

      // Also check where current user is user2
      final reverseQuery = await _firestore
          .collection('friendships')
          .where('user2Id', isEqualTo: currentUser.id)
          .get();

      for (final doc in reverseQuery.docs) {
        final data = doc.data();
        friendIds.add(data['user1Id'] as String);
      }

      if (friendIds.isEmpty) {
        return <UserModel>[];
      }

      // Fetch user profiles
      final friends = <UserModel>[];
      for (final friendId in friendIds) {
        final profile = await _profileService.getProfile(friendId);
        if (profile != null) {
          friends.add(profile);
        }
      }

      return friends;
    });
  }

  @override
  Future<String?> checkFriendshipStatus(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    // Check if friends
    if (await isFriend(userId)) {
      return 'friends';
    }

    // Check for pending request sent by current user
    final outgoing = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUser.id)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (outgoing.docs.isNotEmpty) {
      return 'pending_sent';
    }

    // Check for pending request from other user
    final incoming = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .where('receiverId', isEqualTo: currentUser.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (incoming.docs.isNotEmpty) {
      return 'pending_received';
    }

    return null;
  }

  @override
  Future<bool> isFriend(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    // Check friendships where current user is user1
    final query1 = await _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: currentUser.id)
        .where('user2Id', isEqualTo: userId)
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) return true;

    // Check friendships where current user is user2
    final query2 = await _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .where('user2Id', isEqualTo: currentUser.id)
        .limit(1)
        .get();

    return query2.docs.isNotEmpty;
  }
}
