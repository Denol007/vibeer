import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/username_dialog.dart';
import '../../safety/providers/block_provider.dart';
import '../../friends/providers/friendship_provider.dart';
import '../../chat/providers/chat_provider.dart';

/// Profile Screen - T057
///
/// Displays user's profile with optional userId parameter.
/// If userId is provided, shows that user's profile (view-only).
/// If userId is null, shows own profile with edit and sign out options.
class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  /// Handle sign out
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();

        if (context.mounted) {
          context.go('/auth/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка выхода: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCopyUserId(BuildContext context, String userId, String? username) async {
    // Copy username if set, otherwise copy ID
    final textToCopy = username != null ? '@$username' : userId;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(username != null 
              ? 'Username скопирован: @$username'
              : 'ID пользователя скопирован: $userId'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _showUsernameDialog(BuildContext context, String? currentUsername) async {
    await showDialog<String>(
      context: context,
      builder: (context) => UsernameDialog(currentUsername: currentUsername),
    );
    // Widget will rebuild automatically via FutureBuilder
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final profileService = ref.watch(profileServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: Text('Пользователь не авторизован')),
      );
    }

    // Determine which profile to load
    final targetUserId = userId ?? currentUser.id;
    final isOwnProfile = targetUserId == currentUser.id;

    return FutureBuilder(
      future: profileService.getProfile(targetUserId),
      builder: (context, snapshot) {
        // Build AppBar with user info when available
        final user = snapshot.data;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(isOwnProfile ? 'Мой профиль' : 'Профиль'),
            actions: isOwnProfile
                ? [
                    // Copy user ID/username button
                    if (user != null)
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _handleCopyUserId(context, targetUserId, user.username),
                        tooltip: user.username != null 
                            ? 'Скопировать @${user.username}'
                            : 'Скопировать ID пользователя',
                      ),
                    // Theme toggle button
                    _buildThemeToggleButton(ref),
                    const SizedBox(width: 8),
                    // Settings button
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        context.push('/profile/settings');
                      },
                    ),
                  ]
                : [
                    // Copy user ID/username button for other profiles
                    if (user != null)
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _handleCopyUserId(context, targetUserId, user.username),
                        tooltip: user.username != null 
                            ? 'Скопировать @${user.username}'
                            : 'Скопировать ID пользователя',
                      ),
                  ],
          ),
          body: _buildBody(context, snapshot, isOwnProfile, targetUserId, ref),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot snapshot,
    bool isOwnProfile,
    String targetUserId,
    WidgetRef ref,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: LoadingIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки профиля',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (snapshot.data == null) {
      return const Center(
        child: Text('Профиль не найден'),
      );
    }

    final user = snapshot.data!;

    return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Profile photo
                CircleAvatar(
                  radius: 64,
                  backgroundImage: CachedNetworkImageProvider(
                    user.profilePhotoUrl,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Age
                Text(
                  '${user.age} лет',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // About me section
                if (user.aboutMe != null && user.aboutMe!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'О себе',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.aboutMe!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Username display/edit (for own profile)
                if (isOwnProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.alternate_email),
                        title: Text(
                          user.username != null ? '@${user.username}' : 'Username не установлен',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: user.username != null ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        subtitle: const Text('Уникальный ID как в Telegram'),
                        trailing: const Icon(Icons.edit_outlined, size: 20),
                        onTap: () => _showUsernameDialog(context, user.username),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit profile button (only for own profile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'Редактировать профиль',
                      onPressed: () {
                        Navigator.of(context).pushNamed('/edit-profile');
                      },
                      icon: Icons.edit_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Friends section
                  _buildFriendsSection(context, ref),
                  const SizedBox(height: 16),

                  // Sign out button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSignOut(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Выйти'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Friend button (only for other users' profiles)
                if (!isOwnProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFriendButton(context, ref, targetUserId),
                  ),
                  const SizedBox(height: 12),
                ],

                // Block/Unblock button (only for other users' profiles)
                if (!isOwnProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBlockButton(context, ref, targetUserId),
                  ),
                  const SizedBox(height: 16),
                ],

                // Account info (only for own profile)
                if (isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                user.authProvider == 'google'
                                    ? Icons.g_mobiledata
                                    : Icons.apple,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.authProvider == 'google'
                                    ? 'Google аккаунт'
                                    : 'Apple аккаунт',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
  }

  /// Build theme toggle button
  Widget _buildThemeToggleButton(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final currentThemeMode = ref.watch(themeProvider);
        final themeNotifier = ref.read(themeProvider.notifier);

        IconData icon;
        String tooltip;
        
        switch (currentThemeMode) {
          case AppThemeMode.system:
            icon = Icons.brightness_auto;
            tooltip = 'Системная тема';
            break;
          case AppThemeMode.light:
            icon = Icons.light_mode;
            tooltip = 'Светлая тема';
            break;
          case AppThemeMode.dark:
            icon = Icons.dark_mode;
            tooltip = 'Темная тема';
            break;
        }

        return IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: () async {
            await themeNotifier.toggleTheme();
            
            // Show snackbar with new theme mode
            final newMode = ref.read(themeProvider);
            final message = switch (newMode) {
              AppThemeMode.system => 'Системная тема',
              AppThemeMode.light => 'Светлая тема',
              AppThemeMode.dark => 'Темная тема',
            };
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Build friends section for own profile
  Widget _buildFriendsSection(BuildContext context, WidgetRef ref) {
    final friendsListAsync = ref.watch(friendsListProvider);
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Друзья',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Friends count
            friendsListAsync.when(
              data: (friends) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        friends.isEmpty
                            ? 'У вас пока нет друзей'
                            : '${friends.length} ${_getFriendsWord(friends.length)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(
                'Не удалось загрузить друзей',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Посмотреть друзей',
                    onPressed: () => context.push('/friends'),
                    icon: Icons.people_outline,
                    variant: ButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                // Friend requests button with badge
                incomingRequestsAsync.when(
                  data: (requests) {
                    final requestCount = requests.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => context.push('/friend-requests'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.person_add),
                          tooltip: 'Запросы в друзья',
                        ),
                        if (requestCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                requestCount > 9 ? '9+' : '$requestCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => IconButton(
                    onPressed: () => context.push('/friend-requests'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.person_add),
                  ),
                  error: (_, __) => IconButton(
                    onPressed: () => context.push('/friend-requests'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.person_add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get correct word form for friends count (друг/друга/друзей)
  String _getFriendsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'друг';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'друга';
    } else {
      return 'друзей';
    }
  }

  /// Build friend button (Add Friend / Pending / Friends / Accept Request)
  Widget _buildFriendButton(BuildContext context, WidgetRef ref, String userId) {
    final friendshipStatusAsync = ref.watch(friendshipStatusProvider(userId));

    return friendshipStatusAsync.when(
      data: (status) {
        if (status == 'friends') {
          // Already friends - show message button
          return CustomButton(
            text: 'Написать сообщение',
            onPressed: () => _handleSendMessage(context, ref, userId),
            icon: Icons.message_outlined,
            variant: ButtonVariant.primary,
          );
        } else if (status == 'pending_sent') {
          // Request already sent
          return CustomButton(
            text: 'Запрос отправлен',
            onPressed: null, // Disabled
            icon: Icons.schedule,
            variant: ButtonVariant.secondary,
          );
        } else if (status == 'pending_received') {
          // Request received - show accept button
          return CustomButton(
            text: 'Принять запрос',
            onPressed: () => _handleAcceptFriendRequest(context, ref, userId),
            icon: Icons.person_add,
            variant: ButtonVariant.primary,
          );
        } else {
          // No friendship - show add friend button
          return CustomButton(
            text: 'Добавить в друзья',
            onPressed: () => _handleSendFriendRequest(context, ref, userId),
            icon: Icons.person_add_outlined,
            variant: ButtonVariant.primary,
          );
        }
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleSendMessage(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create conversation
      final conversation = await chatService.getOrCreateConversation(userId);

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to private chat
        context.push(
          '/chat/private/${conversation.id}',
          extra: {'otherUserId': userId},
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия чата: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSendFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final friendshipService = ref.read(friendshipServiceProvider);
      await friendshipService.sendFriendRequest(userId);

      // Wait a bit for Firestore to propagate changes
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate providers to refresh UI
      ref.invalidate(friendshipStatusProvider(userId));
      ref.invalidate(outgoingFriendRequestsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запрос в друзья отправлен'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final friendshipService = ref.read(friendshipServiceProvider);
      
      // Get incoming requests to find the request ID
      final incomingRequests = await ref.read(incomingFriendRequestsProvider.future);
      final request = incomingRequests.firstWhere(
        (req) => req.senderId == userId,
        orElse: () => throw Exception('Request not found'),
      );

      await friendshipService.acceptFriendRequest(request.id);

      // Wait a bit for Firestore to propagate changes
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate all related providers to refresh UI
      ref.invalidate(friendshipStatusProvider(userId));
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(friendsListProvider);
      ref.invalidate(isFriendProvider(userId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы теперь друзья!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildBlockButton(BuildContext context, WidgetRef ref, String userId) {
    final isBlockedAsync = ref.watch(isUserBlockedProvider(userId));

    return isBlockedAsync.when(
      data: (isBlocked) {
        if (isBlocked) {
          // Show unblock button
          return OutlinedButton.icon(
            onPressed: () => _handleUnblockUser(context, ref, userId),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.block),
            label: const Text('Разблокировать'),
          );
        } else {
          // Show block button
          return OutlinedButton.icon(
            onPressed: () => _handleBlockUser(context, ref, userId),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Заблокировать'),
          );
        }
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleBlockUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать пользователя?'),
        content: const Text(
          'Этот пользователь не сможет видеть ваши события и отправлять вам запросы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final blockService = ref.read(blockServiceProvider);
        await blockService.blockUser(userId);

        // Invalidate providers to refresh the UI
        ref.invalidate(isUserBlockedProvider(userId));
        ref.invalidate(blockedUsersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь заблокирован')),
          );
          // Go back to previous screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUnblockUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разблокировать пользователя?'),
        content: const Text(
          'Этот пользователь снова сможет видеть ваши события и отправлять вам запросы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final blockService = ref.read(blockServiceProvider);
        await blockService.unblockUser(userId);

        // Invalidate providers to refresh the UI
        ref.invalidate(isUserBlockedProvider(userId));
        ref.invalidate(blockedUsersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь разблокирован')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
