import 'package:flutter/material.dart';

/// **가로 패딩**: `width × [widthFraction]` 후 **16 — 40** pt 클램프.
///
/// 세로 구간 간격은 `vertical_section_spacing_ref_height_600.dart`.
class PaddingResponsive16_40Vw {
  PaddingResponsive16_40Vw._();

  static const double _min = 16.0;
  static const double _max = 40.0;

  /// 자주 쓰는 비율 (원하면 뷰에서 직접 0.065 등도 전달 가능).
  static const double fractionModal06 = 0.06;
  static const double fractionScreen075 = 0.075;

  static double horizontal(
    BuildContext context,
    double widthFraction,
  ) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * widthFraction).clamp(_min, _max).toDouble();
  }

  /// 좌우 클램프 + **세로(px)는 이 파일이 아니라** 여기서 고정 값만 곁들일 때.
  static EdgeInsets symmetric(
    BuildContext context, {
    required double widthFraction,
    double vertical = 0,
  }) {
    final h = horizontal(context, widthFraction);
    return EdgeInsets.symmetric(horizontal: h, vertical: vertical);
  }
}
