import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_summary/plan_summary_donut_chart_widget.dart';
import '../../../../../model/plan/plan_edit_result.dart';
import '../../../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../../../view_model/plan/enums/chat_step.dart';
import '../../plan_edit_page.dart';

Widget buildSummarySection(BuildContext context, ChatPlanViewModel viewModel) {
  final calc = viewModel.calculationResult ?? viewModel.calculate();
  final hasNoSaving = calc != null && calc.dailyNetSaving <= 0;

  if (hasNoSaving) {
    return _buildNoSavingWarning(context, viewModel);
  } else {
    return _buildSummaryChartWithRecommendation(context, viewModel);
  }
}

Widget _buildNoSavingWarning(
    BuildContext context,
    ChatPlanViewModel viewModel,
    ) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text(
        '저축할 수 있는 금액이 없어요.\n하루 소비 한도 금액을 수정해 주세요!',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () async {
          final editResult = await Navigator.of(context).push<PlanEditResult>(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.totalPlan,
                initialRefData: viewModel.refData,
                requireApplyDate: false,
              ),
            ),
          );
          if (editResult != null) {
            viewModel.applyPlanEditResult(editResult);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0062FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '플랜 수정하기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

Widget _buildSummaryChartWithRecommendation(
    BuildContext context,
    ChatPlanViewModel viewModel,
    ) {
  final canEdit = context.read<ChatPlanViewModel>().currentStep != ChatStep.autoService;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // 요약 차트
      PlanSummaryDonutChartWidget(
        plan: viewModel.totalPlan,
        calculation: viewModel.calculationResult,
        userName: viewModel.userName,
        onEdit: canEdit ? () async {
          final editResult = await Navigator.of(context).push<PlanEditResult>(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.totalPlan,
                initialRefData: viewModel.refData,
                requireApplyDate: false,
              ),
            ),
          );
          if (editResult != null) {
            viewModel.applyPlanEditResult(editResult);
          }
        } : null,
      ),

      const SizedBox(height: 8),
    ],
  );
}

/// 간단한 봇 말풍선 위젯 (Summary 내부 전용)
class _BotBubble extends StatelessWidget {
  final String text;
  const _BotBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아바타
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFBFD8FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/bot_profile.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        // 말풍선
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75, // ✅ 75% 제한
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotBubbleTyping extends StatefulWidget {
  final String text;
  final Duration delay;        // 타이핑 시작 전 대기
  final Duration charInterval; // 글자당 타이핑 속도

  const _BotBubbleTyping({
    required this.text,
    this.delay = const Duration(milliseconds: 400),
    this.charInterval = const Duration(milliseconds: 25),
  });

  @override
  State<_BotBubbleTyping> createState() => _BotBubbleTypingState();
}

class _BotBubbleTypingState extends State<_BotBubbleTyping> with SingleTickerProviderStateMixin {
  bool _showTypingDots = true;
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    // 1) 잠깐 대기
    await Future.delayed(widget.delay);
    if (!mounted) return;

    // 2) 타이핑 애니 시작
    setState(() => _showTypingDots = false);
    _timer = Timer.periodic(widget.charInterval, (t) {
      if (!mounted) return;
      if (_visibleChars >= widget.text.length) {
        t.cancel();
      } else {
        setState(() => _visibleChars++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTypingDots) {
      // ⌛ 타이핑 점 세 개 (봇 아바타와 정렬)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BotAvatar(),
          SizedBox(width: 8),
          _TypingDots(),
        ],
      );
    }

    // ⌨️ 타이핑 중/완료 단계: 현재까지 노출된 문자열로 말풍선 렌더
    final partial = widget.text.substring(0, _visibleChars.clamp(0, widget.text.length));
    return _BotBubble(text: partial.isEmpty ? " " : partial);
  }
}

/// 봇 아바타만 분리 (타이핑/말풍선 모두 동일 사용)
class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFBFD8FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/images/bot_profile.png', fit: BoxFit.cover),
    );
  }
}

/// 간단한 타이핑 점 애니메이션 (…)
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  late final Animation<double> _a1 = CurvedAnimation(parent: _c, curve: const Interval(0.00, 0.60));
  late final Animation<double> _a2 = CurvedAnimation(parent: _c, curve: const Interval(0.20, 0.80));
  late final Animation<double> _a3 = CurvedAnimation(parent: _c, curve: const Interval(0.40, 1.00));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BotAvatar(), // 말풍선 안이 아닌, 같은 높이 기준으로 싶은 경우 제거하세요
            const SizedBox(width: 8),
            _dot(_a1),
            const SizedBox(width: 4),
            _dot(_a2),
            const SizedBox(width: 4),
            _dot(_a3),
          ],
        ),
      ),
    );
  }

  Widget _dot(Animation<double> a) {
    return FadeTransition(
      opacity: a,
      child: const SizedBox(
        width: 6, height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}
