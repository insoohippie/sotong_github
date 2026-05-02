import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Celebration 전용 원형 차트 Painter
/// 시계 방향: 0%(12시) → 25%(3시) → 50%(6시) → 75%(9시) → 100%(12시)
class PlanSummaryChartPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  const PlanSummaryChartPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 21.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final maxAngle = 2 * math.pi;
    final startAngle = -math.pi / 2; // 12시 시작

    // ===== 배경 원 (항상 완전한 원) =====
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // ===== 진행 원 =====
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // ✅ 100%는 drawCircle로 깔끔하게 닫기
    if (p == 1.0) {
      canvas.drawCircle(center, radius, progressPaint);
      return;
    }

    // ❗ 99% 이하는 2π 직전까지만 (StrokeCap.round seam 방지)
    const double epsilon = 0.001;
    final sweepAngle = (maxAngle * p).clamp(0.0, maxAngle - epsilon);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle, // +면 시계방향
      false, // ✅ useCenter=false (부채꼴 금지)
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PlanSummaryChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
