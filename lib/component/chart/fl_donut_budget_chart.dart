import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

String _manWon(num v) {
  if (v <= 0) return '0만원';
  final man = (v / 10000).round();
  return '$man만원';
}

const _cSave  = Color(0xFF3C7BFF);
const _cFixed = Color(0xFFB9D2FF);
const _cVar   = Color(0xFF8BB8FF);

enum _AnimMode { fan, pop }

class FlDonutBudgetChart extends StatefulWidget {
  const FlDonutBudgetChart({
    super.key,
    required this.income,
    required this.fixed,
    required this.variable,
    required this.saving,
    this.centerSpace = 40,
    this.chartHeight = 240,
    this.badgeOutsideOffset = 1.15,

    // 애니메이션 옵션
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

  final double minRatio;

  final Duration fanDuration;
  final double fanStagger;
  final Curve fanCurve;

  final Duration popDuration;
  final Curve popCurve;

  @override
  State<FlDonutBudgetChart> createState() => FlDonutBudgetChartState();
}

class FlDonutBudgetChartState extends State<FlDonutBudgetChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = 0; // 기본: 저축
  late final AnimationController _ac;

  // 데이터 캐시
  late List<double> _rawValues;   // [save, fixed, var]
  late List<double> _areaValues;  // 최소면적 보정된 면적 값

  _AnimMode _mode = _AnimMode.fan;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.fanDuration);
    _recomputeData();
    _ac.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant FlDonutBudgetChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.income != widget.income ||
        oldWidget.fixed  != widget.fixed ||
        oldWidget.variable != widget.variable ||
        oldWidget.saving != widget.saving ||
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

  /// 외부에서: 현재 모드로 재생
  void replay() {
    _ac.forward(from: 0);
  }

  /// 외부에서: 부채(순차) 재생
  void playFan() {
    setState(() {
      _mode = _AnimMode.fan;
      _ac.duration = widget.fanDuration;
    });
    _ac.forward(from: 0);
  }

  /// 외부에서: 동시(팝업) 재생
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

  // 섹션별 진행률(모드에 따라 다르게)
  double _sectionProgress(int index, double t) {
    if (_mode == _AnimMode.pop) {
      return widget.popCurve.transform(t); // 동시
    }
    // fan 모드: 섹션별 지연 + 커브
    final start = widget.fanStagger * index;
    final span  = 1.0 - start;
    if (t <= start) return 0.0;
    final localT = ((t - start) / span).clamp(0.0, 1.0);
    return widget.fanCurve.transform(localT);
  }

  @override
  Widget build(BuildContext context) {
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
            final radius = (i == 0) ? 64.0 : (isTouched ? 64.0 : 52.0);

            sections.add(
              PieChartSectionData(
                color: colors[i],
                value: animatedAreas[i],
                radius: radius,
                title: '',
                badgePositionPercentageOffset: widget.badgeOutsideOffset,
                badgeWidget: _TextBadge(
                  labelTop: labels[i],
                  labelBottom: _manWon(_rawValues[i]),
                  scale: (i == 0 || isTouched) ? 1.1 : 1.0,
                  visible: animatedAreas[i] > 0.0001,
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
    if (!visible) return const SizedBox.shrink();
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
