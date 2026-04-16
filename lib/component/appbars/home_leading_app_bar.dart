import 'package:flutter/material.dart';

/// 왼쪽에 [Icons.home]만 두고, 탭 시 메인 홈 탭으로 이동하는 앱바.
/// [HomeTabNavigator] 하단 네비 홈 탭과 동일 아이콘·크기(28).
class HomeLeadingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeLeadingAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.backgroundColor,
    this.iconColor,
    this.onHome,
  });

  final Widget? title;

  /// [title]이 있을 때 가운데 정렬 여부
  final bool centerTitle;

  final Color? backgroundColor;

  /// null이면 비선택 탭과 동일하게 [Colors.grey]
  final Color? iconColor;

  /// null이면 [Navigator]로 `/home_tab_navigator`까지 스택을 비우고 이동
  final VoidCallback? onHome;

  static void navigateToHomeTab(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home_tab_navigator',
          (route) => false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: onHome ?? () => navigateToHomeTab(context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        icon: Icon(
          Icons.home,
          size: 28,
          color: iconColor ?? Colors.grey,
        ),
      ),
      title: title,
      centerTitle: centerTitle,
    );
  }
}
