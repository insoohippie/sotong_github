import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sotong_local/component/chart/semi_gauge_chart.dart';
import 'package:sotong_local/view_model/home/home_view_model.dart';

import 'home_saving_center_button.dart';

class HomeSavingChartWidget extends StatefulWidget {
  const HomeSavingChartWidget({
    super.key,
    required this.vm,
    required this.planPercent, // 0~100
    required this.userPercent, // 0~100
    required this.onOpenCountdown, // 중앙 버튼 기본 상태 클릭 시
  });

  final HomeViewModel vm;
  final int planPercent;
  final int userPercent;
  final VoidCallback onOpenCountdown;

  @override
  State<HomeSavingChartWidget> createState() => _HomeSavingChartWidgetState();
}

class _HomeSavingChartWidgetState extends State<HomeSavingChartWidget>
    with TickerProviderStateMixin {
  String? _clickedSection; // 'plan' | 'user' | null

  late final AnimationController _greenController;
  late final AnimationController _blueController;
  late final Animation<double> _greenAnim;
  late final Animation<double> _blueAnim;


  @override
  void initState() {
    super.initState();

    _greenController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _blueController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _greenAnim = CurvedAnimation(parent: _greenController, curve: Curves.easeOut);
    _blueAnim = CurvedAnimation(parent: _blueController, curve: Curves.easeOut);

    _greenController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blueController.forward();
      }
    });

    // 🔥 1차: 즉시 시작 (중요)
    _restartGaugeAnimation();

    // 🔥 2차: 프레임 이후 보정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartGaugeAnimation();
    });

    _greenController.addListener(() {
      if (mounted) setState(() {});
    });
    _blueController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant HomeSavingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 퍼센트가 바뀌면 애니메이션 리스타트
    if (oldWidget.planPercent != widget.planPercent ||
        oldWidget.userPercent != widget.userPercent) {
      _restartGaugeAnimation();
      _clickedSection = null; // 값 변경 시 상세 닫기(원하면 제거 가능)
    }
  }

  void _restartGaugeAnimation() {
    _greenController
      ..stop()
      ..reset()
      ..forward();

    _blueController
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _greenController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  void _handleTapGauge(TapDownDetails details, double minP, double maxP, bool isUserLarger) {
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

    final planProgress = (widget.planPercent / 100.0).clamp(0.0, 1.0);
    final userProgress = (widget.userPercent / 100.0).clamp(0.0, 1.0);

    if (widget.planPercent == widget.userPercent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: SemiGaugePainter(
                  progress: 1.0,
                  backgroundColor: const Color(0xFFF1F1F1),
                  progressColorStart: const Color(0xFFF1F1F1),
                  progressColorEnd: const Color(0xFFF1F1F1),
                  strokeWidth: 22,
                  isFullCircle: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '플랜 그래프와 사용자 그래프 수치가 같습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final minP = math.min(planProgress, userProgress);
    final maxP = math.max(planProgress, userProgress);
    final isUserLarger = userProgress > planProgress;

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
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    progress: 1.0,
                    backgroundColor: const Color(0xFFF1F1F1),
                    progressColorStart: const Color(0xFFF1F1F1),
                    progressColorEnd: const Color(0xFFF1F1F1),
                    strokeWidth: 22,
                    isFullCircle: true,
                  ),
                ),

                // 차트2: 기점~큰값 (실선) - 파란 애니메이션
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    startProgress: minP,
                    progress: minP + (_blueAnim.value * (maxP - minP)),
                    backgroundColor: Colors.transparent,
                    progressColorStart: isUserLarger
                        ? const Color(0xFF7DAFFF)
                        : const Color(0xFF0062FF),
                    progressColorEnd: isUserLarger
                        ? const Color(0xFF7DAFFF)
                        : const Color(0xFF0062FF),
                    strokeWidth: 22,
                    isFullCircle: true,
                    isDashed: false,
                  ),
                ),

                // 차트1: 0~기점 (점선) - 초록(여기서는 첫 구간) 애니메이션
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    startProgress: 0.0,
                    progress: _greenAnim.value * minP,
                    backgroundColor: Colors.transparent,
                    progressColorStart: isUserLarger
                        ? const Color(0xFF0062FF)
                        : const Color(0xFF7DAFFF),
                    progressColorEnd: isUserLarger
                        ? const Color(0xFF0062FF)
                        : const Color(0xFF7DAFFF),
                    strokeWidth: 22,
                    isFullCircle: true,
                    isDashed: true,
                    dashWidth: 12.0,
                    dashGap: 6.0,
                  ),
                ),

                // 탭 영역 판별용 투명 레이어
                GestureDetector(
                  onTapDown: (d) => _handleTapGauge(d, minP, maxP, isUserLarger),
                  child: Container(width: 300, height: 300, color: Colors.transparent),
                ),

                // 중앙 버튼
                HomeSavingCenterButton(
                  vm: widget.vm,
                  clickedSection: _clickedSection,
                  onCloseSection: () => setState(() => _clickedSection = null),
                  onOpenCountdown: widget.onOpenCountdown,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFF0062FF), text: '플랜 그래프', textColor: Color(0xFF0062FF)),
              SizedBox(width: 20),
              _LegendDot(color: Color(0xFF7DAFFF), text: '사용자 그래프', textColor: Color(0xFF7DAFFF)),
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
  });

  final Color color;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}
