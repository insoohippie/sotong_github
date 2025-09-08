import 'package:flutter/material.dart';
import '../texts/paragraph_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CustomDualButton extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final bool leftEnabled;
  final bool rightEnabled;
  final double height;

  const CustomDualButton({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeftPressed,
    required this.onRightPressed,
    this.leftEnabled = true,
    this.rightEnabled = true,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              height: height,
              child: ElevatedButton(
                onPressed: leftEnabled ? onLeftPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: leftEnabled
                      ? AppColors.primary
                      : AppColors.disabled.withOpacity(0.6),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              height: height,
              child: ElevatedButton(
                onPressed: rightEnabled ? onRightPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rightEnabled
                      ? AppColors.disabled
                      : AppColors.disabled,
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
