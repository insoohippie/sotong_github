import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 진행 기간을 표시하는 막대 그래프
/// - 전체 기간 중 진행한 기간과 남은 기간을 두 가지 색상으로 표시
/// - 절약률은 표시하지 않음
class ProgressPeriodBarChart extends StatelessWidget {
  /// 플랜 시작일
  final DateTime startDate;

  /// 목표 달성 예정일
  final DateTime? goalDate;

  /// 차트 높이 (기본값: 120)
  final double height;

  /// 차트 패딩 (기본값: 20)
  final double padding;

  const ProgressPeriodBarChart({
    Key? key,
    required this.startDate,
    this.goalDate,
    this.height = 120,
    this.padding = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 목표일이 없으면 빈 컨테이너 반환
    if (goalDate == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final totalDuration = goalDate!.difference(startDate);
    final elapsedDuration = now.difference(startDate);
    final remainingDuration = goalDate!.difference(now);

    // 음수 처리 (목표일이 이미 지난 경우)
    final elapsedDays = elapsedDuration.inDays.clamp(0, totalDuration.inDays);
    final remainingDays = remainingDuration.inDays.clamp(0, totalDuration.inDays);

    final totalDays = totalDuration.inDays;
    if (totalDays <= 0) {
      return const SizedBox.shrink();
    }

    // 비율 계산 (0~1)
    final elapsedRatio = elapsedDays / totalDays;
    final remainingRatio = remainingDays / totalDays;

    // 색상 정의
    const lightBlue = Color(0xFFB9D2FF); // 진행한 기간 (연한 파란색)
    const darkBlue = Color(0xFF2F66FF); // 목표 달성까지 (진한 파란색)

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 수평 막대 그래프
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final barHeight = 30.0;
              
              final elapsedWidth = barWidth * elapsedRatio;
              final remainingWidth = barWidth * remainingRatio;
              
              return SizedBox(
                height: barHeight,
                child: Row(
                  children: [
                    // 진행한 기간 (연한 파란색)
                    if (elapsedWidth > 0)
                      Container(
                        width: elapsedWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    // 남은 기간 (진한 파란색)
                    if (remainingWidth > 0)
                      Container(
                        width: remainingWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: darkBlue,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 진행한 기간
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: lightBlue,
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
              // 목표 달성까지
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: darkBlue,
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
      ),
    );
  }
}
