// plan_category_pill.dart
import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

class PlanCategoryPill extends StatelessWidget {
  final String text;
  final String emoji;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final double height;

  final bool highlight;
  final Color highlightColor;

  const PlanCategoryPill({
    super.key,
    required this.text,
    required this.emoji,
    required this.onTap,
    required this.onClear,
    this.height = 60,
    this.highlight = false,
    this.highlightColor = const Color(0xFFFFF1F1),
  });

  @override
  Widget build(BuildContext context) {
    final name = text.trim();
    final hasValue = name.isNotEmpty;

    final Color bgColor = (hasValue && highlight)
        ? highlightColor
        : (hasValue ? AppColors.lightBlue : AppColors.greyBackground);

    final Color textColor = hasValue ? Colors.black : AppColors.subText;
    final displayEmoji = (emoji.trim().isNotEmpty) ? emoji : '💰';

    return InkWell(
      onTap: onTap,
      onLongPress: onClear,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (!hasValue)
              Icon(Icons.add, size: 18, color: AppColors.subText)
            else
              Text(displayEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? name : '입력',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
