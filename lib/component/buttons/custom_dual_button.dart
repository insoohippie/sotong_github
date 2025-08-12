import 'package:flutter/material.dart';
import '../texts/paragraph_text.dart';
import '../theme/app_colors.dart';

class CustomDualButton extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;

  const CustomDualButton({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeftPressed,
    required this.onRightPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 왼쪽 버튼 - 회색
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            height: 60, // CustomButton과 동일한 높이
            child: ElevatedButton(
              onPressed: onLeftPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.disabled,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: ParagraphText(
                text: leftLabel,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 오른쪽 버튼 - 파란색
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            height: 60, // CustomButton과 동일한 높이
            child: ElevatedButton(
              onPressed: onRightPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                // 파란 버튼
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: ParagraphText(
                text: rightLabel,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
