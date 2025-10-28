import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/events_service.dart';
import '../services/firebase_events_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/event_model.dart';
import '../../../core/utils/app_logger.dart';

/// Provider for EventsService instance
///
/// Creates and provides a singleton instance of [FirebaseEventsService]
/// for dependency injection throughout the app.
final eventsServiceProvider = Provider<EventsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseEventsService(authService: authService);
});

/// Provider for filtered events stream with blocked users removed
///
/// Automatically filters out events organized by blocked users.
/// Updates when block/unblock actions occur.
final filteredEventsProvider =
    StreamProvider.family<List<EventModel>, EventsQueryParams>((
      ref,
      params,
    ) async* {
      final eventsService = ref.watch(eventsServiceProvider);
      final authService = ref.watch(authServiceProvider);
      final profileService = ref.watch(profileServiceProvider);

      // Get current user's blocked user IDs
      Set<String> blockedUserIds = {};
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        try {
          final profile = await profileService.getProfile(currentUser.id);
          if (profile != null) {
            blockedUserIds = profile.blockedUserIds.toSet();
          }
        } catch (e) {
          // If we can't load blocked users, continue without filtering
          AppLogger.warning('Could not load blocked users', e);
        }
      }

      // Stream events and filter out blocked organizers
      await for (final events in eventsService.getActiveEventsInBounds(
        center: params.center,
        radiusKm: params.radiusKm,
      )) {
        if (blockedUserIds.isEmpty) {
          yield events;
        } else {
          yield events
              .where((event) => !blockedUserIds.contains(event.organizerId))
              .toList();
        }
      }
    });

/// Provider for current user's blocked user IDs
///
/// Used to update filtered events when blocking/unblocking users.
final blockedUsersProvider = StreamProvider<List<String>>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final currentUser = authService.currentUser;
  if (currentUser == null) {
    yield [];
    return;
  }

  // Stream user profile to get real-time blocked users updates
  try {
    final profile = await profileService.getProfile(currentUser.id);
    if (profile != null) {
      yield profile.blockedUserIds;
    } else {
      yield [];
    }
  } catch (e) {
    AppLogger.warning('Error loading blocked users', e);
    yield [];
  }
});

/// Parameters for events query
class EventsQueryParams {
  final GeoPoint center;
  final double radiusKm;

  const EventsQueryParams({required this.center, required this.radiusKm});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventsQueryParams &&
        other.center.latitude == center.latitude &&
        other.center.longitude == center.longitude &&
        other.radiusKm == radiusKm;
  }

  @override
  int get hashCode => Object.hash(center.latitude, center.longitude, radiusKm);
}
