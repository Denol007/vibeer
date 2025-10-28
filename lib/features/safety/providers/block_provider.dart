import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/features/auth/providers/auth_provider.dart';
import 'package:vibe_app/features/safety/services/block_service.dart';
import 'package:vibe_app/features/safety/services/firebase_block_service.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';

/// Provider for BlockService instance
final blockServiceProvider = Provider<BlockService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseBlockService(
    firestore: FirebaseFirestore.instance,
    authService: authService,
  );
});

/// Provider for stream of blocked users
final blockedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final blockService = ref.watch(blockServiceProvider);
  return blockService.getBlockedUsers();
});

/// Provider to check if a specific user is blocked
final isUserBlockedProvider = FutureProvider.family<bool, String>((ref, userId) {
  final blockService = ref.watch(blockServiceProvider);
  return blockService.isUserBlocked(userId);
});

/// Provider to check if current user is blocked by another user
final isBlockedByProvider = FutureProvider.family<bool, String>((ref, userId) {
  final blockService = ref.watch(blockServiceProvider);
  return blockService.isBlockedBy(userId);
});
