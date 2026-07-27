import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// 위젯 탭 시 앱 내 소비 기록 화면으로 이동
class HomeWidgetLaunchHandler {
  HomeWidgetLaunchHandler._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static StreamSubscription<Uri?>? _clickSubscription;
  static bool _initialized = false;
  static Uri? _pendingRecordUri;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    if (!Platform.isIOS || _initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    HomeWidget.initiallyLaunchedFromHomeWidget().then(_receiveUri);
    _clickSubscription = HomeWidget.widgetClicked.listen(_receiveUri);
  }

  static void dispose() {
    _clickSubscription?.cancel();
    _clickSubscription = null;
    _navigatorKey = null;
    _pendingRecordUri = null;
    _initialized = false;
  }

  /// 스플래시/로그인 이후 홈 진입 시 보류된 위젯 딥링크 처리
  static void consumePendingAfterNavigation() {
    if (_pendingRecordUri == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    _pendingRecordUri = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      navigator.pushNamed('/record', arguments: DateTime.now());
    });
  }

  static void _receiveUri(Uri? uri) {
    if (uri == null || !_isRecordDeepLink(uri)) return;
    _pendingRecordUri = uri;
    _tryNavigate();
  }

  static void _tryNavigate({bool force = false}) {
    final uri = _pendingRecordUri;
    if (uri == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final routeName = _currentRouteName(navigator.context);
    if (!force && (routeName == null || routeName == '/logo_splash')) {
      return;
    }

    _pendingRecordUri = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;

      if (routeName != '/home_tab_navigator') {
        navigator.pushNamedAndRemoveUntil(
          '/home_tab_navigator',
          (route) => false,
        );
      }

      navigator.pushNamed('/record', arguments: DateTime.now());
    });
  }

  static bool _isRecordDeepLink(Uri uri) {
    return uri.host.toLowerCase() == 'record';
  }

  static String? _currentRouteName(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name;
  }
}
