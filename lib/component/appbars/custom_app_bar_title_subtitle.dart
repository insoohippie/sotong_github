import 'package:flutter/material.dart';
import 'package:sotong/component/texts/header_text.dart';
import 'package:sotong/component/texts/subtext.dart';

import '../theme/app_spacing.dart';

class CustomAppBarTitleSubtitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const CustomAppBarTitleSubtitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sectionSpacing,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 왼쪽 뒤로가기 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios, size: 24),
            ),
          ),

          // 중앙 타이틀 & 서브타이틀
          Column(
            children: [
              HeaderText(text: title),
              const SizedBox(height: 4),
              SubText(text: subtitle, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
