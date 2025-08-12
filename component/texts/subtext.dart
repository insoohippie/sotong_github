import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';


class SubText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  const SubText({super.key, required this.text, this.color, this.fontWeight});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.subtext.copyWith(
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}
