import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sotong/component/chart/semi_gauge_chart.dart';
import 'package:sotong/component/theme/app_colors.dart';
import 'package:sotong/services/chart_animation_haptic.dart';
import 'package:sotong/services/tab_chart_animation_notifier.dart';
import 'package:sotong/view_model/home/home_view_model.dart';

import 'home_saving_center_button.dart';

class HomeSavingChartWidget extends StatefulWidget {
  const HomeSavingChartWidget({
    super.key,
    required this.vm,
    required this.planPercent,
    required this.userPercent,
    this.replayGaugeAnimation = false,
    this.animationTrigger = 0,
    required this.onOpenCountdown,
  });

  final HomeViewModel vm;
  final double planPercent;
  final double userPercent;
  final bool replayGaugeAnimation;
  final int animationTrigger;
  final VoidCallback onOpenCountdown;

  static void resetGaugeAnimationForPlay() {
    _homeGaugeAnimationPlayed = false;
  }

  @override
  State<HomeSavingChartWidget> createState() => HomeSavingChartWidgetState();
}

bool _homeGaugeAnimationPlayed = false;

class HomeSavingChartWidgetState extends State<HomeSavingChartWidget>
    with TickerProviderStateMixin {
  static const _gaugeAnimationDuration = Duration(milliseconds: 1600);
  static const _hapticInterval = Duration(milliseconds: 110);
  static const _autoResetDuration = Duration(seconds: 5);

  String? _focusedSection; // null = both, 'plan' | 'user'
  int? _syncedHomeTick;

  late final AnimationController _gaugeController;
  late final Animation<double> _gaugeAnim;
  final ChartAnimationHapticPlayer _chartHaptic = ChartAnimationHapticPlayer();
  Timer? _autoResetTimer;

  @override
  void initState() {
    super.initState();

    _gaugeController = AnimationController(
      duration: _gaugeAnimationDuration,
      vsync: this,
    );

    _gaugeAnim = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );

    _restartGaugeAnimation(force: widget.replayGaugeAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_homeGaugeAnimationPlayed) {
        _restartGaugeAnimation(force: widget.replayGaugeAnimation);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeSavingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.replayGaugeAnimation && widget.replayGaugeAnimation) {
      resetToDefaultView(animate: true);
      return;
    }

    if (oldWidget.animationTrigger != widget.animationTrigger &&
        widget.animationTrigger > 0) {
      _syncedHomeTick = widget.animationTrigger;
      _replayGaugeFromTab();
      return;
    }

    if (oldWidget.planPercent != widget.planPercent ||
        oldWidget.userPercent != widget.userPercent) {
      if (widget.replayGaugeAnimation) return;
      resetToDefaultView(animate: true);
    }
  }

  /// 홈 배경 탭 등 외부에서 기본(겹침) 뷰로 복귀
  void resetToDefaultView({bool animate = true}) {
    _autoResetTimer?.cancel();
    _autoResetTimer = null;

    if (_focusedSection == null) return;

    setState(() => _focusedSection = null);

    if (animate) {
      _playGaugeAnimation();
    } else {
      _gaugeController.value = 1.0;
    }
  }

  void _restartGaugeAnimation({bool force = false}) {
    if (_homeGaugeAnimationPlayed && !force) {
      _gaugeController.value = 1.0;
      return;
    }
    _homeGaugeAnimationPlayed = true;
    _playGaugeAnimation();
  }

  void _selectSection(String section) {
    _autoResetTimer?.cancel();

    setState(() => _focusedSection = section);
    _playGaugeAnimation();
    _startAutoResetTimer();
  }

  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(_autoResetDuration, () {
      if (!mounted) return;
      if (_focusedSection == null) return;
      resetToDefaultView(animate: true);
    });
  }

  void _playGaugeAnimation() {
    _gaugeController
      ..stop()
      ..reset()
      ..forward();
    _playGaugeSequentialHaptic();
  }

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _chartHaptic.cancel();
    _gaugeController.dispose();
    super.dispose();
  }

  void _syncHomeTabAnimationTrigger(BuildContext context) {
    final homeTick = context.homeChartAnimationTick;
    if (_syncedHomeTick == null) {
      _syncedHomeTick = homeTick;
      if (homeTick > 0) {
        _scheduleReplayGaugeFromTab();
      }
      return;
    }
    if (homeTick == _syncedHomeTick) return;

    _syncedHomeTick = homeTick;
    _scheduleReplayGaugeFromTab();
  }

  void _scheduleReplayGaugeFromTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _replayGaugeFromTab();
    });
  }

  /// 홈 탭 재선택 시 기본 겹침 뷰 + 게이지 애니메이션 재생
  void _replayGaugeFromTab() {
    _autoResetTimer?.cancel();
    _autoResetTimer = null;

    if (_focusedSection != null) {
      setState(() => _focusedSection = null);
    }

    _playGaugeAnimation();
  }

  void _playGaugeSequentialHaptic() {
    _chartHaptic.play(
      duration: _gaugeAnimationDuration,
      interval: _hapticInterval,
    );
  }

  List<Widget> _buildGaugeProgressLayers({
    required double animValue,
    required double planProgress,
    required double userProgress,
    required Color planColor,
    required Color userColor,
    required String? focusedSection,
  }) {
    if (focusedSection == 'plan') {
      return [
        _gaugeArc(
          progress: animValue * planProgress,
          color: planColor,
          isDashed: false,
        ),
      ];
    }

    if (focusedSection == 'user') {
      return [
        _gaugeArc(
          progress: animValue * userProgress,
          color: userColor,
          isDashed: false,
        ),
      ];
    }

    final isSamePercent = (planProgress - userProgress).abs() < 0.005;
    if (isSamePercent) {
      return [
        _gaugeArc(
          progress: animValue * planProgress,
          color: planColor,
          isDashed: false,
        ),
      ];
    }

    final smallerProgress = math.min(planProgress, userProgress);
    final largerProgress = math.max(planProgress, userProgress);
    final isUserLarger = userProgress > planProgress;
    final smallerColor = isUserLarger ? planColor : userColor;
    final largerColor = isUserLarger ? userColor : planColor;

    return [
      _gaugeArc(
        progress: animValue * largerProgress,
        color: largerColor,
        isDashed: false,
      ),
      _gaugeArc(
        progress: animValue * smallerProgress,
        color: smallerColor,
        isDashed: true,
      ),
    ];
  }

  Widget _gaugeArc({
    required double progress,
    required Color color,
    required bool isDashed,
  }) {
    return CustomPaint(
      size: const Size(300, 300),
      painter: SemiGaugePainter(
        startProgress: 0.0,
        progress: progress,
        backgroundColor: Colors.transparent,
        progressColorStart: color,
        progressColorEnd: color,
        strokeWidth: 22,
        isFullCircle: true,
        isDashed: isDashed,
        dashWidth: 12.0,
        dashGap: 6.0,
      ),
    );
  }

  Widget _buildGaugeStack({
    required Color gaugeBg,
    required double planProgress,
    required double userProgress,
    required Color planColor,
    required Color userColor,
  }) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _gaugeAnim,
        child: CustomPaint(
          size: const Size(300, 300),
          painter: SemiGaugePainter(
            progress: 1.0,
            backgroundColor: gaugeBg,
            progressColorStart: gaugeBg,
            progressColorEnd: gaugeBg,
            strokeWidth: 22,
            isFullCircle: true,
          ),
        ),
        builder: (context, child) {
          final layers = _buildGaugeProgressLayers(
            animValue: _gaugeAnim.value,
            planProgress: planProgress,
            userProgress: userProgress,
            planColor: planColor,
            userColor: userColor,
            focusedSection: _focusedSection,
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              child!,
              ...layers,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncHomeTabAnimationTrigger(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gaugeBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF1F1F1);

    final planProgress = (widget.planPercent / 100.0).clamp(0.0, 1.0);
    final userProgress = (widget.userPercent / 100.0).clamp(0.0, 1.0);
    final planColor = AppColors.primary;
    final userColor = const Color(0xFF7DAFFF);
    final viewHeight = MediaQuery.sizeOf(context).height;
    final gaugeLegendGap = viewHeight < 750
        ? 16.0
        : viewHeight < 820
        ? 20.0
        : 24.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildGaugeStack(
                  gaugeBg: gaugeBg,
                  planProgress: planProgress,
                  userProgress: userProgress,
                  planColor: planColor,
                  userColor: userColor,
                ),
                HomeSavingCenterButton(
                  vm: widget.vm,
                  clickedSection: _focusedSection,
                  onCloseSection: () => resetToDefaultView(animate: true),
                  onOpenCountdown: widget.onOpenCountdown,
                ),
              ],
            ),
          ),
          SizedBox(height: gaugeLegendGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: planColor,
                text: '플랜 그래프',
                textColor: planColor,
                selected: _focusedSection == 'plan',
                onTap: () => _selectSection('plan'),
              ),
              const SizedBox(width: 20),
              _LegendDot(
                color: userColor,
                text: '사용자 그래프',
                textColor: userColor,
                selected: _focusedSection == 'user',
                onTap: () => _selectSection('user'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.text,
    required this.textColor,
    this.selected = false,
    this.onTap,
  });

  final Color color;
  final String text;
  final Color textColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final legend = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.45) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return legend;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.buttonTap();
          onTap!();
        },
        borderRadius: BorderRadius.circular(999),
        child: legend,
      ),
    );
  }
}
