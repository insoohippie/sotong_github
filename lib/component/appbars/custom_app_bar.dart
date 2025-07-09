import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/header_text.dart';

import '../../theme/app_spacing.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding,vertical: AppSpacing.sectionSpacing),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, size: 30),
          ),
          const SizedBox(width: 12),
          HeaderText(text: title),
        ],
      ),
    );
  }
}

