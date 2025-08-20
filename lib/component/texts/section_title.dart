import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/texts/header_text.dart';
import '../theme/app_colors.dart';


class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 8),
          ParagraphText(text: title, fontWeight: FontWeight.bold,),
        ],
      ),
    );
  }
}
