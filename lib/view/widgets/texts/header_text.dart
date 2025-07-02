import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class HeaderText extends StatelessWidget {
  final String text;
  final Color? color;

  const HeaderText({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.header.copyWith(color: color),
    );
  }
}
