import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 금액 → "만원" 포맷
String _manWon(num v) {
  if (v <= 0) return '0만원';
  final man = (v / 10000).round();
  return '$man만원';
}

/// 🎨 색상 팔레트: 저축(파랑), 소비(회색 2톤)
const _cSave = Color(0xFF3C7BFF); // 저축
const _cFixed = Color(0xFFE5E7EB); // 월 고정소비 (연한 회색, gray-300)
const _cVar = Color(0xFF9CA3AF);   // 일일 소비×30 (진한 회색, gray-500)

enum _AnimMode { fan, pop }

class FlDonutColoredBudgetChart extends StatefulWidget {
  const FlDonutColoredBudgetChart({
    super.key,
    required this.income,
    required this.fixed,
    required this.variable,
    required this.saving,
    this.centerSpace = 20,
    this.chartHeight = 120,
    this.badgeOutsideOffset = 1.15,

    // 애니메이션/표시 옵션
    this.minRatio = 0.15,

    // fan(부채) 애니메이션
    this.fanDuration = const Duration(milliseconds: 900),
    this.fanStagger = 0.18,
    this.fanCurve = Curves.easeOutCubic,

    // pop(동시 팝업) 애니메이션
    this.popDuration = const Duration(milliseconds: 600),
    this.popCurve = Curves.easeOutBack,
  });

  final double income;
  final double fixed;
  final double variable;
  final double saving;
  final double centerSpace;
  final double chartHeight;
  final double badgeOutsideOffset;

  /// 최소 면적 비율(시각화만; 금액 표기는 원본 유지)
  final double minRatio;

  /// 애니메이션 설정
  final Duration fanDuration;
  final double fanStagger;
  final Curve fanCurve;

  final Duration popDuration;
  final Curve popCurve;

  @override
  State<FlDonutColoredBudgetChart> createState() => FlDonutColoredBudgetChartState();
}

class FlDonutColoredBudgetChartState extends State<FlDonutColoredBudgetChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = 0; // 기본: 저축(0번)
  late final AnimationController _ac;

  // 데이터 캐시
  late List<double> _rawValues;   // [save, fixed, var]
  late List<double> _areaValues;  // 최소면적 보정 후 면적 값

  _AnimMode _mode = _AnimMode.fan;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.fanDuration);
    _recomputeData();
    _ac.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant FlDonutColoredBudgetChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.income   != widget.income ||
        oldWidget.fixed    != widget.fixed  ||
        oldWidget.variable != widget.variable ||
        oldWidget.saving   != widget.saving ||
        oldWidget.minRatio != widget.minRatio) {
      _recomputeData();
      _ac.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  /// 외부에서 재생 컨트롤
  void replay() {
    _ac.forward(from: 0);
  }

  void playFan() {
    setState(() {
      _mode = _AnimMode.fan;
      _ac.duration = widget.fanDuration;
    });
    _ac.forward(from: 0);
  }

  void playPop() {
    setState(() {
      _mode = _AnimMode.pop;
      _ac.duration = widget.popDuration;
    });
    _ac.forward(from: 0);
  }

  void _recomputeData() {
    final double vSave  = widget.saving.clamp(0, widget.income);
    final double vFixed = widget.fixed.clamp(0, widget.income);
    final double vVar   = widget.variable.clamp(0, widget.income);
    _rawValues = [vSave, vFixed, vVar];

    final totalVal = _rawValues.fold<double>(0, (a, b) => a + b);
    final ratios = totalVal == 0
        ? List<double>.filled(_rawValues.length, 1 / _rawValues.length)
        : _rawValues.map((v) => v / totalVal).toList();

    final adjRatios = _adjustMinRatios(ratios, widget.minRatio);
    _areaValues = adjRatios.map((r) => r * totalVal).toList();
  }

  /// 최소 비율 미만은 minRatio로 올리고, 나머지는 남은 비율에서 비례 재분배
  List<double> _adjustMinRatios(List<double> ratios, double minRatio) {
    final n = ratios.length;
    final below = <int>[];
    final above = <int>[];
    for (var i = 0; i < ratios.length; i++) {
      (ratios[i] < minRatio ? below : above).add(i);
    }
    final assignedToBelow = below.length * minRatio;
    final remaining = (1.0 - assignedToBelow).clamp(0.0, 1.0);
    final sumAbove = above.fold<double>(0.0, (a, i) => a + ratios[i]);

    if (sumAbove <= 0) {
      return List<double>.generate(n, (_) => 1.0 / n);
    }

    final out = List<double>.filled(n, 0.0);
    for (final i in below) out[i] = minRatio;
    for (final i in above) out[i] = ratios[i] / sumAbove * remaining;
    return out;
  }

  // 섹션별 진행률(부채/팝 모드에 따라 산출)
  double _sectionProgress(int index, double t) {
    if (_mode == _AnimMode.pop) {
      return widget.popCurve.transform(t); // 동시에
    }
    // fan 모드: 인덱스별 지연 후 개별 커브
    final start = widget.fanStagger * index;
    final span  = 1.0 - start;
    if (t <= start) return 0.0;
    final localT = ((t - start) / span).clamp(0.0, 1.0);
    return widget.fanCurve.transform(localT);
  }

  @override
  Widget build(BuildContext context) {
    // 인덱스 순서: [저축(파랑), 고정(빨강1), 변동(빨강2)]
    final labels = ['저축 가능 금액', '월 고정소비', '일일 소비×30'];
    final colors = [_cSave, _cFixed, _cVar];

    return SizedBox(
      height: widget.chartHeight,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) {
          final t = _ac.value;

          final animatedAreas = List<double>.generate(
            _areaValues.length,
                (i) => _areaValues[i] * _sectionProgress(i, t),
          );

          final sections = <PieChartSectionData>[];
          for (int i = 0; i < animatedAreas.length; i++) {
            final isTouched = i == touchedIndex;
            // 저축(0)은 항상 크게, 나머지는 터치 시만 크게
            final radius = (i == 0) ? 64.0 : (isTouched ? 64.0 : 52.0);

            final showBadge = animatedAreas[i] > 0.0001;
            sections.add(
              PieChartSectionData(
                color: colors[i],
                value: animatedAreas[i],            // 면적 애니메이션
                radius: radius,                     // 반지름 애니메이션(초기 0→목표)
                title: '',
                badgePositionPercentageOffset: widget.badgeOutsideOffset,
                badgeWidget: _TextBadge(
                  labelTop: labels[i],
                  labelBottom: _manWon(_rawValues[i]), // 금액은 원본 값 기준
                  scale: (i == 0 || isTouched) ? 1.1 : 1.0,
                  visible: showBadge,
                ),
              ),
            );
          }

          return PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.touchedSection == null) return;
                  setState(() {
                    touchedIndex = response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              centerSpaceRadius: widget.centerSpace,
              sections: sections,
            ),
          );
        },
      ),
    );
  }
}

class _TextBadge extends StatelessWidget {
  const _TextBadge({
    required this.labelTop,
    required this.labelBottom,
    this.scale = 1.0,
    this.visible = true,
  });

  final String labelTop;
  final String labelBottom;
  final double scale;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 88,
      height: 52,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelTop,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                labelBottom,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
