import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class SubText extends StatelessWidget {
  final String text;

  const SubText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.subtext);
  }
}
