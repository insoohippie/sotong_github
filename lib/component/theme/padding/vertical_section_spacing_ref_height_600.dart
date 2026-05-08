import 'package:flutter/material.dart';

/// Vertical spacing between sections, scaled from a 600 pt reference height.
class SectionGapRefHeight600 {
  SectionGapRefHeight600._();

  static const double refHeight = 600.0;

  static double _scale(double viewHeight) {
    if (viewHeight < refHeight) {
      return 1.0;
    }
    return viewHeight / refHeight;
  }

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
    return scaled(
      viewHeight: MediaQuery.sizeOf(context).height,
      minGap: minGap,
    );
  }

  static List<double> scaledMins({
    required double viewHeight,
    required List<double> minGaps,
  }) {
    final scale = _scale(viewHeight);
    return [
      for (final gap in minGaps) gap * scale,
    ];
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
