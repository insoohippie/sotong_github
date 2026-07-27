import 'package:flutter/material.dart';
import 'package:sotong/component/texts/header_text.dart';

import '../theme/app_spacing.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const CustomAppBar({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sectionSpacing,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 12),
            HeaderText(text: title),
          ],
        ],
      ),
    );
  }
}
