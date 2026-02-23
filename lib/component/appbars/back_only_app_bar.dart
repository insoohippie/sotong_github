import 'package:flutter/material.dart';

/// 설정창 등에서 쓰는 '뒤로가기만 있는' 앱바.
/// 흰 배경, 제목 없음, 왼쪽 뒤로가기 버튼만 표시.
class BackOnlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? iconColor;

  const BackOnlyAppBar({
    super.key,
    this.onBack,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: iconColor ?? theme.colorScheme.onSurface,
          size: 24,
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      title: const SizedBox.shrink(),
    );
  }
}
