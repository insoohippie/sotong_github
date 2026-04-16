import 'package:flutter/material.dart';

/// 설정창 등에서 쓰는 '뒤로가기' 앱바.
/// 흰 배경, 왼쪽 뒤로가기 버튼. [title] 있으면 제목 표시.
class BackOnlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? iconColor;

  /// 제목 (있으면 중앙 또는 leading 옆에 표시)
  final String? title;

  /// 제목 중앙 정렬 (기본 false, title 있을 때만 의미 있음)
  final bool centerTitle;

  const BackOnlyAppBar({
    super.key,
    this.onBack,
    this.backgroundColor,
    this.iconColor,
    this.title,
    this.centerTitle = false,
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
      title: title != null
          ? Text(
        title!,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      )
          : const SizedBox.shrink(),
      centerTitle: centerTitle,
    );
  }
}
