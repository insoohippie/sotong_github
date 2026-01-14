import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiGaugePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0 (외부 원)
  final Color backgroundColor;
  final Color progressColorStart;
  final Color progressColorEnd;
  final double strokeWidth;
  final double? targetLinePosition; // 기준선 위치 (0.0 ~ 1.0, null이면 표시 안 함)
  final bool isFullCircle; // true면 원형(360도), false면 반원(180도)
  final double startProgress; // 시작 지점 (0.0 ~ 1.0, 기본값 0.0)
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
    this.startProgress = 0.0, // 기본값 0.0 (처음부터 시작)
    this.isDashed = false, // 기본값 false (실선)
    this.dashWidth = 8.0, // 점선 대시 길이
    this.dashGap = 4.0, // 점선 간격
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
    final outerRadius = (isFullCircle ? size.width : size.width) / 2;
    // 내부 원 반지름: 외부 원의 stroke 두께를 고려하여 계산
    // 외부 원의 안쪽 가장자리에서 여유 공간을 두고 내부 원을 배치
    final innerRadius = (outerRadius - strokeWidth / 2) * innerRadiusRatio;

    // 배경 그리기: 반원이면 180도, 원형이면 360도
    final maxAngle = isFullCircle ? 2 * math.pi : math.pi;
    final startAngle = isFullCircle
        ? -math.pi / 2
        : math.pi; // 원형은 12시 방향부터, 반원은 왼쪽부터

    // 외부 원 배경 (startProgress부터 끝까지만 그리기)
    // 배경은 항상 전체를 그리지 않고, progress가 1.0이 아닐 때만 나머지 부분을 배경으로 그림
    // 하지만 각 섹션별로 배경을 그리려면, 배경도 startProgress부터 시작해야 함
    // 여기서는 배경을 전체로 그리되, 진행 게이지가 그려지면 덮어씌워지도록 함
    final outerBackgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 배경을 전체로 그리기 (진행 게이지가 없는 부분은 배경색으로 보임)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      maxAngle,
      false,
      outerBackgroundPaint,
    );

    // 외부 원 진행 게이지 (단색으로)
    if (progress > startProgress) {
      // 시작 각도: startProgress만큼 회전
      final actualStartAngle = startAngle + (maxAngle * startProgress);
      // 스윕 각도: (progress - startProgress)만큼
      final sweepAngle = maxAngle * (progress - startProgress);

      final outerProgressPaint = Paint()
        ..color =
            progressColorStart // 단색 사용
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isDashed) {
        // 점선으로 그리기
        _drawDashedArc(
          canvas,
          center,
          outerRadius,
          actualStartAngle,
          sweepAngle,
          outerProgressPaint,
        );
      } else {
        // 실선으로 그리기
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          actualStartAngle,
          sweepAngle,
          false,
          outerProgressPaint,
        );
      }
    }

    // 내부 원 그리기 (innerValue가 있거나 24시간 시계 모드일 때만 표시)
    if (isFullCircle && (innerProgress != null || is24HourClock)) {
      final innerBgColor =
          innerBackgroundColor ?? backgroundColor.withOpacity(0.5);
      final innerFgColorStart =
          innerProgressColorStart ?? progressColorStart.withOpacity(0.7);
      final innerFgColorEnd =
          innerProgressColorEnd ?? progressColorEnd.withOpacity(0.7);
      final innerStroke = innerStrokeWidth ?? (strokeWidth * 0.7);

      // 내부 원 배경 제거됨

      // 24시간 시계 모드인 경우 현재 시간 표시 (애니메이션 값 사용)
      if (is24HourClock && isFullCircle) {
        // innerProgress가 null이 아니면 애니메이션 값 사용, null이면 현재 시간 사용
        final currentTimeProgress =
            innerProgress ??
            (() {
              final now = DateTime.now();
              final currentHour = now.hour;
              final currentMinute = now.minute;
              return (currentHour + currentMinute / 60.0) / 24.0;
            }());
        final currentTimeSweepAngle = maxAngle * currentTimeProgress;

        final innerProgressPaint = Paint()
          ..color = innerFgColorStart
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerStroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          currentTimeSweepAngle,
          false,
          innerProgressPaint,
        );

        // 알람 시간에 단추 모양으로 표시 (주황색 외곽 + 내부 원 색상의 작은 원)
        if (alarmHours != null && alarmHours!.isNotEmpty) {
          // 주황색 외곽 원
          final outerCirclePaint = Paint()
            ..color =
                const Color(0xFFFF8C42) // 주황색 원
            ..style = PaintingStyle.fill;

          // 내부 원 배경 색상의 작은 원
          final innerCirclePaint = Paint()
            ..color =
                innerBgColor // 내부 원 배경과 동일한 색상
            ..style = PaintingStyle.fill;

          for (final alarmHour in alarmHours!) {
            // 알람 시간을 각도로 변환 (12시 방향이 -π/2)
            final alarmProgress = alarmHour / 24.0;
            final alarmAngle = startAngle + (maxAngle * alarmProgress);

            // 원의 중심: 내부 원의 중앙 위치
            final circleCenterRadius = innerRadius;
            final circleCenterX =
                center.dx + circleCenterRadius * math.cos(alarmAngle);
            final circleCenterY =
                center.dy + circleCenterRadius * math.sin(alarmAngle);
            final circleCenter = Offset(circleCenterX, circleCenterY);

            // 외곽 원의 반지름: 내부 원의 stroke 두께
            final outerCircleRadius = innerStroke / 2;

            // 내부 작은 원의 반지름: 외곽 원의 80%
            final innerCircleRadius = outerCircleRadius * 0.8;

            // 외곽 주황색 원 그리기
            canvas.drawCircle(
              circleCenter,
              outerCircleRadius,
              outerCirclePaint,
            );

            // 내부 작은 원 그리기 (단추 느낌)
            canvas.drawCircle(
              circleCenter,
              innerCircleRadius,
              innerCirclePaint,
            );
          }
        }
      } else if (innerProgress != null && innerProgress! > 0) {
        // 일반 모드: 내부 원 진행 게이지 (단색으로)
        final innerSweepAngle = maxAngle * innerProgress!;

        final innerProgressPaint = Paint()
          ..color =
              innerFgColorStart // 단색 사용
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerStroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          innerSweepAngle,
          false,
          innerProgressPaint,
        );
      }
      // 내부 원만 배경으로 표시 (진행률이 없을 때는 배경만 표시됨)
    }

    // 기준선 그리기 (중심에서 일정 거리로 뻗어나가는 선)
    if (targetLinePosition != null &&
        targetLinePosition! >= 0 &&
        targetLinePosition! <= 1.0) {
      // 기준선 각도 계산: 반원이면 왼쪽부터, 원형이면 12시 방향부터
      final targetAngle = isFullCircle
          ? (-math.pi / 2) + (2 * math.pi * targetLinePosition!.clamp(0.0, 1.0))
          : math.pi + (math.pi * targetLinePosition!.clamp(0.0, 1.0));

      // 외부 원 기준선
      final outerInnerRadius = outerRadius - (strokeWidth / 2) + 2;
      final outerOuterRadius = outerRadius + (strokeWidth / 2) - 2;

      final outerLineStartX =
          center.dx + outerInnerRadius * math.cos(targetAngle);
      final outerLineStartY =
          center.dy + outerInnerRadius * math.sin(targetAngle);
      final outerLineStartPoint = Offset(outerLineStartX, outerLineStartY);

      final outerLineEndX =
          center.dx + outerOuterRadius * math.cos(targetAngle);
      final outerLineEndY =
          center.dy + outerOuterRadius * math.sin(targetAngle);
      final outerLineEndPoint = Offset(outerLineEndX, outerLineEndY);

      final linePaint = Paint()
        ..color =
            const Color(0xFFFFC107) // 노란색
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      // 그림자 효과
      final shadowPaint = Paint()
        ..color = const Color(0xFFFFC107).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // 외부 원 기준선 그림자
      canvas.drawLine(
        Offset(outerLineStartPoint.dx + 1, outerLineStartPoint.dy + 1),
        Offset(outerLineEndPoint.dx + 1, outerLineEndPoint.dy + 1),
        shadowPaint,
      );

      // 외부 원 기준선
      canvas.drawLine(outerLineStartPoint, outerLineEndPoint, linePaint);

      // 내부 원 기준선 (내부 원이 있을 때만)
      if (innerProgress != null) {
        final innerStroke = innerStrokeWidth ?? (strokeWidth * 0.7);
        final innerInnerRadius = innerRadius - (innerStroke / 2) + 2;
        final innerOuterRadius = innerRadius + (innerStroke / 2) - 2;

        final innerLineStartX =
            center.dx + innerInnerRadius * math.cos(targetAngle);
        final innerLineStartY =
            center.dy + innerInnerRadius * math.sin(targetAngle);
        final innerLineStartPoint = Offset(innerLineStartX, innerLineStartY);

        final innerLineEndX =
            center.dx + innerOuterRadius * math.cos(targetAngle);
        final innerLineEndY =
            center.dy + innerOuterRadius * math.sin(targetAngle);
        final innerLineEndPoint = Offset(innerLineEndX, innerLineEndY);

        // 내부 원 기준선 그림자
        canvas.drawLine(
          Offset(innerLineStartPoint.dx + 1, innerLineStartPoint.dy + 1),
          Offset(innerLineEndPoint.dx + 1, innerLineEndPoint.dy + 1),
          shadowPaint,
        );

        // 내부 원 기준선
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
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
    );

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final length = pathMetric.length;
      double distance = 0.0;
      bool draw = true;

      while (distance < length) {
        final len = draw ? dashWidth : dashGap;
        final next = (distance + len).clamp(0.0, length);

        if (draw && next > distance) {
          final tangentStart = pathMetric.getTangentForOffset(distance);
          final tangentEnd = pathMetric.getTangentForOffset(next);

          if (tangentStart != null && tangentEnd != null) {
            // 점선 세그먼트를 그릴 때 strokeCap을 적용
            final dashPaint = Paint()
              ..color = paint.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = paint.strokeWidth
              ..strokeCap = StrokeCap.round;

            canvas.drawLine(
              tangentStart.position,
              tangentEnd.position,
              dashPaint,
            );
          }
        }

        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

