import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/events/screens/feed_screen.dart';
import '../../features/events/screens/create_event_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/events/screens/manage_requests_screen.dart';
import '../../features/events/screens/event_participants_screen.dart';
// import '../../features/setup/setup_required_screen.dart';
import '../../features/chat/screens/group_chat_screen.dart';
import '../../features/chat/screens/private_chat_screen.dart';
import '../../features/chat/screens/conversations_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/blocked_users_screen.dart';
import '../../features/safety/screens/report_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/friends/screens/friends_list_screen.dart';
import '../../features/friends/screens/friend_requests_screen.dart';
import '../../features/search/screens/global_search_screen.dart';
import '../../features/search/screens/search_results_screen.dart';
import '../../features/profile/models/user_model.dart';
import '../../features/events/models/event_model.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Helper class to convert Stream to ChangeNotifier for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Application routing configuration with auth guard
///
/// Provides router that integrates with Riverpod auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        name: 'auth-login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main app navigation (requires authentication)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          // Support tab index from query params
          final tabIndex =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return HomeScreen(initialIndex: tabIndex);
        },
        routes: [
          // Event details
          GoRoute(
            path: 'event/:eventId',
            name: 'event-details',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId']!;
              return EventDetailScreen(eventId: eventId);
            },
          ),
        ],
      ),

      // Feed view
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),

      // Create event
      GoRoute(
        path: '/event/create',
        name: 'create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),

      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'blocked',
            name: 'blocked-users',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
        ],
      ),

      // Other user's profile
      GoRoute(
        path: '/user/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),

      // Chat routes
      GoRoute(
        path: '/chat/:eventId',
        name: 'chat',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return GroupChatScreen(eventId: eventId);
        },
      ),

      // Private chat routes
      GoRoute(
        path: '/chat/private/:conversationId',
        name: 'private-chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final otherUserId = extra?['otherUserId'] as String? ?? '';
          return PrivateChatScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
          );
        },
      ),

      // Conversations list
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ConversationsListScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Safety features
      GoRoute(
        path: '/safety/report',
        name: 'report',
        builder: (context, state) {
          final targetId = state.uri.queryParameters['targetId'];
          final targetType = state.uri.queryParameters['targetType'] ?? 'user';
          return ReportScreen(
            userId: targetType == 'user' ? targetId : null,
            eventId: targetType == 'event' ? targetId : null,
          );
        },
      ),

      // Manage join requests (for event organizers)
      GoRoute(
        path: '/event/:eventId/requests',
        name: 'manage-requests',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return ManageRequestsScreen(eventId: eventId);
        },
      ),

      // Event participants list
      GoRoute(
        path: '/event/:eventId/participants',
        name: 'event-participants',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final organizerId = state.uri.queryParameters['organizerId'] ?? '';
          final participantIdsStr = state.uri.queryParameters['participantIds'] ?? '';
          final participantIds = participantIdsStr.isNotEmpty
              ? participantIdsStr.split(',')
              : <String>[];

          return EventParticipantsScreen(
            eventId: eventId,
            organizerId: organizerId,
            participantIds: participantIds,
          );
        },
      ),

      // Friends system
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => const FriendsListScreen(),
      ),
      GoRoute(
        path: '/friend-requests',
        name: 'friend-requests',
        builder: (context, state) => const FriendRequestsScreen(),
      ),

      // Global search by ID
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
        routes: [
          GoRoute(
            path: 'results',
            name: 'search-results',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return SearchResultsScreen(
                users: extra['users'] as List<UserModel>,
                events: extra['events'] as List<EventModel>,
                query: extra['query'] as String,
              );
            },
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),

    // Auth guard with Riverpod integration
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final currentPath = state.matchedLocation;
      
      print('🔀 Router redirect check:');
      print('   Path: $currentPath');
      print('   Authenticated: $isAuthenticated');
      print('   User: ${user?.name ?? "null"}');
      print('   AgeConfirmed: ${user?.isAgeConfirmed ?? "null"}');

      // Case 1: Not authenticated
      if (!isAuthenticated) {
        // Allow access to auth routes only
        if (currentPath.startsWith('/auth')) {
          return null; // Allow
        }
        print('   → Redirecting to /auth/login (not authenticated)');
        return '/auth/login';
      }

      // Case 2: Authenticated but profile not complete
      if (!user.isAgeConfirmed) {
        // Already on profile setup? Allow
        if (currentPath == '/auth/profile-setup') {
          return null;
        }
        print('   → Redirecting to /auth/profile-setup (age not confirmed)');
        return '/auth/profile-setup';
      }

      // Case 3: Authenticated with complete profile
      // If trying to access auth routes, redirect to home
      if (currentPath.startsWith('/auth')) {
        print('   → Redirecting to /home (already authenticated)');
        return '/home';
      }

      // All other cases: allow navigation
      print('   → Allowing navigation');
      return null;
    },
  );
});
