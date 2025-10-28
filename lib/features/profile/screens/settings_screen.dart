import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibe_app/core/theme/colors.dart';
import 'package:vibe_app/features/auth/providers/auth_provider.dart';
import 'package:vibe_app/features/profile/providers/user_settings_provider.dart';

/// Settings screen for user preferences and account management
///
/// Features:
/// - Account information
/// - Privacy settings
/// - Notification preferences
/// - About app
/// - Sign out
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;
    final userSettingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Аккаунт'),
          if (currentUser != null) ...[
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Имя'),
              subtitle: Text(currentUser.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/profile/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(currentUser.email),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Возраст'),
              subtitle: Text('${currentUser.age} лет'),
            ),
          ],

          const Divider(height: 32),

          // Privacy Section
          _buildSectionHeader('Приватность и безопасность'),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Заблокированные пользователи'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/profile/blocked');
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open privacy policy URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Открытие политики конфиденциальности'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Условия использования'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open terms of service URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие условий использования')),
              );
            },
          ),

          const Divider(height: 32),

          // Notifications Section
          _buildSectionHeader('Уведомления'),
          ...userSettingsAsync.when(
            data: (settings) => [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push-уведомления'),
                subtitle: const Text('Получать уведомления о новых событиях'),
                value: settings.pushNotificationsEnabled,
                onChanged: (value) =>
                    _handlePushNotificationsChange(context, ref, value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.chat_bubble_outline),
                title: const Text('Уведомления о сообщениях'),
                subtitle: const Text(
                  'Получать уведомления о новых сообщениях в чате',
                ),
                value: settings.chatNotificationsEnabled,
                onChanged: (value) =>
                    _handleChatNotificationsChange(context, ref, value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.group_outlined),
                title: const Text('Уведомления о запросах'),
                subtitle: const Text(
                  'Получать уведомления о запросах на присоединение',
                ),
                value: settings.joinRequestNotificationsEnabled,
                onChanged: (value) =>
                    _handleJoinRequestNotificationsChange(context, ref, value),
              ),
            ],
            loading: () => [
              const SwitchListTile(
                secondary: Icon(Icons.notifications_outlined),
                title: Text('Push-уведомления'),
                subtitle: Text('Загрузка...'),
                value: true,
                onChanged: null,
              ),
              const SwitchListTile(
                secondary: Icon(Icons.chat_bubble_outline),
                title: Text('Уведомления о сообщениях'),
                subtitle: Text('Загрузка...'),
                value: true,
                onChanged: null,
              ),
              const SwitchListTile(
                secondary: Icon(Icons.group_outlined),
                title: Text('Уведомления о запросах'),
                subtitle: Text('Загрузка...'),
                value: true,
                onChanged: null,
              ),
            ],
            error: (_, __) => [
              const SwitchListTile(
                secondary: Icon(Icons.notifications_outlined),
                title: Text('Push-уведомления'),
                subtitle: Text('Ошибка загрузки настроек'),
                value: true,
                onChanged: null,
              ),
            ],
          ),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader('О приложении'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Версия'),
            subtitle: const Text('1.0.0 (MVP)'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Помощь и поддержка'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help/FAQ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Помощь (в разработке)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Сообщить о проблеме'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open feedback form or email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Форма обратной связи (в разработке)'),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _handleSignOut(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Выйти из аккаунта',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Delete Account Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton.icon(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              icon: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.error,
              ),
              label: const Text(
                'Удалить аккаунт',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handlePushNotificationsChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      final settingsService = ref.read(userSettingsServiceProvider);
      await settingsService.updatePushNotifications(value);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Уведомления включены' : 'Уведомления выключены',
            ),
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

  Future<void> _handleChatNotificationsChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      final settingsService = ref.read(userSettingsServiceProvider);
      await settingsService.updateChatNotifications(value);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Уведомления о чате включены'
                  : 'Уведомления о чате выключены',
            ),
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

  Future<void> _handleJoinRequestNotificationsChange(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      final settingsService = ref.read(userSettingsServiceProvider);
      await settingsService.updateJoinRequestNotifications(value);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Уведомления о запросах включены'
                  : 'Уведомления о запросах выключены',
            ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

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
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppColors.error),
            ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка при выходе: $e')));
        }
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Это действие необратимо. Все ваши данные, события и сообщения будут удалены навсегда.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final authService = ref.read(authServiceProvider);
        
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Удаление аккаунта...'),
              ],
            ),
          ),
        );

        await authService.deleteAccount();

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          context.go('/auth/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аккаунт успешно удален')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления аккаунта: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
