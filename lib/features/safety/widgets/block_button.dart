import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Block Button Widget - T059
///
/// Safety action button for blocking users.
/// Shows confirmation dialog before blocking.
class BlockButton extends StatelessWidget {
  final VoidCallback onBlock;
  final bool isBlocked;

  const BlockButton({super.key, required this.onBlock, this.isBlocked = false});

  Future<void> _showBlockConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isBlocked
              ? 'Разблокировать пользователя?'
              : 'Заблокировать пользователя?',
        ),
        content: Text(
          isBlocked
              ? 'Вы снова сможете видеть события этого пользователя'
              : 'Вы больше не будете видеть события этого пользователя',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onBlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showBlockConfirmation(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: isBlocked ? AppColors.primary : AppColors.error,
        side: BorderSide(
          color: isBlocked ? AppColors.primary : AppColors.error,
        ),
      ),
      icon: Icon(isBlocked ? Icons.block : Icons.block_outlined),
      label: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
    );
  }
}
