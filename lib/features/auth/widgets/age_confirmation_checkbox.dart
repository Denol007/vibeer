import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Age confirmation checkbox widget for profile setup
///
/// Displays a checkbox with text confirming the user is 18+.
/// Used in profile setup to ensure age requirement compliance.
class AgeConfirmationCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool showError;

  const AgeConfirmationCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: GestureDetector(
                  onTap: () => onChanged(!value),
                  child: Text(
                    'I confirm I am 18+',
                    style: TextStyle(
                      fontSize: 14,
                      color: showError ? AppColors.error : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 48.0, top: 4.0),
            child: Text(
              'Необходимо подтвердить возраст',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
