import 'package:flutter/material.dart';

/// 설정창 등에서 쓰는 '뒤로가기' 앱바.
/// 흰 배경, 왼쪽 뒤로가기 버튼. [title] 있으면 제목 표시.
class BackOnlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// [TodayRecordPage] 등 날짜 제목과 동일한 스타일 — 커스텀 [AppBar]에서도 재사용.
  /// [fontSize] 생략 시 20 (홈→기록 등 기본 앱바 타이틀).
  static TextStyle? titleTextStyle(BuildContext context, {double? fontSize}) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium?.copyWith(
      fontSize: fontSize ?? 20,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }

  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? iconColor;

  /// 제목 (있으면 중앙 또는 leading 옆에 표시)
  final String? title;

  /// 제목 중앙 정렬 (기본 false, title 있을 때만 의미 있음)
  final bool centerTitle;

  /// 제목 글자 크기 (기본 20). 미기록 입력 등에서만 줄일 때 지정.
  final double? titleFontSize;

  const BackOnlyAppBar({
    super.key,
    this.onBack,
    this.backgroundColor,
    this.iconColor,
    this.title,
    this.centerTitle = false,
    this.titleFontSize,
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
        style: titleTextStyle(context, fontSize: titleFontSize),
      )
          : const SizedBox.shrink(),
      centerTitle: centerTitle,
    );
  }
}
