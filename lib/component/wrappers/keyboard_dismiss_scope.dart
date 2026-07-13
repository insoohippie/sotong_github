import 'package:flutter/material.dart';

/// 키보드가 열렸을 때 바텀시트 입력 영역(A) 하단의 흰색 내부 여백.
const double keyboardSheetInnerPadding = 20;

/// 키보드가 열려 있을 때 바깥(빈 영역)을 탭하면 [unfocus]로 닫습니다.
///
/// [MaterialApp.builder] 또는 화면/바텀시트 루트에 감싸서 사용하세요.
class KeyboardDismissScope extends StatelessWidget {
  const KeyboardDismissScope({super.key, required this.child});

  final Widget child;

  static void dismiss(BuildContext context) {
    final scope = FocusScope.of(context);
    if (!scope.hasFocus) return;
    scope.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => dismiss(context),
      child: child,
    );
  }
}

/// 스크롤 드래그 시에도 키보드가 내려가도록 하는 앱 공통 스크롤 동작.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) {
    return ScrollViewKeyboardDismissBehavior.onDrag;
  }
}

/// 바텀시트 등에서 키보드 열림/닫힘에 따라 A/B 영역을 나눌 때 사용.
/// [WidgetsBindingObserver.didChangeMetrics]로 키보드 변화를 확실히 반영합니다.
class KeyboardVisibilityBuilder extends StatefulWidget {
  const KeyboardVisibilityBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, bool isKeyboardVisible) builder;

  @override
  State<KeyboardVisibilityBuilder> createState() =>
      _KeyboardVisibilityBuilderState();
}

class _KeyboardVisibilityBuilderState extends State<KeyboardVisibilityBuilder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return widget.builder(context, isKeyboardVisible);
  }
}
