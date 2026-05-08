import 'package:flutter/material.dart';

/// Horizontal padding: `width * widthFraction`, clamped to 16-40 pt.
class PaddingResponsive16_40Vw {
  PaddingResponsive16_40Vw._();

  static const double _min = 16.0;
  static const double _max = 40.0;

  static const double fractionModal06 = 0.06;
  static const double fractionScreen075 = 0.075;

  static double horizontal(
    BuildContext context,
    double widthFraction,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * widthFraction).clamp(_min, _max).toDouble();
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    required double widthFraction,
    double vertical = 0,
  }) {
    final horizontal = PaddingResponsive16_40Vw.horizontal(
      context,
      widthFraction,
    );
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }
}
