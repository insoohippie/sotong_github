import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class DualOptionSelector extends StatelessWidget {
  final String? selectedOption;
  final String option1;
  final String option2;
  final Function(String) onSelected;

  const DualOptionSelector({
    super.key,
    required this.selectedOption,
    required this.option1,
    required this.option2,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption(option1),
        const SizedBox(width: AppSpacing.horizonSpacing),
        _buildOption(option2),
      ],
    );
  }

  Widget _buildOption(String option) {
    final bool isSelected = selectedOption == option;
    final Color bgColor =
    isSelected ? const Color(0xFFEDF4FF) : const Color(0xFFEDEDED);
    final Color textColor = isSelected ? Colors.black : Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(option),
        child: Container(
          height: 60.0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              option,
              style: AppTextStyles.paragraph.copyWith(
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
