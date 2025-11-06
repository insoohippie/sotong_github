import 'package:flutter/material.dart';

import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';

/// 재사용 가능한 애니메이션 예산 바 차트 위젯

const Color _labelBlue = Color(0xFF1D4ED8); // 추후 수정?

class AnimatedBudgetBarChart extends StatefulWidget {
  /// 플랜 정보
  final TotalPlan plan;

  /// 계산 결과
  final SavingCalculationResult? calculation;

  /// 애니메이션 지속 시간 (기본값: 1200ms)
  final Duration animationDuration;

  /// 차트 높이 (기본값: 20)
  final double height;

  /// 차트 너비 (기본값: double.infinity)
  final double? width;

  /// 자동 애니메이션 시작 여부 (기본값: true)
  final bool autoPlay;

  /// 하단 퍼센트 표시 여부 (기본값: true)
  final bool showPercentages;

  const AnimatedBudgetBarChart({
    Key? key,
    required this.plan,
    required this.calculation,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.height = 20,
    this.width,
    this.autoPlay = true,
    this.showPercentages = true,
  }) : super(key: key);

  @override
  State<AnimatedBudgetBarChart> createState() => _AnimatedBudgetBarChartState();
}

class _AnimatedBudgetBarChartState extends State<AnimatedBudgetBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fixedAnim;
  late Animation<double> _variableAnim;
  late Animation<double> _savingAnim;

  // 계산된 값들
  double get monthlyIncome => widget.plan.result.totalMetrics.sumMonthlyIncome.toDouble();
  double get monthlyFixedCost => widget.plan.result.totalMetrics.sumMonthlyConsume.toDouble();
  double get dailySpendingLimit => widget.plan.result.totalMetrics.sumDailyConsume.toDouble();
  double get monthlyVariableCost => dailySpendingLimit * 30;
  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;

  double get fixedRatio =>
      (monthlyFixedCost / (monthlyIncome == 0 ? 1 : monthlyIncome))
          .clamp(0.0, 1.0);
  double get variableRatio =>
      (monthlyVariableCost / (monthlyIncome == 0 ? 1 : monthlyIncome))
          .clamp(0.0, 1.0);
  double get savingRatio => widget.calculation?.savingRatio ?? 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _initAnimations();

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  void _initAnimations() {
    _fixedAnim = Tween<double>(begin: 0, end: fixedRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _variableAnim = Tween<double>(begin: 0, end: variableRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _savingAnim = Tween<double>(begin: 0, end: savingRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedBudgetBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan ||
        oldWidget.calculation != widget.calculation) {
      _initAnimations();
      if (widget.autoPlay) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 애니메이션을 수동으로 시작
  void startAnimation() {
    _controller.forward(from: 0);
  }

  /// 애니메이션을 리셋
  void resetAnimation() {
    _controller.reset();
  }

  // ===== 디자인 유틸 =====

  // 아주 연한 배경 (이미지 느낌)
  static const _bgColor = Color(0xFFEFF6FF); // 연한 하늘색 배경
  static const _labelBlue = Color(0xFF1D4ED8); // 하단 '변동소비' 파란색

  // 세그먼트 색 (그라데이션)
  static const _fixedGrad = [Color(0xFF9FC4FF), Color(0xFFB9D2FF)];    // 고정소비: 가장 연한 파란색
  static const _variableGrad = [Color(0xFF6FA9FF), Color(0xFF8BB8FF)]; // 변동소비: 중간 진한 파란색
  static const _savingGrad = [Color(0xFF2F66FF), Color(0xFF3C7BFF)];   // 저축: 가장 진한 파란색

  String _formatManWon(double won) {
    if (won <= 0) return '';
    final man = (won / 10000).round(); // 만원 단위 반올림
    return '${man}만원';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 비율 정규화
        final total = _fixedAnim.value + _variableAnim.value + _savingAnim.value;
        final nf = total > 0 ? _fixedAnim.value / total : 0.0;
        final nv = total > 0 ? _variableAnim.value / total : 0.0;
        final ns = total > 0 ? _savingAnim.value / total : 0.0;

        // 라벨(금액)
        final fixedText = _formatManWon(monthlyFixedCost);
        final variableText = _formatManWon(monthlyVariableCost);
        final savingText = _formatManWon(monthlySaving);

        // 퍼센트(옵션)
        final fixedPercent = (fixedRatio * 100).round();
        final variablePercent = (variableRatio * 100).round();
        final savingPercent = (savingRatio * 100).round();

        return Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 점선 + 타이틀
              _BracketHeader(title: '한 달 전체 수입'),
              const SizedBox(height: 8),

              // 메인 바(캡슐) : Stack + LayoutBuilder 로 정확한 세그먼트 폭을 그려줌
              LayoutBuilder(
                builder: (context, constraints) {
                  final barH = widget.height;
                  final barW = constraints.maxWidth;

                  final wF = (barW * nf).clamp(0, barW).toDouble();
                  final wV = (barW * nv).clamp(0, barW).toDouble();
                  final wS = (barW * ns).clamp(0, barW).toDouble();

                  double leftF = 0;
                  double leftV = leftF + wF;
                  double leftS = leftV + wV;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(barH / 2),
                    child: Stack(
                      children: [
                        // 전체 트랙(아주 연한 파란색)
                        Container(
                          width: barW,
                          height: barH,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEAFF),
                          ),
                        ),
                        // 고정 소비
                        if (wF > 0)
                          Positioned(
                            left: leftF,
                            width: wF,
                            height: barH,
                            child: _SegmentPill(
                              gradient: _fixedGrad,
                              text: fixedText,
                              height: barH,
                            ),
                          ),
                        // 저축
                        if (wS > 0)
                          Positioned(
                            left: leftS,
                            width: wS,
                            height: barH,
                            child: _SegmentPill(
                              gradient: _savingGrad,
                              text: savingText,
                              height: barH,
                            ),
                          ),
                        // 변동 소비
                        if (wV > 0)
                          Positioned(
                            left: leftV,
                            width: wV,
                            height: barH,
                            child: _SegmentPill(
                              gradient: _variableGrad,
                              text: variableText,
                              height: barH,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // 하단 세그먼트 라벨 + 점선 마커
              _BottomLabels(
                fixedFlex: nf,
                savingFlex: ns,
                variableFlex: nv,
              ),

              // (옵션) 퍼센트 표시는 이전 API 유지: showPercentages=true 일 때만
              if (widget.showPercentages) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (nf > 0)
                      Expanded(
                        flex: (nf * 1000).round(),
                        child: _PercentText('$fixedPercent%'),
                      ),
                    if (nv > 0)
                      Expanded(
                        flex: (nv * 1000).round(),
                        child: _PercentText('$variablePercent%'),
                      ),
                    if (ns > 0)
                      Expanded(
                        flex: (ns * 1000).round(),
                        child: _PercentText('$savingPercent%'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 세그먼트(캡슐 모양 + 중앙 라벨)
class _SegmentPill extends StatelessWidget {
  final List<Color> gradient;
  final String text;
  final double height;

  const _SegmentPill({
    Key? key,
    required this.gradient,
    required this.text,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}

/// 상단 점선 브라켓 + 타이틀
class _BracketHeader extends StatelessWidget {
  final String title;

  const _BracketHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _DashedLine()), // 왼쪽 점선
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const Expanded(child: _DashedLine()), // 오른쪽 점선
      ],
    );
  }
}

/// 하단 라벨(고정소비 / 저축 / 변동소비) + 세그먼트 폭에 비례한 배치
class _BottomLabels extends StatelessWidget {
  final double fixedFlex;
  final double savingFlex;
  final double variableFlex;

  const _BottomLabels({
    required this.fixedFlex,
    required this.savingFlex,
    required this.variableFlex,
  });

  @override
  Widget build(BuildContext context) {
    // 세그먼트 비율이 0이면 표시 생략
    final children = <Widget>[];
    if (fixedFlex > 0) {
      children.add(
        Expanded(
          flex: (fixedFlex * 1000).round(),
          child: const _BottomLabelCell(
            label: '고정소비',
            highlightBlue: false,
          ),
        ),
      );
    }
    if (variableFlex > 0) {
      children.add(
        Expanded(
          flex: (variableFlex * 1000).round(),
          child: const _BottomLabelCell(
            label: '변동소비',
            highlightBlue: false,
          ),
        ),
      );
    }
    if (savingFlex > 0) {
      children.add(
        Expanded(
          flex: (savingFlex * 1000).round(),
          child: const _BottomLabelCell(
            label: '저축',
            highlightBlue: true, // 저축만 파란색 강조
          ),
        ),
      );
    }

    return Column(
      children: [
        // 점선 라인
        const _DashedLine(),
        const SizedBox(height: 4),
        Row(children: children),
      ],
    );
  }
}

class _BottomLabelCell extends StatelessWidget {
  final String label;
  final bool highlightBlue;

  const _BottomLabelCell({
    required this.label,
    required this.highlightBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 세로 점선 마커
        SizedBox(
          height: 8,
          child: CustomPaint(
            painter: _DashedPainter(isHorizontal: false),
            size: const Size(1, 8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: highlightBlue ? _labelBlue : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 점선 라인 (가로/세로 공용)
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        painter: _DashedPainter(isHorizontal: true),
        size: const Size(double.infinity as double, 1),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final bool isHorizontal;

  _DashedPainter({required this.isHorizontal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8) // 회청색 점선
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    if (isHorizontal) {
      double x = 0;
      final y = size.height / 2;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
        x += dashWidth + dashSpace;
      }
    } else {
      double y = 0;
      final x = 0.0;
      while (y < size.height) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashWidth), paint);
        y += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) =>
      oldDelegate.isHorizontal != isHorizontal;
}

class _PercentText extends StatelessWidget {
  final String text;

  const _PercentText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.black54,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
