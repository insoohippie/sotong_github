import 'dart:async';

import 'package:flutter/services.dart';

/// 차트 진입/재생 애니메이션용 연속 햅틱 (다라라락)
class ChartAnimationHapticPlayer {
  Timer? _timer;

  /// [duration] 동안 [interval]마다 가벼운 햅틱을 연속 재생한다.
  void play({
    required Duration duration,
    Duration interval = const Duration(milliseconds: 110),
  }) {
    cancel();

    final pulseCount = (duration.inMilliseconds / interval.inMilliseconds)
        .ceil()
        .clamp(4, 12);

    void pulse() => HapticFeedback.selectionClick();

    pulse();
    var count = 1;
    _timer = Timer.periodic(interval, (_) {
      if (count >= pulseCount) {
        cancel();
        return;
      }
      pulse();
      count++;
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 버튼·탭 등 일반 UI 햅틱
class AppHaptics {
  AppHaptics._();

  static void buttonTap() => HapticFeedback.selectionClick();

  static void lightTap() => HapticFeedback.lightImpact();
}
