import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class ParagraphText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const ParagraphText({
    super.key,
    required this.text,
    this.color,
    this.fontWeight,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.paragraph.copyWith(
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: fontWeight,
    );
    return Text(
      text,
      style: fontSize != null ? base.copyWith(fontSize: fontSize) : base,
    );
  }
}
