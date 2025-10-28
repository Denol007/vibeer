import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:vibe_app/core/theme/colors.dart';
import 'package:vibe_app/features/safety/providers/block_provider.dart';
import 'package:vibe_app/features/profile/models/user_model.dart';
import 'package:vibe_app/shared/widgets/loading_indicator.dart';

/// Screen showing list of blocked users with unblock action
///
/// Features:
/// - List of all blocked users
/// - User profile photo and name
/// - Unblock button
/// - Empty state when no blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заблокированные пользователи'),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            itemCount: blockedUsers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return _buildBlockedUserTile(context, ref, user);
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет заблокированных пользователей',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Вы можете заблокировать пользователей из их профиля',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserTile(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return ListTile(
      onTap: () => context.push('/user/${user.id}'),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceVariant,
        backgroundImage: user.profilePhotoUrl.isNotEmpty
            ? CachedNetworkImageProvider(user.profilePhotoUrl)
            : null,
        child: user.profilePhotoUrl.isEmpty
            ? Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Заблокирован',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary.withOpacity(0.7),
        ),
      ),
      trailing: OutlinedButton(
        onPressed: () => _handleUnblock(context, ref, user),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Разблокировать'),
      ),
    );
  }

  Future<void> _handleUnblock(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разблокировать пользователя?'),
        content: Text(
          'Пользователь ${user.name} снова сможет видеть ваши события и отправлять вам запросы.',
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
        await blockService.unblockUser(user.id);

        // Invalidate providers to refresh the UI
        ref.invalidate(isUserBlockedProvider(user.id));
        ref.invalidate(blockedUsersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} разблокирован'),
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
  }
}
