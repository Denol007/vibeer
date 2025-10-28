import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Report Button Widget - T059
///
/// Safety action button for reporting users or events.
/// Opens report form when tapped.
class ReportButton extends StatelessWidget {
  final VoidCallback onReport;

  const ReportButton({super.key, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onReport,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
      ),
      icon: const Icon(Icons.flag_outlined),
      label: const Text('Пожаловаться'),
    );
  }
}
