import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiGaugePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0 (외부 원)
  final Color backgroundColor;
  final Color progressColorStart;
  final Color progressColorEnd; // (현재 단색 사용 중이지만 유지)
  final double strokeWidth;
  final double? targetLinePosition; // 기준선 위치 (0.0 ~ 1.0, null이면 표시 안 함)
  final bool isFullCircle; // true면 원형(360도), false면 반원(180도)
  final double startProgress; // 시작 지점 (0.0 ~ 1.0, 기본값 0.0) - 홈 화면용
  final bool isDashed; // 점선으로 그리기 여부
  final double dashWidth; // 점선의 대시 길이
  final double dashGap; // 점선의 간격

  // 내부 원 파라미터
  final double? innerProgress; // 0.0 ~ 1.0 (내부 원, null이면 표시 안 함)
  final Color? innerBackgroundColor;
  final Color? innerProgressColorStart;
  final Color? innerProgressColorEnd;
  final double? innerStrokeWidth;
  final double innerRadiusRatio; // 내부 원 반지름 비율 (0.0 ~ 1.0, 기본값 0.7)
  final bool is24HourClock; // true면 24시간 시계 모드
  final List<int>? alarmHours; // 알람 시간 리스트 (0~23)

  SemiGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColorStart,
    required this.progressColorEnd,
    this.strokeWidth = 26,
    this.targetLinePosition,
    this.isFullCircle = false,
    this.startProgress = 0.0, // 기본값 0.0
    this.isDashed = false,
    this.dashWidth = 8.0,
    this.dashGap = 4.0,
    this.innerProgress,
    this.innerBackgroundColor,
    this.innerProgressColorStart,
    this.innerProgressColorEnd,
    this.innerStrokeWidth,
    this.innerRadiusRatio = 0.7,
    this.is24HourClock = false,
    this.alarmHours,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 중심점 계산: 반원이면 하단 중앙, 원형이면 화면 중앙
    final center = isFullCircle
        ? Offset(size.width / 2, size.height / 2)
        : Offset(size.width / 2, size.height);

    final outerRadius = size.width / 2;

    // 내부 원 반지름
    final innerRadius = (outerRadius - strokeWidth / 2) * innerRadiusRatio;

    // 최대 각도: 반원이면 180도, 원형이면 360도
    final maxAngle = isFullCircle ? 2 * math.pi : math.pi;

    // 시작 각도:
    // - 원형: 12시(-π/2)에서 시작
    // - 반원: 왼쪽(π)에서 시작
    final startAngle = isFullCircle ? -math.pi / 2 : math.pi;

    // =========================
    // 외부 "배경"
    // =========================
    final outerBackgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 원형 배경은 drawArc(2π)에서 seam이 날 수 있어 drawCircle로 처리
    if (isFullCircle) {
      canvas.drawCircle(center, outerRadius, outerBackgroundPaint);
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        maxAngle,
        false,
        outerBackgroundPaint,
      );
    }

    // =========================
    // 외부 진행 (핵심 수정)
    // 99%와 100%를 "명확히" 분리:
    // - progress == 1.0: drawCircle + return (절대 drawArc로 덮지 않음)
    // - progress < 1.0: drawArc, 단 2π 근접을 피하기 위해 maxAngle - epsilon
    // =========================
    final clampedProgress = progress.clamp(0.0, 1.0);
    final clampedStartProgress = startProgress.clamp(0.0, 1.0);

    if (clampedProgress > clampedStartProgress) {
      final outerProgressPaint = Paint()
        ..color =
            progressColorStart // 단색 사용
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // 실제 진행률 계산 (startProgress 이후의 진행률)
      final actualProgress = clampedProgress - clampedStartProgress;

      // ✅ 100%는 무조건 완전 원 (startProgress가 0이고 progress가 1.0일 때)
      if (isFullCircle &&
          clampedStartProgress == 0.0 &&
          clampedProgress == 1.0) {
        canvas.drawCircle(center, outerRadius, outerProgressPaint);
        // 중요: 100%에서 drawArc가 실행되면 다시 "끊긴 호"가 덮여 보일 수 있으므로 즉시 종료
        // (내부 원/기준선은 계속 그려야 하므로 return 대신 플래그로 분리)
      } else {
        // 99% 이하는 절대 2π(=maxAngle)를 그리지 않도록 안전장치
        const double epsilon = 0.001; // 라디안
        final double safeMax = isFullCircle ? (maxAngle - epsilon) : maxAngle;

        // 시작 각도: startProgress만큼 회전
        final actualStartAngle = startAngle + (maxAngle * clampedStartProgress);
        // 스윕 각도: (progress - startProgress)만큼
        final sweepAngle = (maxAngle * actualProgress).clamp(0.0, safeMax);

        if (isDashed) {
          _drawDashedArc(
            canvas,
            center,
            outerRadius,
            actualStartAngle,
            sweepAngle,
            outerProgressPaint,
          );
        } else {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: outerRadius),
            actualStartAngle,
            sweepAngle,
            false,
            outerProgressPaint,
          );
        }
      }
    }

    // =========================
    // 내부 원 (원형일 때만)
    // =========================
    if (isFullCircle && (innerProgress != null || is24HourClock)) {
      final innerBgColor =
          innerBackgroundColor ?? backgroundColor.withOpacity(0.5);
      final innerFgColorStart =
          innerProgressColorStart ?? progressColorStart.withOpacity(0.7);
      final innerStroke = innerStrokeWidth ?? (strokeWidth * 0.7);

      if (is24HourClock) {
        final currentTimeProgress =
        (innerProgress ??
            (() {
              final now = DateTime.now();
              final currentHour = now.hour;
              final currentMinute = now.minute;
              return (currentHour + currentMinute / 60.0) / 24.0;
            }()))
            .clamp(0.0, 1.0);

        final innerProgressPaint = Paint()
          ..color = innerFgColorStart
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerStroke
          ..strokeCap = StrokeCap.round;

        // 내부도 2π 근접 seam 방지
        const double epsilon = 0.001;
        final safeMax = maxAngle - epsilon;
        final currentTimeSweepAngle = (maxAngle * currentTimeProgress).clamp(
          0.0,
          safeMax,
        );

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          currentTimeSweepAngle,
          false,
          innerProgressPaint,
        );

        // 알람 단추 표시
        if (alarmHours != null && alarmHours!.isNotEmpty) {
          final outerCirclePaint = Paint()
            ..color = const Color(0xFFFF8C42)
            ..style = PaintingStyle.fill;

          final innerCirclePaint = Paint()
            ..color = innerBgColor
            ..style = PaintingStyle.fill;

          for (final alarmHour in alarmHours!) {
            final alarmProgress = (alarmHour / 24.0).clamp(0.0, 1.0);
            final alarmAngle = startAngle + (maxAngle * alarmProgress);

            final circleCenter = Offset(
              center.dx + innerRadius * math.cos(alarmAngle),
              center.dy + innerRadius * math.sin(alarmAngle),
            );

            final outerCircleRadius = innerStroke / 2;
            final innerCircleRadius = outerCircleRadius * 0.8;

            canvas.drawCircle(
              circleCenter,
              outerCircleRadius,
              outerCirclePaint,
            );
            canvas.drawCircle(
              circleCenter,
              innerCircleRadius,
              innerCirclePaint,
            );
          }
        }
      } else if (innerProgress != null && innerProgress! > 0) {
        final p = innerProgress!.clamp(0.0, 1.0);

        final innerProgressPaint = Paint()
          ..color = innerFgColorStart
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerStroke
          ..strokeCap = StrokeCap.round;

        if (p == 1.0) {
          // 내부도 100%면 완전 원
          canvas.drawCircle(center, innerRadius, innerProgressPaint);
        } else {
          const double epsilon = 0.001;
          final safeMax = maxAngle - epsilon;
          final innerSweepAngle = (maxAngle * p).clamp(0.0, safeMax);

          canvas.drawArc(
            Rect.fromCircle(center: center, radius: innerRadius),
            startAngle,
            innerSweepAngle,
            false,
            innerProgressPaint,
          );
        }
      }
    }

    // =========================
    // 기준선
    // =========================
    if (targetLinePosition != null) {
      final t = targetLinePosition!.clamp(0.0, 1.0);

      final targetAngle = isFullCircle
          ? (-math.pi / 2) + (2 * math.pi * t)
          : math.pi + (math.pi * t);

      final outerInnerRadius = outerRadius - (strokeWidth / 2) + 2;
      final outerOuterRadius = outerRadius + (strokeWidth / 2) - 2;

      final outerLineStartPoint = Offset(
        center.dx + outerInnerRadius * math.cos(targetAngle),
        center.dy + outerInnerRadius * math.sin(targetAngle),
      );
      final outerLineEndPoint = Offset(
        center.dx + outerOuterRadius * math.cos(targetAngle),
        center.dy + outerOuterRadius * math.sin(targetAngle),
      );

      final linePaint = Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final shadowPaint = Paint()
        ..color = const Color(0xFFFFC107).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // 외부 그림자 + 라인
      canvas.drawLine(
        Offset(outerLineStartPoint.dx + 1, outerLineStartPoint.dy + 1),
        Offset(outerLineEndPoint.dx + 1, outerLineEndPoint.dy + 1),
        shadowPaint,
      );
      canvas.drawLine(outerLineStartPoint, outerLineEndPoint, linePaint);

      // 내부 기준선 (innerProgress가 있을 때만)
      if (innerProgress != null) {
        final innerStroke = innerStrokeWidth ?? (strokeWidth * 0.7);
        final innerInnerRadius = innerRadius - (innerStroke / 2) + 2;
        final innerOuterRadius = innerRadius + (innerStroke / 2) - 2;

        final innerLineStartPoint = Offset(
          center.dx + innerInnerRadius * math.cos(targetAngle),
          center.dy + innerInnerRadius * math.sin(targetAngle),
        );
        final innerLineEndPoint = Offset(
          center.dx + innerOuterRadius * math.cos(targetAngle),
          center.dy + innerOuterRadius * math.sin(targetAngle),
        );

        canvas.drawLine(
          Offset(innerLineStartPoint.dx + 1, innerLineStartPoint.dy + 1),
          Offset(innerLineEndPoint.dx + 1, innerLineEndPoint.dy + 1),
          shadowPaint,
        );
        canvas.drawLine(innerLineStartPoint, innerLineEndPoint, linePaint);
      }
    }
  }

  // 점선 호 그리기
  void _drawDashedArc(
      Canvas canvas,
      Offset center,
      double radius,
      double startAngle,
      double sweepAngle,
      Paint paint,
      ) {
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
      );

    for (final pathMetric in path.computeMetrics()) {
      final length = pathMetric.length;
      double distance = 0.0;
      bool draw = true;

      while (distance < length) {
        final segLen = draw ? dashWidth : dashGap;
        final next = (distance + segLen).clamp(0.0, length);

        if (draw && next > distance) {
          final t0 = pathMetric.getTangentForOffset(distance);
          final t1 = pathMetric.getTangentForOffset(next);
          if (t0 != null && t1 != null) {
            final dashPaint = Paint()
              ..color = paint.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = paint.strokeWidth
              ..strokeCap = StrokeCap.round;

            canvas.drawLine(t0.position, t1.position, dashPaint);
          }
        }

        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SemiGaugePainter oldDelegate) => true;
}
