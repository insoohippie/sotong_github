import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 금액 → "만원" 포맷
String _manWon(num v) {
  if (v <= 0) return '0만원';
  final man = (v / 10000).round();
  return '$man만원';
}

/// 🎨 색상 팔레트: 저축(파랑), 소비(회색 2톤)
const _cSave = Color(0xFF3C7BFF); // 저축
const _cFixed = Color(0xFFE5E7EB); // 월 고정소비 (연한 회색, gray-300)
const _cVar = Color(0xFF9CA3AF); // 일일 소비×30 (진한 회색, gray-500)

/// 오버 예산 시: 저축만 빨강, 소비는 회색 2톤 유지
const _cSaveOver = Color(0xFFDC2626); // 저축 없음 → 빨강

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
    this.fanDuration = const Duration(milliseconds: 1000),
    this.fanStagger = 0.18,
    this.fanCurve = Curves.easeOutCubic,

    // pop(동시 팝업) 애니메이션
    this.popDuration = const Duration(milliseconds: 600),
    this.popCurve = Curves.easeOutBack,

    /// true면 오버 예산용 색상(저축 파랑, 소비 연한 빨강 2톤) + 첫 레이블 "저축"
    this.isOverBudget = false,

    /// 등장 애니메이션 완료 시 호출 (아래 텍스트 갱신용)
    this.onEnterComplete,

    /// 변경 시 차트 애니메이션 재시작 (목표금액/보유자산 변경 시 사용)
    this.animationTrigger,
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

  final bool isOverBudget;

  final VoidCallback? onEnterComplete;

  /// 변경 시 애니메이션 재시작 (목표금액/보유자산 등)
  final Object? animationTrigger;

  @override
  State<FlDonutColoredBudgetChart> createState() =>
      FlDonutColoredBudgetChartState();
}

class FlDonutColoredBudgetChartState extends State<FlDonutColoredBudgetChart>
    with TickerProviderStateMixin {
  int touchedIndex = 0; // 기본: 저축(0번)
  late final AnimationController _ac;
  late final AnimationController _exitController;
  Timer? _hapticTimer;

  // 데이터 캐시
  late List<double> _rawValues; // [save, fixed, var]
  late List<double> _areaValues; // 최소면적 보정 후 면적 값

  /// 값 변경 시: 이전 차트(사라지는 쪽) 데이터
  List<double>? _prevRawValues;
  List<double>? _prevAreaValues;
  bool _prevIsOverBudget = false;

  /// exit 애니메이션 끝난 뒤 true → 새 차트 fan-in 표시
  bool _exitingDone = true;

  _AnimMode _mode = _AnimMode.fan;

  static const _exitDuration = Duration(milliseconds: 500);
  static const _delayBetweenExitAndEnter = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.fanDuration);
    _exitController = AnimationController(vsync: this, duration: _exitDuration);
    _ac.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onEnterComplete?.call();
      }
    });
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(_delayBetweenExitAndEnter, () {
          if (!mounted) return;
          setState(() => _exitingDone = true);
          _ac.forward(from: 0);
          _exitController.reset();
          _playEnterHaptic();
        });
      }
    });
    _recomputeData();
    _ac.forward(from: 0);
    _playEnterHaptic();
  }

  void _playEnterHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    final isFan = _mode == _AnimMode.fan;
    final interval = isFan
        ? const Duration(milliseconds: 130)
        : const Duration(milliseconds: 85);
    final count = isFan ? 8 : 7;
    int n = 1;
    _hapticTimer = Timer.periodic(interval, (timer) {
      if (!mounted || n >= count) {
        timer.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      n++;
    });
  }

  void _playExitHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    const interval = Duration(milliseconds: 70);
    const count = 7;
    int n = 1;
    _hapticTimer = Timer.periodic(interval, (timer) {
      if (!mounted || n >= count) {
        timer.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      n++;
    });
  }

  @override
  void didUpdateWidget(covariant FlDonutColoredBudgetChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged =
        oldWidget.income != widget.income ||
        oldWidget.fixed != widget.fixed ||
        oldWidget.variable != widget.variable ||
        oldWidget.saving != widget.saving ||
        oldWidget.minRatio != widget.minRatio ||
        oldWidget.isOverBudget != widget.isOverBudget ||
        oldWidget.animationTrigger != widget.animationTrigger;
    if (!dataChanged) return;

    // 이미 exit 애니메이션 중이면 재시작하지 않음 → 버벅임 방지
    if (!_exitingDone) {
      _recomputeData(); // 다음에 보일 차트 데이터만 최신으로 갱신
      return;
    }

    _prevRawValues = List<double>.from(_rawValues);
    _prevAreaValues = List<double>.from(_areaValues);
    _prevIsOverBudget = oldWidget.isOverBudget;
    _recomputeData();
    _exitingDone = false;
    _exitController.forward(from: 0);
    _playExitHaptic();
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _ac.dispose();
    _exitController.dispose();
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
    final double vSave = widget.saving.clamp(0, widget.income);
    final double vFixed = widget.fixed.clamp(0, widget.income);
    final double vVar = widget.variable.clamp(0, widget.income);
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
    for (final i in below) {
      out[i] = minRatio;
    }
    for (final i in above) {
      out[i] = ratios[i] / sumAbove * remaining;
    }
    return out;
  }

  // 섹션별 진행률(부채/팝 모드에 따라 산출)
  double _sectionProgress(int index, double t) {
    if (_mode == _AnimMode.pop) {
      return widget.popCurve.transform(t); // 동시에
    }
    // fan 모드: 인덱스별 지연 후 개별 커브
    final start = widget.fanStagger * index;
    final span = 1.0 - start;
    if (t <= start) return 0.0;
    final localT = ((t - start) / span).clamp(0.0, 1.0);
    return widget.fanCurve.transform(localT);
  }

  /// Exit 전용: 일일(2) → 고정(1) → 저축(0)이 겹치며 줄어들어 사라짐. "빨강만 전체" 구간 없음, 그래프가 다시 풀리는 동작 없음.
  /// 구간 겹침: 다음 섹션이 사라지기 전에 이전 섹션이 이미 줄어들기 시작.
  double _exitSectionProgress(int index, double exitT) {
    // 일일(2): [0, 0.4], 고정(1): [0.2, 0.6], 저축(0): [0.4, 1.0] → 겹침
    const segLen = 0.4;
    final segStart = (2 - index) * 0.2; // 2:0, 1:0.2, 0:0.4
    final segEnd = segStart + segLen; // 2:0.4, 1:0.6, 0:0.8 → 저축은 1.0까지
    final end = index == 0 ? 1.0 : segEnd;
    if (exitT <= segStart) return 1.0;
    if (exitT >= end) return 0.0;
    final localT = (exitT - segStart) / (end - segStart);
    return 1.0 - widget.fanCurve.transform(localT);
  }

  Widget _buildPieChart(
    List<double> rawValues,
    List<double> areaValues,
    bool isOverBudget,
    double progressT, {
    bool showBadges = true,
    bool isExit = false,
    double exitT = 0,
  }) {
    final colors = isOverBudget
        ? [_cSaveOver, _cFixed, _cVar]
        : [_cSave, _cFixed, _cVar];

    final animatedAreas = isExit
        ? List<double>.generate(
            areaValues.length,
            (i) => areaValues[i] * _exitSectionProgress(i, exitT),
          )
        : List<double>.generate(
            areaValues.length,
            (i) => areaValues[i] * _sectionProgress(i, progressT),
          );

    final labels = isOverBudget
        ? ['저축', '월 고정소비', '일일 소비×30']
        : ['저축 가능 금액', '월 고정소비', '일일 소비×30'];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < animatedAreas.length; i++) {
      final isTouched = i == touchedIndex;
      final radius = (i == 0) ? 64.0 : (isTouched ? 64.0 : 52.0);
      final shouldShowBadge = showBadges && animatedAreas[i] > 0.0001;

      sections.add(
        PieChartSectionData(
          color: colors[i],
          value: animatedAreas[i],
          radius: radius,
          title: '',
          badgePositionPercentageOffset: widget.badgeOutsideOffset,
          badgeWidget: shouldShowBadge
              ? _TextBadge(
                  labelTop: labels[i],
                  labelBottom: _manWon(rawValues[i]),
                  scale: (i == 0 || isTouched) ? 1.1 : 1.0,
                )
              : null,
        ),
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response?.touchedSection == null) {
              return;
            }
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
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.chartHeight,
      width: double.infinity,
      child: RepaintBoundary(
        child: _exitingDone
            ? AnimatedBuilder(
                animation: _ac,
                builder: (_, __) => _buildPieChart(
                  _rawValues,
                  _areaValues,
                  widget.isOverBudget,
                  _ac.value,
                ),
              )
            : AnimatedBuilder(
                animation: _exitController,
                builder: (_, __) => _buildPieChart(
                  _prevRawValues!,
                  _prevAreaValues!,
                  _prevIsOverBudget,
                  0,
                  showBadges: false,
                  isExit: true,
                  exitT: _exitController.value,
                ),
              ),
      ),
    );
  }
}

class _TextBadge extends StatelessWidget {
  const _TextBadge({
    required this.labelTop,
    required this.labelBottom,
    this.scale = 1.0,
  });

  final String labelTop;
  final String labelBottom;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1,
              ),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard Variable',
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              labelBottom,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard Variable',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
