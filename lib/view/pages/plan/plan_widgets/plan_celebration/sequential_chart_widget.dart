import 'package:flutter/material.dart';
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

  void _setCurrentItem(int index) {
    if (widget.charts.isEmpty || index < 0 || index >= widget.charts.length) {
      _targetProgress = 0.0;
      return;
    }
    _targetProgress = _normalizeProgress(widget.charts[index].progress);
    _fillController.reset();
    _fillController.forward(from: 0.0);
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
        // 토글 버튼
        MultiOptionToggle(
          labels: _toggleLabels,
          selected: _selectedToggle,
          onChanged: _onToggleChanged,
          width: 320,
          height: 34,
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
      // 70~100: 파랑색
      return const Color(0xFF0062FF);
    } else if (percent >= 40) {
      // 40~69: 연한 초록색
      return const Color(0xFF6BCF7F);
    } else {
      // 0~39: 연한 빨강색
      return const Color(0xFFFF8A8A);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 200;
    const double strokeWidth = 21.0;

    return AnimatedBuilder(
      animation: fillController,
      builder: (context, _) {
        // 0 -> targetProgress 애니메이션
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
                // 배경 링
                CustomPaint(
                  size: const Size(size, size),
                  painter: const PlanSummaryChartPainter(
                    progress: 1.0,
                    backgroundColor: Color(0xFFF1F1F1),
                    progressColor: Color(0xFFF1F1F1),
                    strokeWidth: strokeWidth,
                  ),
                ),
                // 진행 링
                CustomPaint(
                  size: const Size(size, size),
                  painter: PlanSummaryChartPainter(
                    progress: animatedProgress,
                    backgroundColor: Colors.transparent,
                    progressColor: _getColorByPercent(percent),
                    strokeWidth: strokeWidth,
                  ),
                ),
                // 중앙 퍼센트 (카운트업 애니메이션 - fillController와 동기화)
                Text(
                  '${(fillValue * percent).round()}%',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
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
