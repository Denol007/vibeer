import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibe_app/core/theme/colors.dart';
import 'package:vibe_app/features/auth/providers/auth_provider.dart';
import 'package:vibe_app/features/auth/services/auth_service.dart';
import 'package:vibe_app/shared/widgets/custom_button.dart';
import 'package:vibe_app/shared/widgets/loading_indicator.dart';

/// Login screen with OAuth authentication
///
/// Provides Google and Apple sign-in options with loading
/// and error states.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      // Router will automatically redirect based on auth state
      // No need for manual navigation here
    } on AuthCancelledException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Вход отменён';
        _isLoading = false;
      });
    } on AuthNetworkException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Нет подключения к интернету';
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка входа: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();

      // Router will automatically redirect based on auth state
      // No need for manual navigation here
    } on AuthCancelledException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Вход отменён';
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка входа: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              const Icon(Icons.people, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Vibe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Спонтанные встречи рядом',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 64),

              // Loading indicator
              if (_isLoading) ...[
                const LoadingIndicator(),
                const SizedBox(height: 24),
              ],

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Sign Up section
              const Text(
                'Новый пользователь?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Sign up with Google button
              CustomButton(
                text: 'Регистрация через Google',
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icons.g_mobiledata,
                variant: ButtonVariant.primary,
              ),
              const SizedBox(height: 8),

              // Sign up with Apple button
              CustomButton(
                text: 'Регистрация через Apple',
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icons.apple,
                variant: ButtonVariant.primary,
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'или',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Login section
              const Text(
                'Уже есть аккаунт?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Login with Google button
              CustomButton(
                text: 'Войти через Google',
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icons.g_mobiledata,
                variant: ButtonVariant.secondary,
              ),
              const SizedBox(height: 8),

              // Login with Apple button
              CustomButton(
                text: 'Войти через Apple',
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icons.apple,
                variant: ButtonVariant.secondary,
              ),
              const SizedBox(height: 32),

              // Age requirement notice
              Text(
                'Для использования приложения вам должно быть 18-25 лет',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
