import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class ParagraphText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  const ParagraphText({
    super.key,
    required this.text,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.paragraph.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}
