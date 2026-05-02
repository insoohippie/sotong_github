import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PieModel {
  final int count;
  final Color color;
  PieModel({required this.count, required this.color});
}

class HalfDonutCard extends StatelessWidget {
  final int dDay;
  final String goalAmount;
  final int outerProgress;
  final int innerProgress;
  final bool state;

  const HalfDonutCard({
    super.key,
    required this.dDay,
    required this.goalAmount,
    required this.outerProgress,
    required this.innerProgress,
    this.state = true,
  });

  @override
  Widget build(BuildContext context) {
    // 색상 설정 (이미지 색상 사용)
    Color primaryColor = state ? Colors.blue.shade300 : Colors.red.shade300;
    Color secondaryColor = state ? Colors.blue.shade100 : Colors.red.shade100;
    Color elapsedPeriodColor = state
        ? const Color(0xFFB9D2FF) // 진행한 기간 - 연한 파랑
        : Colors.red.shade300;
    Color remainingPeriodColor = state
        ? const Color(0xFF3C7BFF) // 목표 달성까지 - 진한 파랑
        : Colors.red.shade700;
    Color textColor = state ? Colors.blue : Colors.red;

    // 그래프 데이터 계산
    int outerRemaining = 100 - outerProgress;
    int innerRemaining = 100 - innerProgress;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: state ? Colors.blue.shade50 : Colors.red.shade50,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 제목과 D-Day 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '집 사자!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'D-$dDay',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '목표 금액까지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '$goalAmount원',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            // 반원 그래프
            SizedBox(
              width: 250,
              height: 150,
              child: CustomPaint(
                painter: _DoubleHalfRadialChart(
                  [
                    PieModel(count: outerProgress, color: primaryColor),
                    PieModel(count: outerRemaining, color: secondaryColor),
                  ],
                  [
                    PieModel(count: innerProgress, color: elapsedPeriodColor),
                    PieModel(
                      count: innerRemaining,
                      color: remainingPeriodColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 5, backgroundColor: elapsedPeriodColor),
                const SizedBox(width: 8),
                const Text('진행한 기간', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                CircleAvatar(radius: 5, backgroundColor: remainingPeriodColor),
                const SizedBox(width: 8),
                const Text('목표 달성까지', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 반원 그래프만 표시하는 위젯 (컨테이너 없이)
class HalfDonutChart extends StatelessWidget {
  final int outerProgress;
  final int innerProgress;
  final bool state;
  final double width;
  final double height;
  final bool showLegend;

  const HalfDonutChart({
    super.key,
    required this.outerProgress,
    required this.innerProgress,
    this.state = true,
    this.width = 250,
    this.height = 150,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    // 색상 설정 (이미지 색상 사용)
    // 외부 반원: 연한 파랑 (전체 기간 배경)
    Color primaryColor = state ? const Color(0xFFB9D2FF) : Colors.red.shade300;
    Color secondaryColor = state
        ? const Color(0xFFB9D2FF)
        : Colors.red.shade100;
    // 내부 반원: 진행한 기간(연한 파랑), 목표 달성까지(진한 파랑)
    Color elapsedPeriodColor = state
        ? const Color(0xFFB9D2FF) // 진행한 기간 - 연한 파랑 (이미지 색상)
        : Colors.red.shade300;
    Color remainingPeriodColor = state
        ? const Color(0xFF3C7BFF) // 목표 달성까지 - 진한 파랑 (이미지 색상)
        : Colors.red.shade700;

    // 그래프 데이터 계산
    int outerRemaining = 100 - outerProgress;
    int innerRemaining = 100 - innerProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _DoubleHalfRadialChart(
              [
                PieModel(count: outerProgress, color: primaryColor),
                PieModel(count: outerRemaining, color: secondaryColor),
              ],
              [
                PieModel(count: innerProgress, color: elapsedPeriodColor),
                PieModel(count: innerRemaining, color: remainingPeriodColor),
              ],
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 16),
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 진행한 기간 (연한 파랑)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: elapsedPeriodColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '진행한 기간',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // 목표 달성까지 (진한 파랑)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: remainingPeriodColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '목표 달성까지',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DoubleHalfRadialChart extends CustomPainter {
  final List<PieModel> outerData;
  final List<PieModel> innerData;

  _DoubleHalfRadialChart(this.outerData, this.innerData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height);
    double outerRadius = size.width * 0.45;
    double innerRadius = size.width * 0.35;

    // 바깥 반원 (목표 진행률) - 덮어쓰기 방식
    double startAngle = 0;
    paint.strokeWidth = 20;

    // 큰 선 먼저 그리기
    paint.color = outerData[0].color;
    double firstSweepAngle = -math.pi * (outerData[0].count / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      firstSweepAngle,
      false,
      paint,
    );

    // 작은 선 그리기
    startAngle += firstSweepAngle;
    paint.color = outerData[1].color;
    double secondSweepAngle = -math.pi * (outerData[1].count / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      secondSweepAngle,
      false,
      paint,
    );

    // 다시 큰 선 덮어쓰기
    paint.color = outerData[0].color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      0,
      firstSweepAngle,
      false,
      paint,
    );

    // 안쪽 반원 (실제 진행률) - 덮어쓰기 방식
    startAngle = 0;
    paint.strokeWidth = 15;

    // 큰 선 먼저 그리기
    paint.color = innerData[0].color;
    double innerFirstSweepAngle = -math.pi * (innerData[0].count / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      innerFirstSweepAngle,
      false,
      paint,
    );

    // 작은 선 그리기
    startAngle += innerFirstSweepAngle;
    paint.color = innerData[1].color;
    double innerSecondSweepAngle = -math.pi * (innerData[1].count / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      innerSecondSweepAngle,
      false,
      paint,
    );

    // 다시 큰 선 덮어쓰기
    paint.color = innerData[0].color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      0,
      innerFirstSweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}