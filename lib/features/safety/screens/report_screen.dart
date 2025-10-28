import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/safety_provider.dart';
import '../services/safety_service.dart';

/// Report Screen - T060
///
/// Form for submitting safety reports for users or events.
/// Requires reason (min 10 chars) and shows confirmation on success.
class ReportScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? eventId;

  const ReportScreen({super.key, this.userId, this.eventId})
    : assert(
        userId != null || eventId != null,
        'Either userId or eventId must be provided',
      );

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Validate reason field
  String? _validateReason(String? value) {
    return validateTextLength(value, 500, minLength: 10, fieldName: 'Причина');
  }

  /// Handle report submission
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final safetyService = ref.read(safetyServiceProvider);
      final reason = _reasonController.text.trim();

      if (widget.userId != null) {
        await safetyService.reportUser(userId: widget.userId!, reason: reason);
      } else {
        await safetyService.reportEvent(
          eventId: widget.eventId!,
          reason: reason,
        );
      }

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Жалоба отправлена'),
            content: const Text(
              'Спасибо за ваш отчёт. Мы рассмотрим его в ближайшее время.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close report screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on SafetyException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пожаловаться')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
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
                        Text(
                          'Информация',
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
                      'Пожалуйста, опишите причину вашей жалобы. '
                      'Ваш отчёт будет рассмотрен модераторами.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reason textarea
              CustomTextField(
                controller: _reasonController,
                labelText: 'Причина *',
                hintText: 'Опишите, что не так...',
                maxLines: 6,
                minLines: 4,
                maxLength: 500,
                enabled: !_isSubmitting,
                validator: _validateReason,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),

              // Helper text
              const Text(
                'Минимум 10 символов',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              CustomButton(
                text: 'Отправить жалобу',
                onPressed: _isSubmitting ? null : _submitReport,
                isLoading: _isSubmitting,
              ),
              const SizedBox(height: 16),

              // Privacy note
              Text(
                'Ваша жалоба будет обработана конфиденциально',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
