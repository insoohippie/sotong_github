import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sotong_local/component/chart/semi_gauge_chart.dart';

/// TotalPlan 페이지용 독립적인 차트 위젯
/// HomeViewModel 없이 필요한 데이터만 파라미터로 받음
class TotalPlanChartWidget extends StatefulWidget {
  const TotalPlanChartWidget({
    super.key,
    required this.planPercent, // 0~100 (목표 페이스)
    required this.userPercent, // 0~100 (실제 진행률)
    required this.currentAmount, // 현재 모은 금액
    required this.targetAmount, // 목표 금액
    required this.daysRemaining, // 남은 일수 (null 가능)
  });

  final int planPercent;
  final int userPercent;
  final int currentAmount;
  final int targetAmount;
  final int? daysRemaining;

  @override
  State<TotalPlanChartWidget> createState() => _TotalPlanChartWidgetState();
}

class _TotalPlanChartWidgetState extends State<TotalPlanChartWidget>
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

    _restartGaugeAnimation();

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
  void didUpdateWidget(covariant TotalPlanChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planPercent != widget.planPercent ||
        oldWidget.userPercent != widget.userPercent) {
      _restartGaugeAnimation();
      _clickedSection = null;
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

  String _formatAmount(int amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}억';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    }
    return NumberFormat.decimalPattern('ko_KR').format(amount);
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

                // 차트1: 0~기점 (점선) - 초록 애니메이션
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
                _buildCenterButton(),
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

  Widget _buildCenterButton() {
    final isUser = _clickedSection == 'user';
    final isPlan = _clickedSection == 'plan';

    Color bg;
    Color textColor;
    Color border;

    if (isUser) {
      bg = const Color(0xFF7DAFFF);
      textColor = Colors.white;
      border = const Color(0xFF7DAFFF);
    } else if (isPlan) {
      bg = const Color(0xFF0062FF);
      textColor = Colors.white;
      border = const Color(0xFF0062FF);
    } else {
      bg = Colors.white;
      textColor = const Color(0xFF2962FF);
      border = Colors.grey[300]!;
    }

    // 기본 상태: D-Day + 모인 금액
    if (!isUser && !isPlan) {
      String dDayText = '목표일 없음';
      if (widget.daysRemaining != null) {
        if (widget.daysRemaining! < 0) {
          dDayText = 'D-Day 달성';
        } else {
          dDayText = 'D-${widget.daysRemaining}';
        }
      }

      return _circleShell(
        bg: bg,
        border: border,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dDayText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '모인 금액',
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(widget.currentAmount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      );
    }

    // 클릭 상태: 정보 표시
    final title = isUser ? '사용자 그래프' : '플랜 그래프';
    final items = <Map<String, String>>[];

    if (isUser) {
      final currentAmountText = _formatAmount(widget.currentAmount);
      final actualProgressText = widget.targetAmount > 0
          ? '${(widget.currentAmount / widget.targetAmount * 100).toStringAsFixed(1)}%'
          : '0%';

      items.addAll([
        {'label': '현재까지 모은 금액', 'value': currentAmountText},
        {'label': '실제저축률', 'value': actualProgressText},
      ]);
    } else {
      final targetAmountText = _formatAmount(widget.targetAmount);
      final progressText = '${widget.planPercent}%';

      items.addAll([
        {'label': '목표금액', 'value': targetAmountText},
        {'label': '저축률', 'value': progressText},
      ]);
    }

    return GestureDetector(
      onTap: () => setState(() => _clickedSection = null),
      child: _circleShell(
        bg: bg,
        border: border,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${e['label']}: ${e['value']}',
                    style: TextStyle(fontSize: 10, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleShell({
    required Color bg,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
