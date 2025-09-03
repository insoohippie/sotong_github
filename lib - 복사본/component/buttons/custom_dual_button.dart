import 'package:flutter/material.dart';
import '../texts/paragraph_text.dart';
import '../theme/app_colors.dart';

// CustomDualButton에 옵션 추가
class CustomDualButton extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final bool leftEnabled;
  final bool rightEnabled;

  const CustomDualButton({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeftPressed,
    required this.onRightPressed,
    this.leftEnabled = true,
    this.rightEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            height: 60,
            child: ElevatedButton(
              onPressed: leftEnabled ? onLeftPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: leftEnabled ? AppColors.disabled : AppColors.disabled.withOpacity(0.6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: ParagraphText(
                text: leftLabel,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            height: 60,
            child: ElevatedButton(
              onPressed: rightEnabled ? onRightPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: rightEnabled ? AppColors.primary : AppColors.disabled,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
