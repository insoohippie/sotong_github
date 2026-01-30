import 'package:flutter/material.dart';

import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';
import '../theme/app_colors.dart';

/// 재사용 가능한 애니메이션 예산 바 차트 위젯

// ───────────────────────── 전역 색상 상수 ─────────────────────────
const Color _labelBlue = Color(0xFF1D4ED8); // 하단 '저축' 라벨 강조색

class AnimatedBudgetBarChart extends StatefulWidget {
  /// 플랜 정보
  final TotalPlan plan;

  /// 계산 결과
  final SavingCalculationResult? calculation;

  /// 애니메이션 지속 시간 (기본값: 1200ms)
  final Duration animationDuration;

  /// 차트 높이
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
    this.height = 35,
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
  double get monthlyIncome => widget.plan.result.totalMetrics.monthlyIncomeAmount.toDouble();
  double get monthlyFixedCost => widget.plan.result.totalMetrics.monthlyConsumeAmount.toDouble();
  double get dailySpendingLimit => widget.plan.result.totalMetrics.dailyConsumeAmount.toDouble();
  double get monthlyVariableCost => dailySpendingLimit * 30;
  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;

  // 월수입 0일 때 비율은 0 처리
  bool get _noIncome => monthlyIncome <= 0;

  // 원본 비율(라벨/퍼센트 계산용)
  double get fixedRatio =>
      _noIncome ? 0.0 : (monthlyFixedCost / monthlyIncome).clamp(0.0, 1.0);
  double get variableRatio =>
      _noIncome ? 0.0 : (monthlyVariableCost / monthlyIncome).clamp(0.0, 1.0);
  double get savingRatio =>
      _noIncome ? 0.0 : (widget.calculation?.savingRatio ?? 0).clamp(0.0, 1.0);

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
    // 면적용 비율(그래프 폭)에 최소 20% 규칙 적용
    final adjusted = applyMinAreaRule(
      fixedRatio: fixedRatio,
      variableRatio: variableRatio,
      savingRatio: savingRatio,
      minShare: 0.2, // 20%
    );

    _fixedAnim = Tween<double>(begin: 0, end: adjusted[0]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _variableAnim = Tween<double>(begin: 0, end: adjusted[1]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _savingAnim = Tween<double>(begin: 0, end: adjusted[2]).animate(
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

  // 세그먼트 색 (그라데이션)
  static const _fixedGrad = [Color(0xFF9FC4FF), Color(0xFFB9D2FF)]; // 고정소비
  static const _variableGrad = [Color(0xFF6FA9FF), Color(0xFF8BB8FF)]; // 변동소비
  static const _savingGrad = [Color(0xFF2F66FF), Color(0xFF3C7BFF)]; // 저축

  String _formatManWon(double won) {
    if (won <= 0) return '';
    final man = (won / 10000).round(); // 만원 단위 반올림 (정책 유지)
    return '${man}만원';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 면적(그래프 폭)은 '조정된 비율' 애니메이션 값 사용
        final wFShare = _fixedAnim.value; // 0..1
        final wVShare = _variableAnim.value;
        final wSShare = _savingAnim.value;

        // 라벨(금액) — 원본 금액 기준
        final fixedText = _formatManWon(monthlyFixedCost);
        final variableText = _formatManWon(monthlyVariableCost);
        final savingText = _formatManWon(monthlySaving);

        // 퍼센트(옵션) — 원본 비율 기준
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
              // 상단 점선 브라켓 + 타이틀
              const _BracketHeader(title: '한 달 전체 수입'),
              const SizedBox(height: 16),

              // 메인 바(캡슐)
              LayoutBuilder(
                builder: (context, constraints) {
                  final barH = widget.height;
                  final barW = constraints.maxWidth;

                  final wF = (barW * wFShare).clamp(0, barW).toDouble();
                  final wV = (barW * wVShare).clamp(0, barW).toDouble();
                  final wS = (barW * wSShare).clamp(0, barW).toDouble();

                  double leftF = 0;
                  double leftV = leftF + wF;
                  double leftS = leftV + wV;

                  return ClipRRect(
                    // borderRadius: BorderRadius.circular(barH / 2),
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // 전체 트랙(아주 연한 파란색)
                        Container(
                          width: barW,
                          height: barH,
                          decoration: const BoxDecoration(
                            color: AppColors.lightBlue,
                          ),
                        ),
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
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              // 하단 U자 점선(네 설정 유지)
              _SegmentDashedBrackets(
                fShare: wFShare,
                vShare: wVShare,
                sShare: wSShare,
                barRadiusFactor: 0.5, // 그대로 유지
                stripHeight: 16,      // 그대로 유지
                dash: 3,
                gap: 4,
                stroke: 1,
                color: Colors.black,
              ),
              const SizedBox(height: 6),

              // 하단 라벨(중앙 텍스트만)
              _BottomLabels(
                fixedFlex: wFShare,
                variableFlex: wVShare,
                savingFlex: wSShare,
              ),

              // (옵션) 퍼센트 표시는 원본 비율 기반
              if (widget.showPercentages) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (wFShare > 0)
                      Expanded(
                        flex: (wFShare * 1000).round(),
                        child: _PercentText('$fixedPercent%'),
                      ),
                    if (wVShare > 0)
                      Expanded(
                        flex: (wVShare * 1000).round(),
                        child: _PercentText('$variablePercent%'),
                      ),
                    if (wSShare > 0)
                      Expanded(
                        flex: (wSShare * 1000).round(),
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

/// 막대와 라벨 사이에서 각 조각의 시작/끝을 U자 꺾은선 점선으로 연결
class _SegmentDashedBrackets extends StatelessWidget {
  final double fShare, vShare, sShare;
  final double barRadiusFactor; // radius = stripHeight * factor
  final double stripHeight;     // U자 세로 다리 길이
  final double dash, gap, stroke;
  final Color color;

  const _SegmentDashedBrackets({
    Key? key,
    required this.fShare,
    required this.vShare,
    required this.sShare,
    this.barRadiusFactor = 1.0,
    this.stripHeight = 16,
    this.dash = 6,
    this.gap = 4,
    this.stroke = 2,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: stripHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // 각 세그먼트 실제 px 폭
          final wF = w * fShare;
          final wV = w * vShare;
          final wS = w * sShare;

          // 누적 원시 경계 (보정 전)
          final x0 = 0.0;
          final x1 = x0 + wF;
          final x2 = x1 + wV;
          final x3 = x2 + wS; // == w

          // 보정 radius
          final baseRadius = stripHeight * barRadiusFactor;

          // 세그먼트별 실효 radius (너비 작은 경우 뒤집힘 방지)
          double rF = (wF > 0) ? baseRadius.clamp(0.0, (wF / 2) - 0.5) : 0.0;
          double rV = (wV > 0) ? baseRadius.clamp(0.0, (wV / 2) - 0.5) : 0.0;
          double rS = (wS > 0) ? baseRadius.clamp(0.0, (wS / 2) - 0.5) : 0.0;

          // 보정된 시작/끝 x
          final segments = <_BracketSpan>[];
          if (fShare > 0) segments.add(_BracketSpan(start: x0 + rF, end: x1 - rF));
          if (vShare > 0) segments.add(_BracketSpan(start: x1 + rV, end: x2 - rV));
          if (sShare > 0) segments.add(_BracketSpan(start: x2 + rS, end: x3 - rS));

          return CustomPaint(
            painter: _DashedBracketPainter(
              spans: segments,
              height: stripHeight,
              color: color,
              dash: dash,
              gap: gap,
              stroke: stroke,
            ),
          );
        },
      ),
    );
  }
}

class _BracketSpan {
  final double start; // 상단에서 내려오는 세로선의 x
  final double end;   // 반대편에서 올라가는 세로선의 x
  _BracketSpan({required this.start, required this.end});
}

/// U자 꺾은선 점선 Painter: 상단(y=0)에서 아래(y=h)로 내려갔다가 가로로, 끝에서 위로
class _DashedBracketPainter extends CustomPainter {
  final List<_BracketSpan> spans;
  final double height; // stripHeight
  final double dash, gap, stroke;
  final Color color;

  _DashedBracketPainter({
    required this.spans,
    required this.height,
    required this.color,
    this.dash = 6,
    this.gap = 4,
    this.stroke = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final s in spans) {
      final topY = 0.0;
      final bottomY = height;

      // 1) 왼쪽 세로 (start, 0) → (start, h)
      _drawDashedLine(canvas, paint,
          Offset(s.start, topY), Offset(s.start, bottomY));

      // 2) 가로 (start, h) → (end, h)
      _drawDashedLine(canvas, paint,
          Offset(s.start, bottomY), Offset(s.end, bottomY));

      // 3) 오른쪽 세로 (end, h) → (end, 0)
      _drawDashedLine(canvas, paint,
          Offset(s.end, bottomY), Offset(s.end, topY));
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset a, Offset b) {
    final total = (b - a).distance;
    if (total <= 0) return;

    final dir = (b - a) / total; // 단위벡터
    double traveled = 0.0;
    bool draw = true;

    while (traveled < total) {
      final len = draw ? dash : gap;
      final next = (traveled + len).clamp(0.0, total);
      final p1 = a + dir * traveled;
      final p2 = a + dir * next;
      if (draw) canvas.drawLine(p1, p2, paint);
      traveled = next;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBracketPainter old) {
    return old.spans != spans ||
        old.height != height ||
        old.dash != dash ||
        old.gap != gap ||
        old.stroke != stroke ||
        old.color != color;
  }
}

/// 상단 점선 브라켓 + 타이틀 (양옆 꺾인 점선)
class _BracketHeader extends StatelessWidget {
  final String title;
  const _BracketHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    // 브라켓(점선) 스타일 — 이미지와 유사하게
    const double painterHeight = 20; // 브라켓 영역 높이
    const double stroke = 1;
    const double dash = 4;
    const double gap = 3;
    const double sidePad = 8; // 좌우 여백
    const double endDown = 14; // 양 끝에서 아래로 꺾이는 길이
    const Color lineColor = Colors.black87;

    return SizedBox(
      height: painterHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 텍스트 폭 계산
          final tp = TextPainter(
            text: TextSpan(text: title, style: textStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: constraints.maxWidth);
          final textWidth = tp.size.width;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 점선 배경
              Positioned.fill(
                child: CustomPaint(
                  painter: _TitleBracketPainter(
                    textWidth: textWidth,
                    stroke: stroke,
                    dash: dash,
                    gap: gap,
                    sidePad: sidePad,
                    endDown: endDown,
                    color: lineColor,
                  ),
                ),
              ),
              // 가운데 텍스트
              Text(title, style: textStyle),
            ],
          );
        },
      ),
    );
  }
}

class _TitleBracketPainter extends CustomPainter {
  final double textWidth;
  final double stroke, dash, gap, sidePad, endDown;
  final Color color;

  _TitleBracketPainter({
    required this.textWidth,
    required this.stroke,
    required this.dash,
    required this.gap,
    required this.sidePad,
    required this.endDown,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // 수평 라인의 y 위치
    final y = h * 0.35; // 살짝 위쪽으로 (이미지 느낌)

    // 텍스트 좌우 여유
    const double textGap = 8;

    final center = w / 2;
    final leftLineStartX = sidePad;
    final leftLineEndX = (center - textWidth / 2 - textGap).clamp(sidePad, w);
    final double rightLineStartX = (center + textWidth / 2 + textGap).clamp(0, w);
    final rightLineEndX = w - sidePad;

    // 왼쪽 수평 점선
    if (leftLineEndX - leftLineStartX > 0) {
      _drawDashedLine(canvas, paint, Offset(leftLineStartX, y), Offset(leftLineEndX, y));
      // 왼쪽 끝에서 아래로 꺾임
      _drawDashedLine(canvas, paint, Offset(leftLineStartX, y), Offset(leftLineStartX, y + endDown));
    }

    // 오른쪽 수평 점선
    if (rightLineEndX - rightLineStartX > 0) {
      _drawDashedLine(canvas, paint, Offset(rightLineStartX, y), Offset(rightLineEndX, y));
      // 오른쪽 끝에서 아래로 꺾임
      _drawDashedLine(canvas, paint, Offset(rightLineEndX, y), Offset(rightLineEndX, y + endDown));
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset a, Offset b) {
    final total = (b - a).distance;
    if (total <= 0) return;

    final dir = (b - a) / total; // 단위벡터
    double traveled = 0.0;
    bool draw = true;

    while (traveled < total) {
      final len = draw ? dash : gap;
      final next = (traveled + len).clamp(0.0, total);
      final p1 = a + dir * traveled;
      final p2 = a + dir * next;
      if (draw) canvas.drawLine(p1, p2, paint);
      traveled = next;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _TitleBracketPainter oldDelegate) {
    return oldDelegate.textWidth != textWidth ||
        oldDelegate.stroke != stroke ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.sidePad != sidePad ||
        oldDelegate.endDown != endDown ||
        oldDelegate.color != color;
  }
}

/// “최소 면적 20% 규칙” 적용 함수
/// - 그래프 면적(폭) 계산용 비율만 조정
/// - 라벨/퍼센트는 원본 비율/금액 사용
List<double> applyMinAreaRule({
  required double fixedRatio,
  required double variableRatio,
  required double savingRatio,
  double minShare = 0.2, // 20%
}) {
  // 안전 범위
  double rf = fixedRatio.isFinite ? fixedRatio.clamp(0.0, 1.0) : 0.0;
  double rv = variableRatio.isFinite ? variableRatio.clamp(0.0, 1.0) : 0.0;
  double rs = savingRatio.isFinite ? savingRatio.clamp(0.0, 1.0) : 0.0;

  final total = rf + rv + rs;
  if (total <= 0) return const [0.0, 0.0, 0.0];

  // 정규화(합=1)
  double bf = rf / total;
  double bv = rv / total;
  double bs = rs / total;

  // 0은 제외하고, 0<비율<minShare 인 항목은 캡핑 대상
  bool isSmall(double b) => b > 0 && b < minShare;
  final capF = isSmall(bf);
  final capV = isSmall(bv);
  final capS = isSmall(bs);

  final cappedCount = (capF ? 1 : 0) + (capV ? 1 : 0) + (capS ? 1 : 0);
  final capSum = minShare * cappedCount;
  double remaining = (1.0 - capSum).clamp(0.0, 1.0);

  // 미캡핑 합(0은 미캡/캡 모두 아님 → 0 유지)
  double sumUncapped = 0.0;
  if (!capF) sumUncapped += bf;
  if (!capV) sumUncapped += bv;
  if (!capS) sumUncapped += bs;

  double af, av, as;

  if (sumUncapped > 0) {
    // 남은 비율을 미캡핑 요소들에 원래 비율 비례로 배분
    af = (bf == 0) ? 0.0 : (capF ? minShare : remaining * (bf / sumUncapped));
    av = (bv == 0) ? 0.0 : (capV ? minShare : remaining * (bv / sumUncapped));
    as = (bs == 0) ? 0.0 : (capS ? minShare : remaining * (bs / sumUncapped));
  } else {
    // 모두 캡핑되었거나(혹은 0만 존재) → 남은 비율 균등 분배(캡핑 대상에게만)
    final active = cappedCount;
    if (active > 0) {
      final bonus = (1.0 - capSum) / active;
      af = (bf == 0) ? 0.0 : (capF ? minShare + bonus : 0.0);
      av = (bv == 0) ? 0.0 : (capV ? minShare + bonus : 0.0);
      as = (bs == 0) ? 0.0 : (capS ? minShare + bonus : 0.0);
    } else {
      // 논리상 드문 케이스: 정규화 비율 그대로
      af = bf;
      av = bv;
      as = bs;
    }
  }

  // 수치 오차 보정(합=1)
  final sumA = af + av + as;
  if (sumA > 0) {
    af /= sumA;
    av /= sumA;
    as /= sumA;
  }
  return [af, av, as];
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
        // borderRadius: BorderRadius.circular(height / 2),
        borderRadius: BorderRadius.circular(0),
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

/// 하단 라벨(고정소비 / 변동소비 / 저축) + 세그먼트 폭에 비례한 배치 (중앙 텍스트만)
class _BottomLabels extends StatelessWidget {
  final double fixedFlex;
  final double variableFlex;
  final double savingFlex;

  const _BottomLabels({
    required this.fixedFlex,
    required this.variableFlex,
    required this.savingFlex,
  });

  @override
  Widget build(BuildContext context) {
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

    return Row(children: children);
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
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: highlightBlue ? _labelBlue : Colors.black87,
      ),
    );
  }
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
