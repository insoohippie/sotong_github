import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color? backgroundColor;
  final double borderRadius;
  final TextInputType? keyboardType;
  final bool obscureText;
  final double height;
  final Widget? suffix;
  final int minLines;
  final int maxLines;

  const CustomTextArea({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.keyboardType,
    this.obscureText = false,
    this.height = 150.0,
    this.suffix,
    this.minLines = 5,
    this.maxLines = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = backgroundColor ??
        (isDark
            ? AppColors.darkSurface
            : (controller.text.isEmpty
                ? AppColors.greyBackground
                : AppColors.lightBlue));

    final textStyle = isDark
        ? AppTextStyles.paragraph.copyWith(color: AppColors.darkText)
        : AppTextStyles.paragraph;

    final hintStyle = AppTextStyles.paragraph.copyWith(
      fontSize: 13,
      color: isDark ? AppColors.darkSubText : Colors.grey,
      fontFamily: 'Pretendard Variable',
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      alignment: Alignment.topLeft,
      child: TextFormField(
        controller: controller,
        style: textStyle,
        cursorColor: isDark ? AppColors.darkText : null,
        textAlignVertical: TextAlignVertical.top,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          isCollapsed: false,
          isDense: true,
          hintText: hintText,
          hintStyle: hintStyle,
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
        onChanged: onChanged,
        keyboardType: keyboardType ?? TextInputType.multiline,
        obscureText: obscureText,
      ),
    );
  }
}
