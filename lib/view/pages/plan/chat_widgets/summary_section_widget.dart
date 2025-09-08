import 'package:flutter/material.dart';
import './plan_summary_chart_widget.dart';
import '../plan_edit_page.dart';
import '../../../../view_model/plan/chat_plan_viewmodel.dart';

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
          final updatedPlan = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.planInfo,
                initialRefData: viewModel.refData,
              ),
            ),
          );
          if (updatedPlan != null) {
            viewModel.updatePlanInfo(
              planName: updatedPlan.planName,
              targetAmount: updatedPlan.targetAmount,
              currentAsset: updatedPlan.currentAsset,
            );
            viewModel.calculate(); // 추천 멘트/요약 재계산
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
  final recommendation = viewModel.summaryRecommendation; // null 가능

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // 요약 차트
      PlanSummaryChartWidget(
        planInfo: viewModel.planInfo,
        calculation: viewModel.calculationResult!,
        userName: viewModel.userName,
        onEdit: () async {
          final updatedPlan = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.planInfo,
                initialRefData: viewModel.refData,
              ),
            ),
          );
          if (updatedPlan != null) {
            viewModel.updatePlanInfo(
              planName: updatedPlan.planName,
              targetAmount: updatedPlan.targetAmount,
              currentAsset: updatedPlan.currentAsset,
            );
            viewModel.calculate(); // 추천 멘트/요약 재계산 → 내부 notify
          }
        },
      ),

      const SizedBox(height: 16),

      // 추천 멘트 (봇 말풍선 느낌, 채팅에 쌓이지 않음)
      if (recommendation != null && recommendation.isNotEmpty)
        _BotBubble(text: recommendation),

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
        Expanded(
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
      ],
    );
  }
}
