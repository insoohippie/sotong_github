import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color? backgroundColor;
  final double borderRadius;
  final TextInputType? keyboardType;
  final bool obscureText;
  final double height;
  final Widget? suffix;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.keyboardType,
    this.obscureText = false,
    this.height = 60.0,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ??
        (controller.text.isEmpty
            ? AppColors.greyBackground
            : AppColors.lightBlue);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.paragraph,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isCollapsed: false,
          isDense: true,
          hintText: hintText,
          hintStyle: AppTextStyles.paragraph.copyWith(color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
      ),
    );
  }
}
