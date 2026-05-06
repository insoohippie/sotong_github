import 'package:flutter/material.dart';

/// **세로** 구역(섹션) **사이** 간격만: 뷰 **높이 600** 기준 스케일.
///
/// 가로 패딩은 `horizontal_padding_clamped_fraction.dart`.
///
/// **최소 pt (a, b, c, …)는 이 파일에 두지 않는다** — 각 뷰에서 `(a,b,…)`를 정의하고
/// [minGap] / [minGaps]로만 넘긴다.
///
/// - [viewHeight] < 600 → 스케일 1 — **(a,b,…)는 최소로 고정** (줄지 않음).
/// - [viewHeight] == 600 → 스케일 1 (`600/600`) — **기준 높이에서 (a,b,…)가 그대로 적용**.
/// - [viewHeight] > 600 → 스케일 `h/600` — **같은 비율**로 (a,b,…)가 함께 커짐.
///
/// [minGaps] 순서: **맨 위~1, 1~2, …, (n-1)~n** (n = 그 뷰의 구역 수 = 리스트 길이).
class SectionGapRefHeight600 {
  SectionGapRefHeight600._();

  static const double refHeight = 600.0;

  static double _scale(double viewHeight) {
    if (viewHeight < refHeight) {
      return 1.0;
    }
    return viewHeight / refHeight;
  }

  /// [minGap]: 해당 뷰에서 정한 **짧은 화면(스케일 1) 기준** 구역 간 pt.
  /// [viewHeight]는 보통 `MediaQuery.sizeOf(context).height`.
  static double scaled({
    required double viewHeight,
    required double minGap,
  }) {
    return minGap * _scale(viewHeight);
  }

  static double scaledFromContext(
    BuildContext context, {
    required double minGap,
  }) {
    final h = MediaQuery.sizeOf(context).height;
    return scaled(viewHeight: h, minGap: minGap);
  }

  /// [refHeight] 이상 뷰에서는 각 항에 동일 `scale`이 곱해짐.
  static List<double> scaledMins({
    required double viewHeight,
    required List<double> minGaps,
  }) {
    final s = _scale(viewHeight);
    return [for (final g in minGaps) g * s];
  }

  static List<double> scaledMinsFromContext(
    BuildContext context, {
    required List<double> minGaps,
  }) {
    return scaledMins(
      viewHeight: MediaQuery.sizeOf(context).height,
      minGaps: minGaps,
    );
  }
}
