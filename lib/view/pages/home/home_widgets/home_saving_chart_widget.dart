import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sotong_local/component/chart/semi_gauge_chart.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/view_model/home/home_view_model.dart';

import 'home_saving_center_button.dart';

class HomeSavingChartWidget extends StatefulWidget {
  const HomeSavingChartWidget({
    super.key,
    required this.vm,
    required this.planPercent, // 0~100, 소수 둘째 자리까지
    required this.userPercent, // 0~100, 소수 둘째 자리까지
    this.showIntro = false,
    this.onIntroDismissed,
    required this.onOpenCountdown, // 중앙 버튼 기본 상태 클릭 시
  });

  final HomeViewModel vm;
  final double planPercent;
  final double userPercent;
  final bool showIntro;
  final FutureOr<void> Function()? onIntroDismissed;
  final VoidCallback onOpenCountdown;

  /// 플랜 완료 후 홈 진입 시 애니메이션을 다시 재생하도록 플래그 리셋
  static void resetGaugeAnimationForPlay() {
    _homeGaugeAnimationPlayed = false;
  }

  @override
  State<HomeSavingChartWidget> createState() => _HomeSavingChartWidgetState();
}

/// 앱 세션 동안 홈 게이지 애니메이션 재생 여부 (플랜 완료 후 홈 진입 시 1회 재생)
bool _homeGaugeAnimationPlayed = false;

class _HomeSavingChartWidgetState extends State<HomeSavingChartWidget>
    with TickerProviderStateMixin {
  static const _gaugeAnimationDuration = Duration(milliseconds: 1600);
  static const _coachmarkDelay = Duration(milliseconds: 900);
  static const _hapticInterval = Duration(milliseconds: 200);
  static const _hapticCount = 8;

  String? _clickedSection; // 'plan' | 'user' | null

  late final AnimationController _gaugeController;
  late final Animation<double> _gaugeAnim;
  Timer? _hapticTimer;
  Timer? _coachmarkTimer;
  bool _showIntroCoachmark = false;

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

    // 🔥 1차: 즉시 시작 (중요)
    _restartGaugeAnimation(force: widget.showIntro);
    if (widget.showIntro) {
      _scheduleIntroCoachmark();
    }

    // 🔥 2차: 프레임 이후 보정 (이미 한 번 재생된 경우 스킵)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_homeGaugeAnimationPlayed) {
        _restartGaugeAnimation(force: widget.showIntro);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeSavingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showIntro && widget.showIntro) {
      _restartGaugeAnimation(force: true);
      _scheduleIntroCoachmark();
      _clickedSection = null;
      return;
    }

    if (oldWidget.showIntro && !widget.showIntro) {
      _coachmarkTimer?.cancel();
      _showIntroCoachmark = false;
    }

    // 퍼센트가 바뀌면 애니메이션 리스타트
    if (oldWidget.planPercent != widget.planPercent ||
        oldWidget.userPercent != widget.userPercent) {
      if (widget.showIntro) return;
      _restartGaugeAnimation();
      _clickedSection = null; // 값 변경 시 상세 닫기(원하면 제거 가능)
    }
  }

  void _restartGaugeAnimation({bool force = false}) {
    // 로그인 후 최초 1회만 애니 재생, 이후엔 최종 상태만 표시
    if (_homeGaugeAnimationPlayed && !force) {
      _gaugeController.value = 1.0;
      return;
    }
    _homeGaugeAnimationPlayed = true;

    _gaugeController
      ..stop()
      ..reset()
      ..forward();
    _playGaugeSequentialHaptic(); // 초록 구간 쫘라락
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _coachmarkTimer?.cancel();
    _gaugeController.dispose();
    super.dispose();
  }

  void _scheduleIntroCoachmark() {
    _coachmarkTimer?.cancel();
    _showIntroCoachmark = false;
    _coachmarkTimer = Timer(_coachmarkDelay, () {
      if (!mounted || !widget.showIntro) return;
      setState(() => _showIntroCoachmark = true);
    });
  }

  void _dismissIntroCoachmark() {
    _coachmarkTimer?.cancel();
    if (mounted) {
      setState(() => _showIntroCoachmark = false);
    }
    final callback = widget.onIntroDismissed;
    if (callback != null) {
      unawaited(Future<void>.sync(callback));
    }
  }

  /// 게이지 애니메이션에 맞춰 과하지 않게 햅틱을 분산한다.
  void _playGaugeSequentialHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    int count = 1;
    _hapticTimer = Timer.periodic(_hapticInterval, (_) {
      if (!mounted) {
        _hapticTimer?.cancel();
        return;
      }
      if (count >= _hapticCount) {
        _hapticTimer?.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      count++;
    });
  }

  void _handleTapGauge(
    TapDownDetails details,
    double minP,
    double maxP,
    bool isUserLarger,
  ) {
    const size = Size(300, 300);
    final center = Offset(size.width / 2, size.height / 2);
    final local = details.localPosition;

    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final radius = size.width / 2;
    const strokeWidth = 22.0;
    final innerRadius = radius - strokeWidth / 2;
    final outerRadius = radius + strokeWidth / 2;

    if (distance < innerRadius || distance > outerRadius) return;

    double angle = math.atan2(dy, dx);
    angle = angle + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final normalized = angle / (2 * math.pi);

    String? clicked;
    if (normalized >= 0.0 && normalized < minP) {
      clicked = isUserLarger ? 'plan' : 'user';
    } else if (normalized >= minP && normalized < maxP) {
      clicked = isUserLarger ? 'user' : 'plan';
    }

    setState(() {
      if (clicked != null) {
        _clickedSection = (_clickedSection == clicked) ? null : clicked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gaugeBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF1F1F1);

    final planProgress = (widget.planPercent / 100.0).clamp(0.0, 1.0);
    final userProgress = (widget.userPercent / 100.0).clamp(0.0, 1.0);
    final planColor = AppColors.primary;
    final userColor = const Color(0xFF7DAFFF);
    final isSamePercent =
        (widget.planPercent - widget.userPercent).abs() < 0.005;
    final viewHeight = MediaQuery.sizeOf(context).height;
    final gaugeLegendGap = viewHeight < 750
        ? 16.0
        : viewHeight < 820
        ? 20.0
        : 24.0;

    if (isSamePercent) {
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
                  RepaintBoundary(
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
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            child!,
                            CustomPaint(
                              size: const Size(300, 300),
                              painter: SemiGaugePainter(
                                startProgress: 0.0,
                                progress: _gaugeAnim.value * planProgress,
                                backgroundColor: Colors.transparent,
                                progressColorStart: planColor,
                                progressColorEnd: planColor,
                                strokeWidth: 22,
                                isFullCircle: true,
                                isDashed: false,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  HomeSavingCenterButton(
                    vm: widget.vm,
                    clickedSection: _clickedSection,
                    onCloseSection: () =>
                        setState(() => _clickedSection = null),
                    onOpenCountdown: widget.onOpenCountdown,
                  ),
                  if (_showIntroCoachmark)
                    Align(
                      alignment: const Alignment(0, 0.14),
                      child: _PlanGraphIntroCoachmark(
                        onDismiss: _dismissIntroCoachmark,
                      ),
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
                ),
                const SizedBox(width: 20),
                _LegendDot(
                  color: userColor,
                  text: '사용자 그래프',
                  textColor: userColor,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final smallerProgress = math.min(planProgress, userProgress);
    final largerProgress = math.max(planProgress, userProgress);
    final isUserLarger = userProgress > planProgress;
    final smallerColor = isUserLarger ? planColor : userColor;
    final largerColor = isUserLarger ? userColor : planColor;

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
                // 배경
                RepaintBoundary(
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
                      final progress = _gaugeAnim.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          child!,
                          // 큰 그래프: 0~큰값 전체를 먼저 그린다
                          CustomPaint(
                            size: const Size(300, 300),
                            painter: SemiGaugePainter(
                              startProgress: 0.0,
                              progress: progress * largerProgress,
                              backgroundColor: Colors.transparent,
                              progressColorStart: largerColor,
                              progressColorEnd: largerColor,
                              strokeWidth: 22,
                              isFullCircle: true,
                              isDashed: false,
                            ),
                          ),

                          // 작은 그래프: 위에 덮어서 항상 더 위에 보이게 한다
                          CustomPaint(
                            size: const Size(300, 300),
                            painter: SemiGaugePainter(
                              startProgress: 0.0,
                              progress: progress * smallerProgress,
                              backgroundColor: Colors.transparent,
                              progressColorStart: smallerColor,
                              progressColorEnd: smallerColor,
                              strokeWidth: 22,
                              isFullCircle: true,
                              isDashed: true,
                              dashWidth: 12.0,
                              dashGap: 6.0,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 탭 영역 판별용 투명 레이어
                GestureDetector(
                  onTapDown: (d) => _handleTapGauge(
                    d,
                    smallerProgress,
                    largerProgress,
                    isUserLarger,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    color: Colors.transparent,
                  ),
                ),

                // 중앙 버튼
                HomeSavingCenterButton(
                  vm: widget.vm,
                  clickedSection: _clickedSection,
                  onCloseSection: () => setState(() => _clickedSection = null),
                  onOpenCountdown: widget.onOpenCountdown,
                ),
                if (_showIntroCoachmark)
                  Align(
                    alignment: const Alignment(0, 0.14),
                    child: _PlanGraphIntroCoachmark(
                      onDismiss: _dismissIntroCoachmark,
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: gaugeLegendGap),
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppColors.primary,
                text: '플랜 그래프',
                textColor: AppColors.primary,
              ),
              const SizedBox(width: 20),
              _LegendDot(
                color: const Color(0xFF7DAFFF),
                text: '사용자 그래프',
                textColor: const Color(0xFF7DAFFF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanGraphIntroCoachmark extends StatelessWidget {
  const _PlanGraphIntroCoachmark({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF13233F)
        : const Color(0xFFEAF2FF);
    const borderColor = Color(0x473C7BFF);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '오늘 자정부터 1초마다 누적된 저축액이에요!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.text,
    required this.textColor,
  });

  final Color color;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}
