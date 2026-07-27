import 'package:flutter/material.dart';
import '../texts/subtext.dart';
import '../theme/app_colors.dart';
import '../../services/chart_animation_haptic.dart';

class SmallRoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;

  const SmallRoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.add_circle,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.whiteText,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        AppHaptics.buttonTap();
        onPressed();
      },
      icon: Icon(icon, size: 16, color: textColor),
      label: SubText(text: text, color: textColor, fontWeight: FontWeight.bold,),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!, width: borderWidth),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        alignment: Alignment.center,
        minimumSize: const Size(0, 36),
      ),
    );
  }
}
