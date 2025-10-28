import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../models/user_model.dart';
import '../providers/profile_provider.dart';

/// Dialog for setting/changing username
class UsernameDialog extends ConsumerStatefulWidget {
  final String? currentUsername;

  const UsernameDialog({
    super.key,
    this.currentUsername,
  });

  @override
  ConsumerState<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends ConsumerState<UsernameDialog> {
  late TextEditingController _controller;
  bool _isChecking = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final username = _controller.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = null;
        _isAvailable = null;
      });
      return;
    }

    // Validate format first
    if (!UserModel.isValidUsername(username)) {
      setState(() {
        _errorMessage = 'Только строчные буквы, цифры и _\nДлина: 3-20 символов';
        _isAvailable = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _isAvailable = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final isAvailable = await profileService.isUsernameAvailable(username);

      setState(() {
        _isAvailable = isAvailable;
        _errorMessage = isAvailable ? null : 'Этот username уже занят';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка проверки: ${e.toString()}';
        _isAvailable = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _save() async {
    final username = _controller.text.trim();

    if (username.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    if (_isAvailable != true) {
      await _checkAvailability();
      if (_isAvailable != true) return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile(username: username);

      if (mounted) {
        Navigator.of(context).pop(username);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username обновлен: @$username'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Установить username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите уникальный username, как в Telegram.\nНапример: @denol',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'например: denol',
              prefixText: '@',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _isChecking
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _isAvailable == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _isAvailable == false
                          ? Icon(Icons.error, color: AppColors.error)
                          : null,
              errorText: _errorMessage,
            ),
            onChanged: (_) {
              // Reset status when typing
              setState(() {
                _isAvailable = null;
                _errorMessage = null;
              });
            },
            onSubmitted: (_) => _checkAvailability(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isChecking || _isSaving
                      ? null
                      : _checkAvailability,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Проверить'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Правила:\n• 3-20 символов\n• Только строчные буквы, цифры, _\n• Должен начинаться с буквы',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isAvailable != true ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
