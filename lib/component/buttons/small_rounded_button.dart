import 'package:flutter/material.dart';
import '../texts/subtext.dart';
import '../theme/app_colors.dart';
import '../../services/chart_animation_haptic.dart';

class SmallRoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final bool enabled;

  const SmallRoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.add_circle,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.whiteText,
    this.borderColor,
    this.borderWidth = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;
    final effectiveBackground = isEnabled
        ? backgroundColor
        : AppColors.disabled.withValues(alpha: 0.35);
    final effectiveTextColor = isEnabled ? textColor : AppColors.subText;

    return ElevatedButton.icon(
      onPressed: isEnabled
          ? () {
              AppHaptics.buttonTap();
              onPressed!();
            }
          : null,
      icon: Icon(icon, size: 16, color: effectiveTextColor),
      label: SubText(
        text: text,
        color: effectiveTextColor,
        fontWeight: FontWeight.bold,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackground,
        disabledBackgroundColor: effectiveBackground,
        disabledForegroundColor: effectiveTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(
                  color: isEnabled ? borderColor! : AppColors.disabled,
                  width: borderWidth,
                ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        alignment: Alignment.center,
        minimumSize: const Size(0, 36),
      ),
    );
  }
}
