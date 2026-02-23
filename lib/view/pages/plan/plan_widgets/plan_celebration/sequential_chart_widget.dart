import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'plan_summary_chart_painter.dart';
import 'package:sotong_local/component/buttons/multi_option_toggle.dart';

/// totalplan.dart에서 사용:
/// SequentialChartWidget(charts: charts)
class SequentialChartWidget extends StatefulWidget {
  final List<ChartData> charts;

  const SequentialChartWidget({super.key, required this.charts});

  @override
  State<SequentialChartWidget> createState() => _SequentialChartWidgetState();
}

/// ✅ totalplan.dart가 ChartData(progress: ...)로 만들고 있으므로
/// 필드명을 progress로 맞춤.
/// - progress는 0.0~1.0 (권장)
/// - 0~100이 들어올 가능성이 있으면 아래 clamp에서 자동 변환도 처리함.
class ChartData {
  final String title;
  final double progress; // 0.0~1.0 (또는 0~100 들어와도 보정 가능)
  final Color color;
  final String? subtitle;
  final String? description; // subtitle의 별칭 (호환성)

  const ChartData({
    required this.title,
    required this.progress,
    required this.color,
    this.subtitle,
    this.description,
  });
}

class _SequentialChartWidgetState extends State<SequentialChartWidget>
    with TickerProviderStateMixin {
  late final AnimationController _fillController; // 0 -> targetProgress
  Timer? _hapticTimer;

  int _currentIndex = 0;
  double _targetProgress = 0.0; // 0~1
  String _selectedToggle = ''; // 선택된 토글

  // 토글 라벨 리스트
  List<String> get _toggleLabels => ['절제 달성률', '평균 저축률', '목표 달성률'];

  @override
  void initState() {
    super.initState();

    // 초기 선택: 첫 번째 토글
    if (widget.charts.isNotEmpty) {
      _selectedToggle = _toggleLabels[0];
    }

    // 0 -> targetProgress 애니메이션
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 초기 차트 설정
    if (widget.charts.isNotEmpty) {
      _setCurrentItem(0);
    }
  }

  double _normalizeProgress(double p) {
    // p가 0~1이면 그대로
    if (p <= 1.0) return p.clamp(0.0, 1.0);
    // p가 0~100으로 들어오면 0~1로 변환
    return (p / 100.0).clamp(0.0, 1.0);
  }

  /// 원형 그래프 애니(1500ms)에 맞춰 쫘라락 햅틱 (15회, 100ms 간격)
  void _playChartSequentialHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    int count = 1;
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || count >= 15) {
        _hapticTimer?.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      count++;
    });
  }

  void _setCurrentItem(int index) {
    if (widget.charts.isEmpty || index < 0 || index >= widget.charts.length) {
      _targetProgress = 0.0;
      return;
    }
    _targetProgress = _normalizeProgress(widget.charts[index].progress);
    _fillController.reset();
    _fillController.forward(from: 0.0);
    _playChartSequentialHaptic();
  }

  void _onToggleChanged(String selectedLabel) {
    final index = _toggleLabels.indexOf(selectedLabel);
    if (index >= 0 && index < widget.charts.length) {
      setState(() {
        _selectedToggle = selectedLabel;
        _currentIndex = index;
      });
      _setCurrentItem(index);
    }
  }

  @override
  void didUpdateWidget(covariant SequentialChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.charts != widget.charts) {
      _currentIndex = 0;
      _setCurrentItem(0);
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _fillController.dispose();
    super.dispose();
  }

  int _displayPercent(double normalizedProgress) {
    // 표시용: 0~1 -> 0~100
    return (normalizedProgress * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.charts.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = widget.charts[_currentIndex];
    final normalized = _normalizeProgress(item.progress);
    final percent = _displayPercent(normalized);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 토글 버튼 (선택된 칩 너비를 칸의 85%로 제한 → 좌우 여백)
        MultiOptionToggle(
          labels: _toggleLabels,
          selected: _selectedToggle,
          onChanged: _onToggleChanged,
          width: 320,
          height: 30,
          indicatorWidthRatio: 0.85,
        ),
        const SizedBox(height: 50), // 토글과 차트 사이 패딩
        // 차트 위젯 (퍼센트에 따라 색상 결정)
        _SingleChartWidget(
          percent: percent,
          fillController: _fillController,
          targetProgress: normalized,
        ),
      ],
    );
  }
}

class _SingleChartWidget extends StatelessWidget {
  final int percent; // 0~100 (표시용)
  final AnimationController fillController;
  final double targetProgress; // 0~1

  const _SingleChartWidget({
    required this.percent,
    required this.fillController,
    required this.targetProgress,
  });

  // 퍼센트에 따른 색상 결정
  Color _getColorByPercent(int percent) {
    if (percent >= 70) {
      return const Color(0xFF0062FF);
    } else if (percent >= 40) {
      return const Color(0xFF6BCF7F);
    } else {
      return const Color(0xFFFF8A8A);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 200;
    const double strokeWidth = 21.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgRingColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF1F1F1);

    return AnimatedBuilder(
      animation: fillController,
      builder: (context, _) {
        final fillValue = CurvedAnimation(
          parent: fillController,
          curve: Curves.easeOutCubic,
        ).value;
        final animatedProgress = (fillValue * targetProgress).clamp(0.0, 1.0);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(size, size),
                  painter: PlanSummaryChartPainter(
                    progress: 1.0,
                    backgroundColor: bgRingColor,
                    progressColor: bgRingColor,
                    strokeWidth: strokeWidth,
                  ),
                ),
                CustomPaint(
                  size: const Size(size, size),
                  painter: PlanSummaryChartPainter(
                    progress: animatedProgress,
                    backgroundColor: Colors.transparent,
                    progressColor: _getColorByPercent(percent),
                    strokeWidth: strokeWidth,
                  ),
                ),
                Text(
                  '${(fillValue * percent).round()}%',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
