import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Temporary setup screen shown when Firebase/Google Maps are not configured
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Требуется настройка'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.settings_suggest,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),

            const Text(
              'Требуется настройка',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Для полной функциональности приложения необходимо настроить:',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            _buildRequirement(
              '1. Google Maps API Key',
              'Требуется для отображения карты и поиска событий',
              Icons.map,
              'См. файл GOOGLE_MAPS_SETUP.md',
            ),
            const SizedBox(height: 16),

            _buildRequirement(
              '2. Firebase Configuration',
              'Требуется для аутентификации, базы данных и хранилища',
              Icons.cloud,
              'Запустите: flutterfire configure',
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Текущий режим',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Вы вошли через MockAuthService (тестовый режим). '
                    'Карта, события, чат и другие функции требуют настройки Firebase.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Быстрый старт:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildCodeBlock(
              '1. Получите Google Maps API ключ\n'
              '2. Добавьте в AndroidManifest.xml\n'
              '3. Запустите: flutterfire configure\n'
              '4. Раскомментируйте Firebase.initializeApp() в main.dart\n'
              '5. Замените MockAuthService на FirebaseAuthService',
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Show more info
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Подробная инструкция'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Документация находится в файлах:\n\n'
                          '• GOOGLE_MAPS_SETUP.md - настройка карт\n'
                          '• firebase/README.md - настройка Firebase\n\n'
                          'После настройки приложение получит доступ ко всем функциям: '
                          'карта с событиями, чат, профили, безопасность и т.д.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Понятно'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Подробная инструкция'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(
    String title,
    String description,
    IconData icon,
    String action,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }
}
