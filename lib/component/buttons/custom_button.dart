import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../services/chart_animation_haptic.dart';
import '../theme/app_spacing.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final double height;
  final Color? backgroundColor;

  /// null이면 기본 screenPadding 사용, EdgeInsets.zero면 전체 너비
  final EdgeInsetsGeometry? padding;

  /// 버튼 텍스트 크기. null이면 17 (본문 복원용)
  final double? fontSize;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.height = 60,
    this.backgroundColor,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: enabled
              ? () {
            AppHaptics.buttonTap();
            onPressed();
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            backgroundColor ??
                (enabled ? AppColors.primary : AppColors.disabled),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, height),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            overlayColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: fontSize ?? 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
